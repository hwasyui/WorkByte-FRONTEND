/// Mirrors the backend password policy in WorkByte-BACKEND
/// (functions/schema_model.py, `_validate_password_strength`):
/// 8+ characters with an uppercase letter, a lowercase letter, a digit,
/// and a special character.
class PasswordValidator {
  static const int minLength = 8;

  static const String requirementsHint =
      'Min. 8 characters with uppercase, lowercase, number & symbol';

  /// Returns null when [password] satisfies the backend policy, otherwise
  /// an error message listing what's missing.
  static String? validate(String password) {
    if (password.isEmpty) return 'Password is required';

    final missing = <String>[];
    if (password.length < minLength) {
      missing.add('at least $minLength characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      missing.add('an uppercase letter');
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      missing.add('a lowercase letter');
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      missing.add('a number');
    }
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      missing.add('a special character');
    }

    if (missing.isEmpty) return null;
    return 'Password must contain ${missing.join(', ')}';
  }
}
