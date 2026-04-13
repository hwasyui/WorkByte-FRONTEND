import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/client_model.dart';
import '../models/freelancer_model.dart';

class ProfileProvider extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  ClientModel? _clientProfile;
  FreelancerModel? _freelancerProfile;
  String? _userType;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ClientModel? get clientProfile => _clientProfile;
  FreelancerModel? get freelancerProfile => _freelancerProfile;
  String? get userType => _userType;
  bool get hasProfile => _clientProfile != null || _freelancerProfile != null;
  bool get isClient => _userType == 'client';
  bool get isFreelancer => _userType == 'freelancer';

  String get displayName {
    if (isClient) return _clientProfile?.displayName ?? 'User';
    return _freelancerProfile?.displayName ?? 'User';
  }

  String? get profilePictureUrl {
    if (isClient) return _clientProfile?.profilePictureUrl;
    return _freelancerProfile?.profilePictureUrl;
  }

  String? get bio {
    if (isClient) return _clientProfile?.bio;
    return _freelancerProfile?.bio;
  }

  String get jobTitle {
    if (isClient) return _clientProfile?.jobTitle ?? '-';
    return _freelancerProfile?.jobTitle ?? '-';
  }

  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  // local
  // static const String _baseUrl = 'http://10.0.2.2:8000';

  Future<void> fetchProfile({
    required String token,
    required String userId,
    required String userType,
  }) async {
    _isLoading = true;
    _error = null;
    _userType = userType;
    notifyListeners();

    try {
      final endpoint = userType == 'client'
          ? '$_baseUrl/clients/$userId'
          : '$_baseUrl/freelancers/$userId';

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);
      debugPrint('GET /$userType profile response: $body');

      if (response.statusCode == 200) {
        final profileData = body['details'] ?? body['data'] ?? body;
        if (userType == 'client') {
          _clientProfile = ClientModel.fromJson(
            profileData as Map<String, dynamic>,
          );
        } else {
          _freelancerProfile = FreelancerModel.fromJson(
            profileData as Map<String, dynamic>,
          );
        }
      } else {
        _error = body['message'] ?? body['detail'] ?? 'Failed to load profile';
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      debugPrint('fetchProfile error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String token,
    required String identifier,
    required Map<String, dynamic> fields,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final endpoint = isClient
          ? '$_baseUrl/clients/$identifier'
          : '$_baseUrl/freelancers/$identifier';

      final response = await http.put(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(fields),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final profileData = data['details'] ?? data['data'] ?? data;
        if (isClient) {
          _clientProfile = ClientModel.fromJson(profileData);
        } else {
          _freelancerProfile = FreelancerModel.fromJson(profileData);
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _error = data['message'] ?? data['detail'] ?? 'Update failed';
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  void updateJobTitle(String jobTitle) {
    if (isClient) {
      _clientProfile = _clientProfile?.copyWith(jobTitle: jobTitle);
    } else {
      _freelancerProfile = _freelancerProfile?.copyWith(jobTitle: jobTitle);
    }
    notifyListeners();
  }

  void updateProfilePictureUrl(String? url) {
    if (isClient) {
      _clientProfile = _clientProfile?.copyWith(profilePictureUrl: url);
    } else {
      _freelancerProfile = _freelancerProfile?.copyWith(profilePictureUrl: url);
    }
    notifyListeners();
  }
  void clear() {
    _clientProfile = null;
    _freelancerProfile = null;
    _userType = null;
    _error = null;
    notifyListeners();
  }
}
