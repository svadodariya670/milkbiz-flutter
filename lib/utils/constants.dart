class AppHelpers {
  static String initials(String name) =>
      name.isNotEmpty ? name[0].toUpperCase() : '?';
  static String formatDate(DateTime date) =>
      '${date.day}/${date.month}/${date.year}';
}
