import 'dart:async';
import 'dart:convert';

import 'package:ecommerce_app/api/api_services.dart';
import 'package:ecommerce_app/data/local_cart_database.dart';
import 'package:ecommerce_app/model/product_model.dart';
import 'package:ecommerce_app/provider/auth_provider.dart';
import 'package:ecommerce_app/provider/service_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final ProductElement product;
  final int quantity;

  double get unitPrice =>
      product.price * (1 - product.discountPercentage / 100);
  double get total => unitPrice * quantity;
}

class CartState {
  const CartState({
    this.items = const {},
    this.userId,
    this.cartId,
    this.isLoading = false,
    this.error,
  });

  final Map<int, CartItem> items;
  final int? userId;
  final int? cartId;
  final bool isLoading;
  final String? error;

  int get totalQuantity =>
      items.values.fold(0, (total, item) => total + item.quantity);

  CartState copyWith({
    Map<int, CartItem>? items,
    int? userId,
    int? cartId,
    bool? isLoading,
    String? error,
    bool clearCartId = false,
    bool clearError = false,
  }) => CartState(
    items: items ?? this.items,
    userId: userId ?? this.userId,
    cartId: clearCartId ? null : cartId ?? this.cartId,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
  );
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);

class CartNotifier extends Notifier<CartState> {
  int _loadGeneration = 0;
  Future<void> _loadFuture = Future<void>.value();
  Future<void> _mutationQueue = Future<void>.value();

  @override
  CartState build() {
    final userId = ref.watch(authProvider.select((auth) => auth.user?.id));
    final generation = ++_loadGeneration;
    if (userId == null) {
      _loadFuture = Future<void>.value();
      return const CartState();
    }

    _loadFuture = Future<void>.microtask(
      () => _loadUserCart(userId, generation),
    );
    return CartState(userId: userId, isLoading: true);
  }

  Future<void> reload() async {
    final userId = state.userId;
    if (userId == null) return;
    final generation = ++_loadGeneration;
    state = state.copyWith(isLoading: true, clearError: true);
    _loadFuture = _loadUserCart(userId, generation);
    await _loadFuture;
  }

  Future<void> retrySync() => _queueSync();

  Future<void> add(ProductElement product) async {
    await _loadFuture;
    final current = state.items[product.id];
    if (product.stock <= 0 ||
        (current != null && current.quantity >= product.stock)) {
      return;
    }
    final items = {...state.items};
    items[product.id] = CartItem(
      product: product,
      quantity: (current?.quantity ?? 0) + 1,
    );
    state = state.copyWith(items: items, clearError: true);
    await _queueSync();
  }

  Future<void> setQuantity(int productId, int quantity) async {
    await _loadFuture;
    if (quantity <= 0) {
      await remove(productId);
      return;
    }
    final current = state.items[productId];
    if (current == null) return;
    final items = {...state.items};
    items[productId] = CartItem(
      product: current.product,
      quantity: current.product.stock > 0
          ? quantity.clamp(1, current.product.stock).toInt()
          : quantity,
    );
    state = state.copyWith(items: items, clearError: true);
    await _queueSync();
  }

  Future<void> remove(int productId) async {
    await _loadFuture;
    final items = {...state.items}..remove(productId);
    if (items.length == state.items.length) return;
    state = state.copyWith(items: items, clearError: true);
    await _queueSync();
  }

  Future<void> clear() async {
    await _loadFuture;
    if (state.items.isEmpty && state.cartId == null) return;
    state = state.copyWith(items: const {}, clearError: true);
    await _queueSync();
  }

  Future<void> _loadUserCart(int userId, int generation) async {
    try {
      final cached = await _readLocalCart(userId);
      if (generation != _loadGeneration) return;
      if (cached != null) {
        state = CartState(
          userId: userId,
          cartId: (cached['cartId'] as num?)?.toInt(),
          items: _parseCachedItems(cached['items']),
          isLoading: false,
        );
        return;
      }

      final response = await ref
          .read(apiServicesProvider)
          .get('/carts/user/$userId');
      if (generation != _loadGeneration) return;
      if (response is! Map<String, dynamic>) {
        throw const FormatException('Unexpected carts response.');
      }

      final rawCarts = response['carts'] as List<dynamic>? ?? const [];
      final matchingCarts = rawCarts.whereType<Map<String, dynamic>>().where(
        (cart) => (cart['userId'] as num?)?.toInt() == userId,
      );
      final matchingCart = matchingCarts.isEmpty ? null : matchingCarts.first;
      if (matchingCart == null) {
        state = state.copyWith(
          userId: userId,
          isLoading: false,
          items: const {},
          clearCartId: true,
          clearError: true,
        );
        await _writeLocalCart();
        return;
      }

      final items = _parseItems(matchingCart['products']);
      state = state.copyWith(
        userId: userId,
        cartId: (matchingCart['id'] as num?)?.toInt(),
        items: items,
        isLoading: false,
        clearError: true,
      );
      await _writeLocalCart();
    } catch (error) {
      if (generation != _loadGeneration) return;
      state = state.copyWith(isLoading: false, error: _messageFor(error));
    }
  }

  Future<void> _queueSync() {
    _mutationQueue = _mutationQueue
        .then((_) async {
          await _writeLocalCart();
          await _syncCurrentCart();
        })
        .catchError((Object error) {
          state = state.copyWith(error: _messageFor(error));
        });
    return _mutationQueue;
  }

