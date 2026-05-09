import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'profile_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool _isLoading = false;
  bool _isRestoring = false;
  String? _error;
  String? _token;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  bool get isRestoring => _isRestoring;
  String? get error => _error;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  String? get userId => _currentUser?.userId;
  bool get isAuthenticated => _token != null && _currentUser != null;

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

      final user = await _service.getMe(savedToken);

      _token = savedToken;
      _currentUser = user;

      if (profileProvider != null) {
        await profileProvider.fetchProfile(
          token: _token!,
          userId: _currentUser!.userId,
          userType: _currentUser!.type,
        );
      }
    } catch (e) {
      await _service.clearSavedToken();
      _token = null;
      _currentUser = null;
    }

    _isRestoring = false;
    notifyListeners();
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

      if (profileProvider != null) {
        await profileProvider.fetchProfile(
          token: _token!,
          userId: _currentUser!.userId,
          userType: _currentUser!.type,
        );
      }

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
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout({ProfileProvider? profileProvider}) async {
    await _service.clearSavedToken();
    _token = null;
    _currentUser = null;
    _error = null;
    profileProvider?.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
