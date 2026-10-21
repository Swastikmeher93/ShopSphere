import 'package:ecommerce_app/constants/app_colors.dart';
import 'package:ecommerce_app/provider/cart_provider.dart';
import 'package:flutter/material.dart';

class ShopSectionCard extends StatelessWidget {
  const ShopSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      )),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      );
}

class ShopPrimaryButton extends StatelessWidget {
  const ShopPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 54,
        child: FilledButton.icon(
          onPressed: onPressed,
          icon: Icon(icon ?? Icons.arrow_forward_rounded),
          label: Text(label,
              style: const TextStyle(fontWeight: FontWeight.w700)),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.deepCoral,
            foregroundColor: Colors.white,
            disabledBackgroundColor: AppColors.deepCoral.withValues(alpha: 0.4),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      );
}

class ShopPriceSummary extends StatelessWidget {
  const ShopPriceSummary({
    super.key,
    required this.subtotal,
    required this.shipping,
    required this.total,
  });

  final double subtotal;
  final double shipping;
  final double total;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _PriceRow(label: 'Subtotal', amount: subtotal),
          const SizedBox(height: 10),
          _PriceRow(
            label: 'Shipping',
            amount: shipping,
            free: shipping == 0,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1),
          ),
          _PriceRow(label: 'Total', amount: total, bold: true),
        ],
      );
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.free = false,
    this.bold = false,
  });

  final String label;
  final double amount;
  final bool free;
  final bool bold;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: AppColors.ink.withValues(alpha: bold ? 1 : 0.68),
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
                  fontSize: bold ? 16 : 14,
                )),
          ),
          Text(
            free ? 'FREE' : '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: bold ? AppColors.deepCoral : AppColors.ink,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 18 : 14,
            ),
          ),
        ],
      );
}

class CartLineTile extends StatelessWidget {
  const CartLineTile({
    super.key,
    required this.item,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartItem item;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              width: 84,
              height: 92,
              color: AppColors.paleCream,
              child: product.thumbnail.isEmpty
                  ? const Icon(Icons.image_not_supported_outlined,
                      color: AppColors.deepCoral)
                  : Image.network(
                      product.thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.deepCoral),
                    ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    )),
                const SizedBox(height: 5),
                Text('\$${item.unitPrice.toStringAsFixed(2)} each',
                    style: TextStyle(
                        color: AppColors.ink.withValues(alpha: 0.6),
                        fontSize: 12)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: () => onQuantityChanged(item.quantity - 1),
                    ),
                    SizedBox(
                      width: 34,
                      child: Text('${item.quantity}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink)),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: () => onQuantityChanged(item.quantity + 1),
                    ),
                    const Spacer(),
                    Text('\$${item.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.deepCoral,
                          fontWeight: FontWeight.w800,
                        )),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove item',
            onPressed: onRemove,
            icon: const Icon(Icons.delete_outline_rounded,
                color: AppColors.deepCoral),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  const _QuantityButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.paleCream,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: AppColors.deepCoral),
        ),
      );
}
