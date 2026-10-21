import 'package:ecommerce_app/model/product_model.dart';
import 'package:ecommerce_app/provider/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productProvider = FutureProvider<Product>((ref) async {
  final response = await ref.watch(apiServicesProvider).get('/products');
  if (response is! Map<String, dynamic>) {
    throw const FormatException('Unexpected products response.');
  }
  return Product.fromJson(response);
});

final productDetailsProvider =
    FutureProvider.family<ProductElement, int>((ref, productId) async {
  final response =
      await ref.watch(apiServicesProvider).get('/products/$productId');
  if (response is! Map<String, dynamic>) {
    throw const FormatException('Unexpected product details response.');
  }
  return ProductElement.fromJson(response);
});
