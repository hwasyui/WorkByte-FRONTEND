import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/payment_proof_model.dart';
import '../models/payout_info_model.dart';
import '../models/contract_model.dart';
import 'session_guard.dart';

class PaymentServiceException implements Exception {
  final String message;
  final int statusCode;
  const PaymentServiceException(this.message, {required this.statusCode});

  @override
  String toString() => message;
}

class PaymentService {
  final String _baseUrl = (dotenv.env['BACKEND'] ?? '').replaceAll(
    RegExp(r'/$'),
    '',
  );

  Map<String, String> _jsonHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  String _guessMime(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    const map = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
    };
    return map[ext] ?? 'application/octet-stream';
  }

  String _errorMessage(http.Response res, {String fallback = 'Request failed'}) {
    try {
      final decoded = jsonDecode(res.body);
      if (decoded is Map<String, dynamic>) {
        final details = decoded['details'];
        if (details is String && details.trim().isNotEmpty) return details;
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) return message;
      }
    } catch (_) {}
    return fallback;
  }

  Map<String, dynamic> _unwrap(String body) {
    final decoded = jsonDecode(body);
    final details = decoded is Map<String, dynamic>
        ? (decoded['details'] ?? decoded['data'] ?? decoded)
        : decoded;
    return details as Map<String, dynamic>;
  }

  Future<double?> getCommissionRate(String token) async {
    try {
      final res = await SessionGuard.guard(
        token,
        (t) => http
            .get(
              Uri.parse('$_baseUrl/payments/commission-rate'),
              headers: _jsonHeaders(t),
            )
            .timeout(const Duration(seconds: 15)),
      );
      if (res.statusCode == 200) {
        final data = _unwrap(res.body);
        return (data['commission_rate'] as num?)?.toDouble();
      }
    } catch (_) {}
    return null;
  }

  Future<PaymentProofModel> uploadPaymentProof({
    required String token,
    required String contractId,
    required String payee,
    required double amount,
    String? referenceNumber,
    required File file,
  }) async {
    final uri = Uri.parse('$_baseUrl/contracts/$contractId/payment-proof');

    final res = await SessionGuard.guard(token, (t) async {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $t'
        ..fields['payee'] = payee
        ..fields['amount'] = amount.toString();

      if (referenceNumber != null && referenceNumber.trim().isNotEmpty) {
        request.fields['reference_number'] = referenceNumber.trim();
      }

      final fileName = file.path.split('/').last;
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: fileName,
          contentType: MediaType.parse(_guessMime(fileName)),
        ),
      );

      final streamed = await request.send().timeout(const Duration(seconds: 120));
      return http.Response.fromStream(streamed).timeout(const Duration(seconds: 30));
    });

    if (res.statusCode == 200 || res.statusCode == 201) {
      return PaymentProofModel.fromJson(_unwrap(res.body));
    }
    throw PaymentServiceException(
      _errorMessage(res, fallback: 'Failed to upload payment proof'),
      statusCode: res.statusCode,
    );
  }

  Future<List<PaymentProofModel>> getPaymentProofs({
    required String token,
    required String contractId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http
          .get(
            Uri.parse('$_baseUrl/contracts/$contractId/payment-proof'),
            headers: _jsonHeaders(t),
          )
          .timeout(const Duration(seconds: 20)),
    );

    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      final list = decoded is Map<String, dynamic>
          ? (decoded['details'] ?? decoded['data'] ?? [])
          : decoded;
      if (list is! List) return [];
      return list
          .map((e) => PaymentProofModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw PaymentServiceException(
      _errorMessage(res, fallback: 'Failed to fetch payment proofs'),
      statusCode: res.statusCode,
    );
  }

  Future<ContractModel> confirmReceipt({
    required String token,
    required String contractId,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http
          .post(
            Uri.parse('$_baseUrl/contracts/$contractId/confirm-receipt'),
            headers: _jsonHeaders(t),
          )
          .timeout(const Duration(seconds: 20)),
    );

    if (res.statusCode == 200) {
      return ContractModel.fromJson(_unwrap(res.body));
    }
    throw PaymentServiceException(
      _errorMessage(res, fallback: 'Failed to confirm receipt'),
      statusCode: res.statusCode,
    );
  }

  Future<PayoutInfoModel> updatePayoutInfo({
    required String token,
    required String freelancerId,
    required String bankName,
    required String accountNumber,
    required String accountHolderName,
  }) async {
    final res = await SessionGuard.guard(
      token,
      (t) => http
          .put(
            Uri.parse('$_baseUrl/freelancers/$freelancerId/payout-info'),
            headers: _jsonHeaders(t),
            body: jsonEncode({
              'bank_name': bankName,
              'account_number': accountNumber,
              'account_holder_name': accountHolderName,
            }),
          )
          .timeout(const Duration(seconds: 20)),
    );

    if (res.statusCode == 200) {
      return PayoutInfoModel.fromJson(_unwrap(res.body));
    }
    throw PaymentServiceException(
      _errorMessage(res, fallback: 'Failed to save payout info'),
      statusCode: res.statusCode,
    );
  }

  Future<PayoutInfoModel?> getPayoutInfo({
    required String token,
    required String freelancerId,
  }) async {
    try {
      final res = await SessionGuard.guard(
        token,
        (t) => http
            .get(
              Uri.parse('$_baseUrl/freelancers/$freelancerId/payout-info'),
              headers: _jsonHeaders(t),
            )
            .timeout(const Duration(seconds: 15)),
      );
      if (res.statusCode == 200) {
        return PayoutInfoModel.fromJson(_unwrap(res.body));
      }
    } catch (_) {}
    return null;
  }
}
