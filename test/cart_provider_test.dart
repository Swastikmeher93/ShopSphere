import 'package:ecommerce_app/model/product_model.dart';
import 'package:ecommerce_app/provider/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

ProductElement _product({
  required int id,
  double price = 20,
  double discount = 0,
  int stock = 10,
}) => ProductElement(
  id: id,
  title: 'Product $id',
  description: 'Test product',
  category: 'test',
  price: price,
  discountPercentage: discount,
  rating: 4,
  stock: stock,
  thumbnail: '',
);

void main() {
  group('Cart calculations', () {
    test('applies product discount to unit price and quantity total', () {
      final item = CartItem(
        product: _product(id: 1, price: 50, discount: 20),
        quantity: 3,
      );

      expect(item.unitPrice, 40);
      expect(item.total, 120);
    });

    test('calculates cart quantity and subtotal across products', () {
      final items = {
        1: CartItem(product: _product(id: 1, price: 10), quantity: 2),
        2: CartItem(
          product: _product(id: 2, price: 25, discount: 20),
          quantity: 1,
        ),
      };
      final state = CartState(items: items);

      expect(state.totalQuantity, 3);
      expect(cartSubtotal(items), 40);
    });
  });
}
