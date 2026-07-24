import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:workbyte_app/services/notification_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/session_guard.dart';
import 'profile_provider.dart';
import 'notification_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  AuthProvider() {
    // Access token is short-lived (30 min); try a silent refresh before logging out.
    SessionGuard.registerRefresh(_refreshOrRetryOnce);
    SessionGuard.register(() {
      handleSessionExpired();
    });
  }

  // Dedupes concurrent 401s into a single refresh attempt.
  Future<String?>? _refreshInFlight;

  Future<String?> _refreshOrRetryOnce() {
    return _refreshInFlight ??= _attemptRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _attemptRefresh() async {
    try {
      final newToken = await _service.refreshAccessToken();
      if (newToken != null) {
        _token = newToken;
        notifyListeners();
      }
      return newToken;
    } catch (e) {
      debugPrint('Silent token refresh failed: $e');
      return null;
    }
  }

  bool _isLoading = false;
  bool _isRestoring = false;
  String? _error;
  String? _token;
  UserModel? _currentUser;
  bool _sessionExpired = false;
  bool _backendUnavailable = false;

  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  String? get error => _error;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  String? get userId => _currentUser?.userId;
  bool get isAuthenticated => _token != null && _currentUser != null;
  bool get sessionExpired => _sessionExpired;
  bool get backendUnavailable => _backendUnavailable;

  void clearBackendUnavailable() {
    _backendUnavailable = false;
  }

  // ban state convenience getters
  bool get isReportBanned => _currentUser?.isReportBanned ?? false;
  String? get banMessage => _currentUser?.banMessage;
  DateTime? get reportBannedAt => _currentUser?.reportBannedAt;

  Future<void> restoreSession({ProfileProvider? profileProvider}) async {
    _isRestoring = true;
    notifyListeners();

    try {
      final savedToken = await _service.getSavedToken();

      if (savedToken == null || savedToken.isEmpty) {
        _token = null;
        _currentUser = null;
        _isRestoring = false;
        notifyListeners();
        return;
      }

      UserModel user;
      try {
        user = await _service.getMe(savedToken);
        _token = savedToken;
      } on SessionExpiredException {
        // Access token expired — try the refresh token before giving up.
        final refreshed = await _refreshOrRetryOnce();
        if (refreshed == null) rethrow;
        user = await _service.getMe(refreshed);
      }
      _currentUser = user;

      if (_currentUser!.hasRole && profileProvider != null) {
        await profileProvider.fetchProfile(
          token: _token!,
          userId: _currentUser!.userId,
          userType: _currentUser!.type,
        );
      }
    } on SessionExpiredException {
      // Token is genuinely invalid/expired — safe to clear
      await handleSessionExpired(profileProvider: profileProvider);
    } catch (e) {
      final savedToken = await _service.getSavedToken();
      if (savedToken != null) {
        _token = savedToken;
      }
      if (e is TimeoutException || e is SocketException) {
        _backendUnavailable = true;
      } else {
        debugPrint('restoreSession: non-auth error, keeping session: $e');
      }
    }

    _isRestoring = false;
    notifyListeners();
  }

  bool shouldShowProfileSetup(ProfileProvider profileProvider) {
    if (!isAuthenticated || _currentUser == null) return false;

    final role = _currentUser!.type.toLowerCase();

    if (role != 'freelancer') return false;

    return !profileProvider.isOnboardingComplete;
  }

  Future<Map<String, dynamic>?> loginWithGoogle({
    ProfileProvider? profileProvider,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _service.loginWithGoogle();
      final token = result['token'] as String;
      final isNewUser = result['is_new_user'] as bool;

      await _service.saveToken(token);
      _token = token;
      _currentUser = await _service.getMe(token);

      if (!isNewUser && _currentUser!.hasRole && profileProvider != null) {
        await profileProvider.fetchProfile(
          token: _token!,
          userId: _currentUser!.userId,
          userType: _currentUser!.type,
        );
      }

      _isLoading = false;
      notifyListeners();
      return {'is_new_user': isNewUser};
    } on SessionExpiredException {
      await handleSessionExpired(profileProvider: profileProvider);
      _isLoading = false;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> login(
    String email,
    String password, {
    ProfileProvider? profileProvider,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _token = await _service.login(email, password);
      await _service.saveToken(_token!);
      _currentUser = await _service.getMe(_token!);

      await NotificationService.saveTokenToBackend();

      if (_currentUser!.hasRole && profileProvider != null) {
        await profileProvider.fetchProfile(
          token: _token!,
          userId: _currentUser!.userId,
          userType: _currentUser!.type,
        );
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } on SessionExpiredException {
      await handleSessionExpired(profileProvider: profileProvider);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String userType,
    String? fullName,
    String? companyName,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.register(
        email: email,
        password: password,
        userType: userType,
        fullName: fullName,
        companyName: companyName,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> verifyEmail({required String email, required String otp}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.verifyEmail(email: email, otp: otp);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.forgotPassword(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> resendVerification({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.resendVerification(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> addRole({
    required String role,
    required String fullName,
    ProfileProvider? profileProvider,
  }) async {
    if (_token == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.addRole(token: _token!, role: role, fullName: fullName);
      _currentUser = await _service.getMe(_token!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on SessionExpiredException {
      await handleSessionExpired(profileProvider: profileProvider);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String oldPassword,
    required String newPassword,
    ProfileProvider? profileProvider,
  }) async {
    if (_token == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.changePassword(
        token: _token!,
        oldPassword: oldPassword,
        newPassword: newPassword,
      );
      _currentUser = await _service.getMe(_token!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on SessionExpiredException {
      await handleSessionExpired(profileProvider: profileProvider);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> setPassword({
    required String newPassword,
    ProfileProvider? profileProvider,
  }) async {
    if (_token == null) return false;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.setPassword(token: _token!, newPassword: newPassword);
      _currentUser = await _service.getMe(_token!);
      _isLoading = false;
      notifyListeners();
      return true;
    } on SessionExpiredException {
      await handleSessionExpired(profileProvider: profileProvider);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // call this after an appeal is approved to refresh ban state
  Future<void> refreshUser({
    ProfileProvider? profileProvider,
    NotificationProvider? notificationProvider,
  }) async {
    if (_token == null) return;

    try {
      UserModel user;
      try {
        user = await _service.getMe(_token!);
      } on SessionExpiredException {
        final refreshed = await _refreshOrRetryOnce();
        if (refreshed == null) rethrow;
        user = await _service.getMe(refreshed);
      }
      _currentUser = user;
      notifyListeners();
    } on SessionExpiredException {
      await handleSessionExpired(
        profileProvider: profileProvider,
        notificationProvider: notificationProvider,
      );
    } catch (e) {
      debugPrint('refreshUser failed: $e');
    }
  }

  Future<bool> tryRefresh() async {
    final newToken = await _refreshOrRetryOnce();
    return newToken != null;
  }

  Future<void> handleSessionExpired({
    ProfileProvider? profileProvider,
    NotificationProvider? notificationProvider,
  }) async {
    await _service.clearSavedToken();
    await _service.clearRefreshToken();
    _token = null;
    _currentUser = null;
    _error = null;
    _sessionExpired = true;
    profileProvider?.clear();
    notificationProvider?.clear();
    notifyListeners();
  }

  void clearSessionExpired() {
    _sessionExpired = false;
    notifyListeners();
  }

  Future<void> logout({
    ProfileProvider? profileProvider,
    NotificationProvider? notificationProvider,
  }) async {
    final refreshToken = await _service.getSavedRefreshToken();
    if (refreshToken != null) await _service.logout(refreshToken);
    await _service.signOutGoogle();
    await _service.clearSavedToken();
    await _service.clearRefreshToken();
    _token = null;
    _currentUser = null;
    _error = null;
    _sessionExpired = false;
    profileProvider?.clear();
    notificationProvider?.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
