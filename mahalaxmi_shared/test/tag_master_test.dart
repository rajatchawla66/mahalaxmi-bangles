import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/models/tag.dart';

void main() {
  group('TagMaster', () {
    group('fromJson', () {
      test('parses all fields', () {
        final json = {
          'id': 1,
          'name': 'gold',
          'display_name': 'Gold',
          'category': 'Chuda',
          'is_active': true,
          'categories': ['Chuda', 'Kaleera'],
          'created_at': '2026-01-01T00:00:00Z',
        };

        final tag = TagMaster.fromJson(json);

        expect(tag.id, equals(1));
        expect(tag.name, equals('gold'));
        expect(tag.displayName, equals('Gold'));
        expect(tag.legacyCategory, equals('Chuda'));
        expect(tag.isActive, isTrue);
        expect(tag.categories, equals(['Chuda', 'Kaleera']));
      });

      test('defaults is_active to true', () {
        final json = {'name': 'test', 'display_name': 'Test'};
        final tag = TagMaster.fromJson(json);
        expect(tag.isActive, isTrue);
      });

      test('defaults categories to empty list', () {
        final json = {'name': 'test', 'display_name': 'Test'};
        final tag = TagMaster.fromJson(json);
        expect(tag.categories, isEmpty);
      });
    });

    group('toJson', () {
      test('round-trips correctly', () {
        final tag = TagMaster(
          name: 'new_arrival',
          displayName: 'New Arrival',
          categories: ['Chuda', 'Kaleera'],
        );

        final json = tag.toJson();
        final restored = TagMaster.fromJson(json);

        expect(restored.name, equals('new_arrival'));
        expect(restored.displayName, equals('New Arrival'));
        expect(restored.categories, equals(['Chuda', 'Kaleera']));
      });
    });

    group('tag list operations (mirrors removeTagFromAllItems logic)', () {
      test('removing a tag preserves other tags', () {
        final tags = ['Gold', 'Silver', 'New_Arrival'];
        final tagToRemove = 'Silver';
        final updated = tags.where((t) => t != tagToRemove).toList();

        expect(updated, equals(['Gold', 'New_Arrival']));
      });

      test('removing the only tag produces empty list', () {
        final tags = ['Gold'];
        final tagToRemove = 'Gold';
        final updated = tags.where((t) => t != tagToRemove).toList();

        expect(updated, isEmpty);
      });

      test('removing a non-existent tag leaves list unchanged', () {
        final tags = ['Gold', 'Silver'];
        final tagToRemove = 'Platinum';
        final updated = tags.where((t) => t != tagToRemove).toList();

        expect(updated, equals(['Gold', 'Silver']));
      });

      test('removing tag from empty list stays empty', () {
        final tags = <String>[];
        final tagToRemove = 'Gold';
        final updated = tags.where((t) => t != tagToRemove).toList();

        expect(updated, isEmpty);
      });

      test('removing duplicate tag removes all occurrences', () {
        final tags = ['Gold', 'Silver', 'Gold'];
        final tagToRemove = 'Gold';
        final updated = tags.where((t) => t != tagToRemove).toList();

        expect(updated, equals(['Silver']));
      });

      test('renaming tag preserves other tags', () {
        final tags = ['Gold', 'Silver', 'New_Arrival'];
        final oldTag = 'Gold';
        final newTag = 'Gold_Plated';
        final updated = tags.map((t) => t == oldTag ? newTag : t).toList();

        expect(updated, equals(['Gold_Plated', 'Silver', 'New_Arrival']));
      });
    });
  });
}
