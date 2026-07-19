String formatLastActive(String? isoString) {
  if (isoString == null || isoString.isEmpty) return 'Never opened';

  final dateTime = DateTime.tryParse(isoString);
  if (dateTime == null) return 'Never opened';

  final now = DateTime.now();
  final local = dateTime.toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final accessDate = DateTime(local.year, local.month, local.day);

  if (accessDate == today) {
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return 'Today $h:$m';
  }

  if (accessDate == yesterday) {
    return 'Yesterday';
  }

  final diff = today.difference(accessDate).inDays;
  if (diff > 0) {
    return '$diff days ago';
  }

  return 'Never opened';
}
