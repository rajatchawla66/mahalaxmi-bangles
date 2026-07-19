import 'package:flutter_test/flutter_test.dart';
import 'package:mahalaxmi_shared/models/category.dart';

void main() {
  group('Category', () {
    group('fromJson', () {
      test('parses all fields including has_sizes and has_subcategories', () {
        final json = {
          'id': 1,
          'name': 'Test_Category',
          'icon': 'STAR',
          'color': 'AMBER_600',
          'description': 'A test category',
          'sub_categories': 'Sub1, Sub2',
          'order_type': 'sizes',
          'is_active': false,
          'cover_image_url': 'https://example.com/cover.jpg',
          'has_sizes': true,
          'has_subcategories': true,
        };

        final cat = Category.fromJson(json);

        expect(cat.id, equals(1));
        expect(cat.name, equals('Test_Category'));
        expect(cat.icon, equals('STAR'));
        expect(cat.color, equals('AMBER_600'));
        expect(cat.description, equals('A test category'));
        expect(cat.subCategories, equals('Sub1, Sub2'));
        expect(cat.orderType, equals('sizes'));
        expect(cat.isActive, isFalse);
        expect(cat.coverImageUrl, equals('https://example.com/cover.jpg'));
        expect(cat.hasSizes, isTrue);
        expect(cat.hasSubcategories, isTrue);
      });

      test('defaults has_sizes to false and has_subcategories to false when missing', () {
        final json = {
          'name': 'Minimal',
        };

        final cat = Category.fromJson(json);

        expect(cat.hasSizes, isFalse);
        expect(cat.hasSubcategories, isFalse);
      });

      test('defaults has_sizes to false when explicitly null', () {
        final json = {
          'name': 'NullFlags',
          'has_sizes': null,
          'has_subcategories': null,
        };

        final cat = Category.fromJson(json);

        expect(cat.hasSizes, isFalse);
        expect(cat.hasSubcategories, isFalse);
      });

      test('parses has_sizes from false value', () {
        final json = {
          'name': 'ExplicitFalse',
          'has_sizes': false,
          'has_subcategories': false,
        };

        final cat = Category.fromJson(json);

        expect(cat.hasSizes, isFalse);
        expect(cat.hasSubcategories, isFalse);
      });
    });

    group('toJson', () {
      test('serializes has_sizes and has_subcategories', () {
        final cat = Category(
          name: 'Serialize_Test',
          hasSizes: true,
          hasSubcategories: true,
        );

        final json = cat.toJson();

        expect(json['has_sizes'], isTrue);
        expect(json['has_subcategories'], isTrue);
      });

      test('serializes defaults correctly', () {
        final cat = Category(name: 'Defaults');

        final json = cat.toJson();

        expect(json['has_sizes'], isFalse);
        expect(json['has_subcategories'], isFalse);
      });
    });

    group('subCategoryList', () {
      test('splits comma-separated sub_categories', () {
        final cat = Category(name: 'Test', subCategories: 'A, B, C');
        expect(cat.subCategoryList, equals(['A', 'B', 'C']));
      });

      test('returns empty list when sub_categories is empty', () {
        final cat = Category(name: 'Test', subCategories: '');
        expect(cat.subCategoryList, isEmpty);
      });

      test('filters empty entries', () {
        final cat = Category(name: 'Test', subCategories: 'A, , B,');
        expect(cat.subCategoryList, equals(['A', 'B']));
      });
    });

    group('copyWith', () {
      test('copyWith preserves identity for unchanged fields', () {
        final cat = Category(name: 'Original', hasSizes: true, hasSubcategories: true);
        final copy = cat.copyWith();

        expect(copy.name, equals('Original'));
        expect(copy.hasSizes, isTrue);
        expect(copy.hasSubcategories, isTrue);
      });

      test('copyWith changes specified fields', () {
        final cat = Category(name: 'Original', hasSizes: false, hasSubcategories: false);
        final copy = cat.copyWith(hasSizes: true, hasSubcategories: true);

        expect(copy.name, equals('Original'));
        expect(copy.hasSizes, isTrue);
        expect(copy.hasSubcategories, isTrue);
      });
    });

    group('equality', () {
      test('identical fields are equal', () {
        final a = Category(name: 'Equal', hasSizes: true, hasSubcategories: true);
        final b = Category(name: 'Equal', hasSizes: true, hasSubcategories: true);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('different hasSizes makes inequality', () {
        final a = Category(name: 'Test', hasSizes: true);
        final b = Category(name: 'Test', hasSizes: false);

        expect(a, isNot(equals(b)));
      });

      test('different hasSubcategories makes inequality', () {
        final a = Category(name: 'Test', hasSubcategories: true);
        final b = Category(name: 'Test', hasSubcategories: false);

        expect(a, isNot(equals(b)));
      });
    });
  });
}
