import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/contract_milestone_model.dart';
import '../models/contract_model.dart';
import 'session_guard.dart';

/// A failed contract request, carrying the metadata the backend puts *beside*
/// `details` in the error envelope rather than inside it.
class ContractServiceException implements Exception {
  final String message;
  final int statusCode;

  /// `locked_field`, `frozen_field`, `harmful_text`, or null.
  final String? blockedBy;

  /// The offending field and the value it must hold, set on `locked_field`.
  final String? field;
  final String? expected;

  final List<String> detectedLabels;

  const ContractServiceException(
    this.message, {
    required this.statusCode,
    this.blockedBy,
    this.field,
    this.expected,
    this.detectedLabels = const [],
  });

  bool get isDuplicate => statusCode == 409;

  @override
  String toString() => message;
}

class ContractService {
  static final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// `details` is a human readable string on most errors but an object on a
  /// 422, where the messages live under `validation_errors`. Rendering the
  /// object directly would show a Dart map to the user.
  static String _errorMessage(dynamic body, String fallback) {
    if (body is! Map) return fallback;

    final details = body['details'];
    if (details is String && details.trim().isNotEmpty) return details.trim();

    if (details is Map) {
      final errors = details['validation_errors'];
      if (errors is List && errors.isNotEmpty) {
        final messages = errors
            .map(
              (e) => e is Map
                  ? (e['message'] ?? '').toString().trim()
                  : e.toString().trim(),
            )
            .where((m) => m.isNotEmpty)
            .toList();
        if (messages.isNotEmpty) return messages.join('\n');
      }
    }

    final message = body['message'];
    if (message is String && message.trim().isNotEmpty) return message.trim();

    return fallback;
  }

  ContractServiceException _failure(
    http.Response res,
    dynamic body,
    String fallback,
  ) {
    final map = body is Map ? body : const {};
    final labels = map['detected_labels'];

    return ContractServiceException(
      _errorMessage(body, fallback),
      statusCode: res.statusCode,
      blockedBy: map['blocked_by'] as String?,
      field: map['field'] as String?,
      expected: map['expected']?.toString(),
      detectedLabels: labels is List
          ? labels.map((l) => l.toString()).toList()
          : const [],
    );
  }

