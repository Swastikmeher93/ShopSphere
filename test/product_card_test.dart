import 'package:ecommerce_app/model/product_model.dart';
import 'package:ecommerce_app/screens/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('product card shows product and sale price without cart button', (
    tester,
  ) async {
    const product = ProductElement(
      id: 1,
      title: 'Test mug',
      description: 'A ceramic mug',
      category: 'kitchen',
      price: 10,
      discountPercentage: 20,
      rating: 4.5,
      stock: 2,
      thumbnail: '',
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 190,
              height: 280,
              child: ProductCard(product: product),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Test mug'), findsOneWidget);
    expect(find.text('KITCHEN'), findsOneWidget);
    expect(find.text('\$8.00'), findsOneWidget);
    expect(find.text('\$10.00'), findsOneWidget);
    expect(find.text('Add to cart'), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
  });
}
