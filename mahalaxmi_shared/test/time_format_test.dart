import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/utils/time_format.dart';

void main() {
  group('formatLastActive', () {
    test('returns Never opened for null', () {
      expect(formatLastActive(null), 'Never opened');
    });

    test('returns Never opened for empty string', () {
      expect(formatLastActive(''), 'Never opened');
    });

    test('returns Never opened for non-parseable string', () {
      expect(formatLastActive('not-a-date'), 'Never opened');
    });

    test('returns Today HH:mm for today timestamp', () {
      final now = DateTime.now();
      final iso = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}T'
          '10:42:00';
      final result = formatLastActive(iso);
      expect(result, startsWith('Today '));
      expect(result, contains('10:42'));
    });

    test('returns Yesterday for yesterday timestamp', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final iso = '${yesterday.year}-'
          '${yesterday.month.toString().padLeft(2, '0')}-'
          '${yesterday.day.toString().padLeft(2, '0')}T'
          '15:30:00';
      expect(formatLastActive(iso), 'Yesterday');
    });

    test('returns X days ago for older timestamp', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final iso = '${threeDaysAgo.year}-'
          '${threeDaysAgo.month.toString().padLeft(2, '0')}-'
          '${threeDaysAgo.day.toString().padLeft(2, '0')}T'
          '09:15:00';
      expect(formatLastActive(iso), '3 days ago');
    });

    test('handles ISO string with timezone offset', () {
      final now = DateTime.now();
      final iso = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}T'
          '14:30:00+05:30';
      final result = formatLastActive(iso);
      expect(result, startsWith('Today '));
      expect(result, contains('14:30'));
    });

    test('handles ISO string with Z suffix', () {
      final now = DateTime.now().toUtc();
      final iso = '${now.year}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}T'
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:00Z';
      final result = formatLastActive(iso);
      // Z time converts to local, so just verify it's "Today HH:mm"
      expect(result, startsWith('Today '));
    });
  });
}
