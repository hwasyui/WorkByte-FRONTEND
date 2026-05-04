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

  bool get isProfileComplete {
    if (isClient) {
      final c = _clientProfile;
      if (c == null) return false;
      return (c.fullName?.isNotEmpty ?? false) && c.jobTitle != '-' && (c.bio?.isNotEmpty ?? false);
    }
    if (isFreelancer) {
      final f = _freelancerProfile;
      if (f == null) return false;
      return f.fullName.isNotEmpty && f.jobTitle != '-' && (f.bio?.isNotEmpty ?? false);
    }
    return false;
  }

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

  Future<bool> fetchProfile({
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

      debugPrint('GET /$userType profile endpoint: $endpoint');
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
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = body['message'] ?? body['detail'] ?? 'Failed to load profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Network error: ${e.toString()}';
      debugPrint('fetchProfile error: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
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

      debugPrint('PUT profile endpoint: $endpoint');
      debugPrint('PUT profile payload: $fields');
      
      // Create multipart request for form-data
      final uri = Uri.parse(endpoint);
      final request = http.MultipartRequest('PUT', uri);
      
      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add form fields from the fields map
      fields.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value.toString();
        }
      });
      
      debugPrint('Sending multipart request with fields: ${request.fields}');
      
      // Send the request
      final streamResponse = await request.send();
      final response = await http.Response.fromStream(streamResponse);
      
      final data = jsonDecode(response.body);
      debugPrint('Update profile response: ${response.statusCode}, data: $data');

      if (response.statusCode == 200) {
        final profileData = data['details'] ?? data['data'] ?? data;
        print('Profile data from server: $profileData');
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
      print('Update failed: $_error');
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

  void updateProfilePictureUrl(String url) {
    // Clear image cache to force reload
    imageCache.clear();
    imageCache.clearLiveImages();
    
    if (isClient) {
      _clientProfile =
          _clientProfile?.copyWith(profilePictureUrl: url);
    } else {
      _freelancerProfile =
          _freelancerProfile?.copyWith(profilePictureUrl: url);
    }
    notifyListeners();
  }

  void clearProfilePicture() {
    // Clear image cache to force reload
    imageCache.clear();
    imageCache.clearLiveImages();
    
    if (isClient) {
      _clientProfile = _clientProfile?.copyWith(profilePictureUrl: null);
    } else {
      _freelancerProfile = _freelancerProfile?.copyWith(profilePictureUrl: null);
    }
    notifyListeners();
  }

  void forceRefreshProfilePicture() {
    imageCache.clear();
    imageCache.clearLiveImages();
    notifyListeners();
  }

  Future<ClientModel?> fetchClientById({
    required String token,
    required String clientId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/clients/$clientId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final profileData = body['details'] ?? body['data'] ?? body;
        return ClientModel.fromJson(profileData as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('fetchClientById error: $e');
    }
    return null;
  }

  Future<FreelancerModel?> fetchFreelancerById({
    required String token,
    required String freelancerId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/freelancers/$freelancerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final profileData = body['details'] ?? body['data'] ?? body;
        return FreelancerModel.fromJson(profileData as Map<String, dynamic>);
      }
    } catch (e) {
      debugPrint('fetchFreelancerById error: $e');
    }
    return null;
  }

  void clear() {
    _clientProfile = null;
    _freelancerProfile = null;
    _userType = null;
    _error = null;
    notifyListeners();
  }
}
