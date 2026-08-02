import 'package:http/http.dart' as http;
import 'auth_service.dart';

class SessionGuard {
  static void Function()? _onExpired;
  static Future<String?> Function()? _onRefresh;

  static void register(void Function() onExpired) {
    _onExpired = onExpired;
  }

  static void registerRefresh(Future<String?> Function() onRefresh) {
    _onRefresh = onRefresh;
  }

  static void check(http.Response response) {
    if (response.statusCode == 401) {
      _onRefresh?.call().then((token) {
        if (token == null) _onExpired?.call();
      });
      throw const SessionExpiredException();
    }
  }

  static Future<http.Response> guard(
    String token,
    Future<http.Response> Function(String token) request,
  ) async {
    final response = await request(token);
    if (response.statusCode != 401) return response;

    final newToken = await _onRefresh?.call();
    if (newToken == null) {
      _onExpired?.call();
      throw const SessionExpiredException();
    }

    final retried = await request(newToken);
    if (retried.statusCode == 401) {
      _onExpired?.call();
      throw const SessionExpiredException();
    }
    return retried;
  }
}
