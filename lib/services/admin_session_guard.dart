import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Same purpose as [SessionGuard], but for the admin panel's separate
/// token/session (AdminProvider/AdminService use their own storage key and
/// have no relationship to the regular user AuthProvider), so an expired
/// admin token must not touch the regular user's session.
class AdminSessionGuard {
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
