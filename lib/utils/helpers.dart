import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppHelpers {
  static String formatDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
  static String formatMonth(DateTime d) => DateFormat('MMMM yyyy').format(d);
  static String monthKey(DateTime d) => DateFormat('yyyy-MM').format(d);
  static String formatCurrency(num n) => '₹${n.toStringAsFixed(0)}';

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning ☀️';
    if (h < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  static void showSnack(BuildContext ctx, String msg, {bool error = false}) {
    ScaffoldMessenger.of(ctx)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
      ));
  }

  static Future<bool> confirm(
    BuildContext ctx, {
    required String title,
    required String message,
    String confirmText = 'Confirm',
    bool danger = true,
  }) async {
    final result = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(confirmText,
                style: TextStyle(color: danger ? Colors.red : Colors.blue)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Generates a unique, readable customer ID like CUST-001
  static String generateCustomerId(int count) {
    final n = (count + 1).toString().padLeft(3, '0');
    return 'CUST-$n';
  }

  /// Generates a unique milkman ID like MILK-ABC123
  static String generateMilkmanId(String uid) {
    return 'MILK-${uid.substring(0, 6).toUpperCase()}';
  }
}
