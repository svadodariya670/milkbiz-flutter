class Validators {
  static String? required(String? v, {String field = 'This field'}) =>
      (v == null || v.trim().isEmpty) ? '$field is required' : null;

  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Min 6 characters';
    return null;
  }

  static String? positiveNumber(String? v, {String field = 'Value'}) {
    if (v == null || v.isEmpty) return '$field is required';
    final n = double.tryParse(v);
    if (n == null) return 'Enter a valid number';
    if (n <= 0) return '$field must be > 0';
    return null;
  }

  static String? customerId(String? v) {
    if (v == null || v.trim().isEmpty) return 'Customer ID is required';
    if (v.trim().length < 4) return 'Min 4 characters';
    if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(v.trim())) {
      return 'Only letters, numbers, - and _ allowed';
    }
    return null;
  }
}
