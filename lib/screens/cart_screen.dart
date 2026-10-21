import 'package:ecommerce_app/constants/app_colors.dart';
import 'package:ecommerce_app/provider/cart_provider.dart';
import 'package:ecommerce_app/screens/checkout_screen.dart';
import 'package:ecommerce_app/screens/widgets/shop_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final items = cartState.items;
    final lines = items.values.toList();
    final subtotal = cartSubtotal(items);
    final shipping = subtotal >= 100 || subtotal == 0 ? 0.0 : 7.99;
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Your cart'),
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        actions: [
          if (lines.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Clear', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: cartState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.deepCoral),
            )
          : lines.isEmpty && cartState.error != null
          ? _CartLoadError(
              message: cartState.error!,
              onRetry: () => ref.read(cartProvider.notifier).reload(),
            )
          : lines.isEmpty
          ? _EmptyCart()
          : LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final itemCard = ShopSectionCard(
                  title:
                      'Items (${items.values.fold<int>(0, (n, item) => n + item.quantity)})',
                  child: Column(
                    children: [
                      if (cartState.error != null) ...[
                        _CartSyncNotice(
                          message: cartState.error!,
                          onRetry: () =>
                              ref.read(cartProvider.notifier).retrySync(),
                        ),
                        const SizedBox(height: 8),
                      ],
                      for (var index = 0; index < lines.length; index++) ...[
                        CartLineTile(
                          item: lines[index],
                          onQuantityChanged: (quantity) => ref
                              .read(cartProvider.notifier)
                              .setQuantity(lines[index].product.id, quantity),
                          onRemove: () => ref
                              .read(cartProvider.notifier)
                              .remove(lines[index].product.id),
                        ),
                        if (index != lines.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                );
                final summary = Column(
                  children: [
                    ShopSectionCard(
                      title: 'Order summary',
                      child: ShopPriceSummary(
                        subtotal: subtotal,
                        shipping: shipping,
                        total: total,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ShopPrimaryButton(
                      label: 'Continue to checkout',
                      icon: Icons.shopping_cart_checkout_rounded,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtotal >= 100
                          ? 'You unlocked free shipping.'
                          : 'Free shipping on orders over \$100.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.62),
                        fontSize: 12,
                      ),
                    ),
                  ],
                );

                return SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1120),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 7, child: itemCard),
                                  const SizedBox(width: 20),
                                  Expanded(flex: 4, child: summary),
                                ],
                              )
                            : Column(
                                children: [
                                  itemCard,
                                  const SizedBox(height: 16),
                                  summary,
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 106,
            height: 106,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.palePeach,
            ),
            child: const Icon(
              Icons.shopping_cart_outlined,
              size: 48,
              color: AppColors.deepCoral,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Add something you love and it will show up here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.ink.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 20),
          ShopPrimaryButton(
            label: 'Continue shopping',
            icon: Icons.storefront_rounded,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

class _CartSyncNotice extends StatelessWidget {
  const _CartSyncNotice({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0D7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 18,
              color: AppColors.deepCoral,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry sync'),
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              foregroundColor: AppColors.deepCoral,
            ),
          ),
        ),
      ],
    ),
  );
}

class _CartLoadError extends StatelessWidget {
  const _CartLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 46,
            color: AppColors.deepCoral,
          ),
          const SizedBox(height: 12),
          const Text(
            'Could not load your cart',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
