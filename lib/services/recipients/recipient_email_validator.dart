class RecipientEmailValidator {
  static final RegExp _emailRegExp = RegExp(
    r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
    caseSensitive: false,
  );

  static bool isValid(String input) {
    final value = input.trim();
    if (value.isEmpty) return false;
    return _emailRegExp.hasMatch(value);
  }
}
