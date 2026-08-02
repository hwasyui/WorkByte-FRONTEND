class PasswordValidator {
  static const int minLength = 8;

  static const String requirementsHint =
      'Min. 8 characters with uppercase, lowercase, number & symbol';

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