  Future<void> _syncCurrentCart() async {
    final userId = state.userId;
    if (userId == null) return;
    final api = ref.read(apiServicesProvider);
    final products = state.items.values
        .map((item) => {'id': item.product.id, 'quantity': item.quantity})
        .toList(growable: false);

    if (products.isEmpty) {
      final cartId = state.cartId;
      if (cartId == null) return;
      try {
        await api.delete('/carts/$cartId');
      } on ApiException catch (error) {
        // DummyJSON carts are simulated and may disappear between sessions.
        // A missing remote cart is already in the desired deleted state.
        if (error.statusCode != 404) rethrow;
      }
      state = state.copyWith(clearCartId: true, clearError: true);
      await _writeLocalCart();
      return;
    }

    final cartId = state.cartId;
    dynamic response;
    if (cartId == null) {
      response = await api.post(
        '/carts/add',
        body: {'userId': userId, 'products': products},
      );
    } else {
      try {
        response = await api.put(
          '/carts/$cartId',
          body: {'userId': userId, 'products': products},
        );
      } on ApiException catch (error) {
        if (error.statusCode != 404) rethrow;
        // Recreate a missing demo API cart while retaining its local items.
        state = state.copyWith(clearCartId: true);
        await _writeLocalCart();
        response = await api.post(
          '/carts/add',
          body: {'userId': userId, 'products': products},
        );
      }
    }
    if (response is! Map<String, dynamic>) {
      throw const FormatException('Unexpected cart mutation response.');
    }
    final returnedCartId = (response['id'] as num?)?.toInt();
    if (returnedCartId != null && state.userId == userId) {
      state = state.copyWith(cartId: returnedCartId, clearError: true);
      await _writeLocalCart();
    }
  }

  Future<Map<String, dynamic>?> _readLocalCart(int userId) async {
    try {
      final cart = await LocalCartDatabase.instance.readCart(userId);
      if (cart != null) {
        return {
          'initialized': true,
          'cartId': cart.cartId,
          'items': cart.items,
        };
      }
    } catch (_) {
      // If SQLite is unavailable, try the cache written by older app builds.
    }

    try {
      final json = await ref
          .read(secureStorageProvider)
          .read(key: 'cart_cache_$userId');
      if (json == null) return null;
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic> || decoded['initialized'] != true) {
        return null;
      }
      // Import a legacy secure-storage cart into SQLite for future launches.
      await LocalCartDatabase.instance.writeCart(
        userId: userId,
        cartId: (decoded['cartId'] as num?)?.toInt(),
        items: _serializeItems(_parseCachedItems(decoded['items'])),
      );
      try {
        await ref.read(secureStorageProvider).delete(key: 'cart_cache_$userId');
      } catch (_) {
        // The SQLite copy is already saved; ignore legacy-cache cleanup errors.
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeLocalCart() async {
    final userId = state.userId;
    if (userId == null) return;
    final data = {
      'initialized': true,
      'cartId': state.cartId,
      'items': state.items.values
          .map(
            (item) => {
              'quantity': item.quantity,
              'product': {
                'id': item.product.id,
                'title': item.product.title,
                'description': item.product.description,
                'category': item.product.category,
                'price': item.product.price,
                'discountPercentage': item.product.discountPercentage,
                'rating': item.product.rating,
                'stock': item.product.stock,
                'brand': item.product.brand,
                'thumbnail': item.product.thumbnail,
                'images': item.product.images,
              },
            },
          )
          .toList(growable: false),
    };
    try {
      await LocalCartDatabase.instance.writeCart(
        userId: userId,
        cartId: state.cartId,
        items: _serializeItems(state.items),
      );
      try {
        await ref.read(secureStorageProvider).delete(key: 'cart_cache_$userId');
      } catch (_) {
        // SQLite is authoritative once the write succeeds.
      }
    } catch (_) {
      // Preserve the prior local cache if SQLite is temporarily unavailable.
      try {
        await ref
            .read(secureStorageProvider)
            .write(key: 'cart_cache_$userId', value: jsonEncode(data));
      } catch (_) {
        // Cart API syncing still works if device storage is unavailable.
      }
    }
  }
}

Map<int, CartItem> _parseItems(Object? rawProducts) {
  if (rawProducts is! List) return const {};
  final items = <int, CartItem>{};
  for (final rawProduct in rawProducts.whereType<Map<String, dynamic>>()) {
    final productData = Map<String, dynamic>.from(rawProduct);
    productData.putIfAbsent('stock', () => 999999);
    final product = ProductElement.fromJson(productData);
    final quantity = (rawProduct['quantity'] as num?)?.toInt() ?? 0;
    if (product.id > 0 && quantity > 0) {
      items[product.id] = CartItem(product: product, quantity: quantity);
    }
  }
  return items;
}

Map<int, CartItem> _parseCachedItems(Object? rawItems) {
  if (rawItems is! List) return const {};
  final items = <int, CartItem>{};
  for (final rawItem in rawItems.whereType<Map<String, dynamic>>()) {
    final rawProduct = rawItem['product'];
    if (rawProduct is! Map<String, dynamic>) continue;
    final product = ProductElement.fromJson(rawProduct);
    final quantity = (rawItem['quantity'] as num?)?.toInt() ?? 0;
    if (product.id > 0 && quantity > 0) {
      items[product.id] = CartItem(product: product, quantity: quantity);
    }
  }
  return items;
}

List<Map<String, dynamic>> _serializeItems(Map<int, CartItem> items) => items
    .values
    .map(
      (item) => {'quantity': item.quantity, 'product': item.product.toJson()},
    )
    .toList(growable: false);

String _messageFor(Object error) => error is ApiException
    ? '${error.message} Your local cart is still saved.'
    : 'Could not sync your cart. Your local cart is still saved.';

double cartSubtotal(Map<int, CartItem> items) =>
    items.values.fold(0, (sum, item) => sum + item.total);
