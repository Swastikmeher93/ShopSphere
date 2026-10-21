import 'package:ecommerce_app/constants/app_colors.dart';
import 'package:ecommerce_app/provider/cart_provider.dart';
import 'package:ecommerce_app/screens/widgets/shop_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);
    final items = cartState.items;
    final subtotal = cartSubtotal(items);
    final shipping = subtotal >= 100 || subtotal == 0 ? 0.0 : 7.99;
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
      ),
      body: cartState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.deepCoral),
            )
          : items.isEmpty
              ? const Center(child: Text('Your cart is empty.'))
              : Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 680),
                      child: ShopSectionCard(
                        title: 'Order summary',
                        child: Column(
                          children: [
                            for (final item in items.values)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 54,
                                        height: 54,
                                        color: AppColors.paleCream,
                                        child: item.product.thumbnail.isEmpty
                                            ? const Icon(
                                                Icons.image_not_supported_outlined,
                                                color: AppColors.deepCoral,
                                                size: 20,
                                              )
                                            : Image.network(
                                                item.product.thumbnail,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    const Icon(
                                                  Icons.image_not_supported_outlined,
                                                  color: AppColors.deepCoral,
                                                  size: 20,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.product.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: AppColors.ink,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text('Quantity: ${item.quantity}',
                                              style: TextStyle(
                                                color: AppColors.ink
                                                    .withValues(alpha: 0.6),
                                                fontSize: 12,
                                              )),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('\$${item.total.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: AppColors.ink,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                        )),
                                  ],
                                ),
                              ),
                            const Divider(height: 18),
                            ShopPriceSummary(
                              subtotal: subtotal,
                              shipping: shipping,
                              total: total,
                            ),
                            const SizedBox(height: 16),
                            ShopPrimaryButton(
                              label: 'Place order · \$${total.toStringAsFixed(2)}',
                              icon: Icons.check_circle_outline_rounded,
                              onPressed: () => _placeOrder(context, ref),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Demo checkout · no payment will be processed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.ink.withValues(alpha: 0.55),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
    );
  }

  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final items = ref.read(cartProvider).items;
    if (items.isEmpty) return;

    final orderItems = items.values.toList(growable: false);
    final subtotal = cartSubtotal(items);
    final shipping = subtotal >= 100 ? 0.0 : 7.99;
    final total = subtotal + shipping;
    final itemCount = items.values.fold<int>(0, (sum, item) => sum + item.quantity);
    final orderNumber =
        'SS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    await ref.read(cartProvider.notifier).clear();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => OrderConfirmationScreen(
          orderNumber: orderNumber,
          orderItems: orderItems,
          itemCount: itemCount,
          total: total,
        ),
      ),
    );
  }
}

class OrderConfirmationScreen extends StatelessWidget {
  const OrderConfirmationScreen({
    super.key,
    required this.orderNumber,
    required this.orderItems,
    required this.itemCount,
    required this.total,
  });

  final String orderNumber;
  final List<CartItem> orderItems;
  final int itemCount;
  final double total;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(22),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  children: [
                    Container(
                      width: 104,
                      height: 104,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE4F4E9),
                      ),
                      child: const Icon(Icons.check_rounded,
                          size: 58, color: Color(0xFF32804A)),
                    ),
                    const SizedBox(height: 20),
                    const Text('Order confirmed!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: AppColors.ink,
                            fontSize: 28,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    Text(
                      'Your order has been placed successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.68),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Demo checkout · no payment was processed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 22),
                    ShopSectionCard(
                      title: 'Items ordered',
                      child: Column(
                        children: [
                          for (final item in orderItems)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.product.title}  ×  ${item.quantity}',
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Text('\$${item.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: AppColors.ink,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      )),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ShopSectionCard(
                      title: 'Order details',
                      child: Column(
                        children: [
                          _ConfirmationRow(
                              label: 'Order number', value: orderNumber),
                          _ConfirmationRow(label: 'Items', value: '$itemCount'),
                          _ConfirmationRow(
                            label: 'Order total',
                            value: '\$${total.toStringAsFixed(2)}',
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ShopPrimaryButton(
                      label: 'Continue shopping',
                      icon: Icons.storefront_rounded,
                      onPressed: () => Navigator.of(context)
                          .popUntil((route) => route.isFirst),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: AppColors.palePeach.withValues(alpha: 0.8))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 112,
              child: Text(label,
                  style: TextStyle(
                      color: AppColors.ink.withValues(alpha: 0.58),
                      fontSize: 12)),
            ),
            Expanded(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
}
