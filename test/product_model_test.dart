import 'package:ecommerce_app/model/product_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductElement', () {
    test('parses product details and uses the first image as thumbnail', () {
      final product = ProductElement.fromJson({
        'id': 12,
        'title': 'Canvas backpack',
        'description': 'A lightweight bag',
        'category': 'bags',
        'price': 50,
        'discountPercentage': 10,
        'rating': 4.6,
        'stock': 8,
        'images': ['https://example.com/bag-front.png'],
        'tags': ['travel'],
        'reviews': [
          {
            'rating': 5,
            'comment': 'Great quality',
            'date': '2026-10-20',
            'reviewerName': 'Sam',
          },
        ],
      });

      expect(product.id, 12);
      expect(product.thumbnail, 'https://example.com/bag-front.png');
      expect(product.images, ['https://example.com/bag-front.png']);
      expect(product.tags, ['travel']);
      expect(product.reviews.single.reviewerName, 'Sam');
    });

    test('serializes and restores product data', () {
      final product = ProductElement.fromJson({
        'id': 9,
        'title': 'Desk lamp',
        'description': 'Warm light',
        'category': 'home',
        'price': 24.5,
        'discountPercentage': 0,
        'rating': 4.2,
        'stock': 3,
        'thumbnail': 'https://example.com/lamp.png',
        'images': ['https://example.com/lamp.png'],
        'weight': 1.5,
      });

      final restored = ProductElement.fromJson(product.toJson());

      expect(restored.id, product.id);
      expect(restored.title, product.title);
      expect(restored.price, product.price);
      expect(restored.thumbnail, product.thumbnail);
      expect(restored.weight, product.weight);
    });
  });
}
