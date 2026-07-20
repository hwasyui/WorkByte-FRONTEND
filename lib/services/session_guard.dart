import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Central choke point for detecting an expired/invalid session on any HTTP
/// response. Call [SessionGuard.check] right after every network response is
/// received; on a 401 it notifies the registered handler (which flips
/// AuthProvider into its logged-out state and redirects to the login screen)
/// and throws [SessionExpiredException] so the caller's own error handling
/// still runs as before.
class SessionGuard {
  static void Function()? _onExpired;

  static void register(void Function() onExpired) {
    _onExpired = onExpired;
  }

  static void check(http.Response response) {
    if (response.statusCode == 401) {
      _onExpired?.call();
      throw const SessionExpiredException();
    }
  }
}
