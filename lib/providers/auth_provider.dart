import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'profile_provider.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service = AuthService();

  bool _isLoading = false;
  String? _error;
  String? _token;
  UserModel? _currentUser;

  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get token => _token;
  UserModel? get currentUser => _currentUser;
  String? get userId => _currentUser?.userId;
  bool get isAuthenticated => _token != null;

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

  void logout({ProfileProvider? profileProvider}) {
    _token = null;
    _currentUser = null;
    profileProvider?.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