  Future<List<ContractModel>> getAllContracts(String token) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _failure(res, body, 'Failed to load contracts');
  }

  Future<List<ContractModel>> getContractsByClient(
    String token,
    String clientId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/client/$clientId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/client/$clientId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _failure(res, body, 'Failed to load contracts');
  }

  Future<List<ContractModel>> getContractsByFreelancer(
    String token,
    String freelancerId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/freelancer/$freelancerId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/freelancer/$freelancerId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final details = body['details'];
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body['data'] ?? []));
      return (list as List)
          .map((e) => ContractModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw _failure(res, body, 'Failed to load contracts');
  }

  Future<ContractModel> getContractById(String token, String contractId) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/$contractId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/$contractId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw _failure(res, body, 'Failed to load contract');
  }

  /// The contract created from [proposalId], or null when the bid has not been
  /// contracted yet. `contract.proposal_id` is unique, so this is the
  /// authoritative answer for "does this accepted bid already have a contract?".
  Future<ContractModel?> getContractByProposal(
    String token,
    String proposalId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/proposal/$proposalId'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    debugPrint('GET /contracts/proposal/$proposalId status: ${res.statusCode}');
    if (res.statusCode == 404) return null;

    final body = jsonDecode(res.body);
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw _failure(res, body, 'Failed to load contract');
  }

  /// The contract's milestone schedule, already ordered by `sequence_order`.
  /// Sorted again here because the list drives an ordered stepper and a
  /// mis-ordered response would silently mislabel which milestone is current.
  Future<List<ContractMilestoneModel>> getContractMilestones(
    String token,
    String contractId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/$contractId/milestones'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/$contractId/milestones status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final details = body is Map ? body['details'] : null;
      final list = (details is Map && details['items'] != null)
          ? details['items']
          : (details is List ? details : (body is Map ? body['data'] ?? [] : body));
      if (list is! List) return const [];
      final milestones = list
          .map(
            (e) => ContractMilestoneModel.fromJson(e as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
      return milestones;
    }
    throw _failure(res, body, 'Failed to load milestones');
  }

  Future<Map<String, dynamic>> getContractGenerationData(
    String token,
    String contractId,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/$contractId/generation-data'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint(
      'GET /contracts/$contractId/generation-data status: ${res.statusCode}',
    );
    if (res.statusCode == 200) {
      return body['data'] ?? body['details'] ?? {};
    }
    throw _failure(res, body, 'Failed to load generation data');
  }

  Future<String> getContractPdfUrl(String token, String contractId) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.get(
        Uri.parse('$_baseUrl/contracts/$contractId/pdf-url'),
        headers: _headers(t),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('GET /contracts/$contractId/pdf-url status: ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = (body['details'] ?? body['data']) as Map<String, dynamic>?;
      final pdfUrl =
          data?['pdf_url'] as String? ?? data?['contract_pdf_url'] as String?;
      if (pdfUrl == null || pdfUrl.isEmpty) {
        throw Exception('PDF URL not found');
      }
      return pdfUrl;
    }
    throw _failure(res, body, 'Failed to get PDF URL');
  }

  /// Creates the contract, its terms and its PDF in one transaction. [data]
  /// must carry the nested `terms` object; the response is the finished row,
  /// PDF included. A failure leaves nothing behind, so the caller can simply
  /// let the user correct the form and try again.
  Future<ContractModel> createContract(
    String token,
    Map<String, dynamic> data,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.post(
        Uri.parse('$_baseUrl/contracts'),
        headers: _headers(t),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30)),
    );
    final body = jsonDecode(res.body);
    debugPrint('POST /contracts status: ${res.statusCode}');
    if (res.statusCode == 201) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw _failure(res, body, 'Failed to create contract');
  }

  /// Delivers the already-stored PDF to the freelancer over DM. Nothing is
  /// re-rendered, so calling this again simply posts the same document again.
  Future<ContractModel> sendContract(
    String token,
    String contractId, {
    String? notificationMessage,
    bool saveMessageAsTemplate = false,
  }) async {
    final message = notificationMessage?.trim();

    final res = await SessionGuard.guard(
      token,
      (t) => http.post(
        Uri.parse('$_baseUrl/contracts/$contractId/send'),
        headers: _headers(t),
        body: jsonEncode({
          if (message != null && message.isNotEmpty)
            'notification_message': message,
          if (saveMessageAsTemplate) 'save_message_as_template': true,
        }),
      ).timeout(const Duration(seconds: 30)),
    );
    final body = jsonDecode(res.body);
    debugPrint('POST /contracts/$contractId/send status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw _failure(res, body, 'Failed to send contract');
  }

  Future<ContractModel> updateContract(
    String token,
    String contractId,
    Map<String, dynamic> data,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.put(
        Uri.parse('$_baseUrl/contracts/$contractId'),
        headers: _headers(t),
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('PUT /contracts/$contractId status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['data'] ?? body['details'] ?? body);
    }
    throw _failure(res, body, 'Failed to update contract');
  }

  Future<ContractModel> raiseDispute(
    String token,
    String contractId,
    String reason,
  ) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.put(
        Uri.parse('$_baseUrl/contracts/$contractId/dispute'),
        headers: _headers(t),
        body: jsonEncode({'reason': reason}),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);
    debugPrint('PUT /contracts/$contractId/dispute status: ${res.statusCode}');
    if (res.statusCode == 200) {
      return ContractModel.fromJson(body['details'] ?? body['data'] ?? body);
    }
    throw _failure(res, body, 'Failed to raise dispute');
  }

  Future<ContractModel> cancelContract(
    String token,
    String contractId, {
    String? reason,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http.put(
        Uri.parse('$_baseUrl/contracts/$contractId/cancel'),
        headers: {
          'Authorization': 'Bearer $t',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        }),
      ).timeout(const Duration(seconds: 20)),
    );
    final body = jsonDecode(res.body);

    if (res.statusCode == 200) {
      final raw = body['details'] ?? body['data'] ?? body;
      return ContractModel.fromJson(raw as Map<String, dynamic>);
    }

    throw _failure(res, body, 'Failed to cancel contract');
  }
}
