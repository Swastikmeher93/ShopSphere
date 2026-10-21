import 'package:ecommerce_app/constants/app_colors.dart';
import 'package:ecommerce_app/model/product_model.dart';
import 'package:ecommerce_app/provider/cart_provider.dart';
import 'package:ecommerce_app/provider/product_provider.dart';
import 'package:ecommerce_app/screens/cart_screen.dart';
import 'package:ecommerce_app/screens/widgets/cart_action_button.dart';
import 'package:ecommerce_app/screens/widgets/shop_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductDetailsScreen extends ConsumerWidget {
  const ProductDetailsScreen({
    super.key,
    required this.productId,
    this.initialProduct,
  });

  final int productId;
  final ProductElement? initialProduct;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productDetailsProvider(productId));
    final cartQuantity =
        ref.watch(cartProvider).items[productId]?.quantity ?? 0;
    final product = productAsync.value ?? initialProduct;
    Widget showProduct(ProductElement product) => _ProductDetails(
      product: product,
      cartQuantity: cartQuantity,
      onAddToCart: () {
        ref.read(cartProvider.notifier).add(product);
      },
      onDecreaseQuantity: () => ref
          .read(cartProvider.notifier)
          .setQuantity(productId, cartQuantity - 1),
      onGoToCart: () => Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => const CartScreen())),
    );
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        title: const Text('Product details'),
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        actions: const [CartActionButton()],
      ),
      body: product != null
          ? showProduct(product)
          : productAsync.when(
              data: showProduct,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.deepCoral),
              ),
              error: (error, stackTrace) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        size: 44,
                        color: AppColors.deepCoral,
                      ),
                      const SizedBox(height: 12),
                      const Text('Could not load this product.'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(productDetailsProvider(productId)),
                        child: const Text('Try again'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class _ProductDetails extends StatefulWidget {
  const _ProductDetails({
    required this.product,
    required this.cartQuantity,
    required this.onAddToCart,
    required this.onDecreaseQuantity,
    required this.onGoToCart,
  });

  final ProductElement product;
  final int cartQuantity;
  final VoidCallback onAddToCart;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onGoToCart;

  @override
  State<_ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<_ProductDetails> {
  final _pageController = PageController();
  int _imageIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = <String>[];
    for (final source in [product.thumbnail, ...product.images]) {
      final image = source.trim();
      if (image.isNotEmpty && !images.contains(image)) images.add(image);
    }
    final category = _titleCase(product.category.replaceAll('-', ' '));
    final salePrice = product.price * (1 - product.discountPercentage / 100);

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final gallery = _ProductGallery(
          productId: product.id,
          images: images,
          controller: _pageController,
          currentIndex: _imageIndex,
          onPageChanged: (index) => setState(() => _imageIndex = index),
        );
        final summary = _ProductSummary(
          product: product,
          category: category,
          salePrice: salePrice,
          cartQuantity: widget.cartQuantity,
          onAddToCart: widget.onAddToCart,
          onDecreaseQuantity: widget.onDecreaseQuantity,
          onGoToCart: widget.onGoToCart,
        );

        return SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 11, child: gallery),
                          const SizedBox(width: 28),
                          Expanded(flex: 9, child: summary),
                        ],
                      )
                    else ...[
                      gallery,
                      const SizedBox(height: 22),
                      summary,
                    ],
                    const SizedBox(height: 24),
                    _InformationSection(
                      title: 'About this product',
                      child: Text(
                        product.description.isEmpty
                            ? 'No description available.'
                            : product.description,
                        style: TextStyle(
                          height: 1.55,
                          color: AppColors.ink.withValues(alpha: 0.78),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _InformationSection(
                      title: 'Product information',
                      child: Column(
                        children: [
                          _InfoRow(label: 'Product ID', value: '${product.id}'),
                          _InfoRow(label: 'SKU', value: _orDash(product.sku)),
                          _InfoRow(
                            label: 'Brand',
                            value: _orDash(product.brand),
                          ),
                          _InfoRow(label: 'Category', value: category),
                          _InfoRow(
                            label: 'Weight',
                            value: product.weight > 0
                                ? '${product.weight} kg'
                                : '—',
                          ),
                          _InfoRow(
                            label: 'Dimensions',
                            value: _orDash(product.dimensions),
                          ),
                          _InfoRow(
                            label: 'Minimum order',
                            value: '${product.minimumOrderQuantity} items',
                          ),
                          _InfoRow(
                            label: 'Availability',
                            value: _orDash(product.availabilityStatus),
                          ),
                          _InfoRow(
                            label: 'Shipping',
                            value: _orDash(product.shippingInformation),
                          ),
                          _InfoRow(
                            label: 'Warranty',
                            value: _orDash(product.warrantyInformation),
                          ),
                          _InfoRow(
                            label: 'Returns',
                            value: _orDash(product.returnPolicy),
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    if (product.tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InformationSection(
                        title: 'Tags',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: product.tags
                              .map(
                                (tag) => Chip(
                                  label: Text(_titleCase(tag)),
                                  backgroundColor: AppColors.paleCream,
                                  side: BorderSide.none,
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                    if (product.reviews.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _InformationSection(
                        title: 'Customer reviews (${product.reviews.length})',
                        child: Column(
                          children: product.reviews
                              .map((review) => _ReviewTile(review: review))
                              .toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductGallery extends StatelessWidget {
  const _ProductGallery({
    required this.productId,
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  final int productId;
  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 1.05,
          child: Container(
            color: Colors.white,
            child: images.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 56,
                      color: AppColors.deepCoral,
                    ),
                  )
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      PageView.builder(
                        controller: controller,
                        itemCount: images.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, index) {
                          final image = Image.network(
                            images[index],
                            key: ValueKey(images[index]),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 56,
                                    color: AppColors.deepCoral,
                                  ),
                                ),
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.deepCoral,
                                    ),
                                  ),
                          );
                          return index == 0
                              ? Hero(
                                  tag: 'product-image-$productId',
                                  child: image,
                                )
                              : image;
                        },
                      ),
                      if (images.length > 1) ...[
                        Positioned(
                          left: 8,
                          top: 0,
                          bottom: 0,
                          child: _GalleryArrow(
                            icon: Icons.chevron_left_rounded,
                            label: 'Previous image',
                            onPressed: currentIndex > 0
                                ? () => _showPage(currentIndex - 1)
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 8,
                          top: 0,
                          bottom: 0,
                          child: _GalleryArrow(
                            icon: Icons.chevron_right_rounded,
                            label: 'Next image',
                            onPressed: currentIndex < images.length - 1
                                ? () => _showPage(currentIndex + 1)
                                : null,
                          ),
                        ),
                        Positioned(
                          right: 14,
                          bottom: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.ink.withValues(alpha: 0.72),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${currentIndex + 1} / ${images.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
      if (images.length > 1) ...[
        const SizedBox(height: 12),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) => Semantics(
              button: true,
              selected: index == currentIndex,
              label: 'Show image ${index + 1} of ${images.length}',
              child: InkWell(
                onTap: () => _showPage(index),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 68,
                  height: 68,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: index == currentIndex
                          ? AppColors.deepCoral
                          : AppColors.palePeach,
                      width: index == currentIndex ? 2 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const ColoredBox(
                        color: AppColors.paleCream,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.deepCoral,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ],
  );

  void _showPage(int index) {
    controller.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }
}

class _GalleryArrow extends StatelessWidget {
  const _GalleryArrow({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Center(
    child: Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, color: AppColors.deepCoral),
      ),
    ),
  );
}

class _ProductSummary extends StatelessWidget {
  const _ProductSummary({
    required this.product,
    required this.category,
    required this.salePrice,
    required this.cartQuantity,
    required this.onAddToCart,
    required this.onDecreaseQuantity,
    required this.onGoToCart,
  });

  final ProductElement product;
  final String category;
  final double salePrice;
  final int cartQuantity;
  final VoidCallback onAddToCart;
  final VoidCallback onDecreaseQuantity;
  final VoidCallback onGoToCart;

  @override
  Widget build(BuildContext context) {
    final inStock = product.stock > 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.palePeach,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            category,
            style: const TextStyle(
              color: AppColors.deepCoral,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          product.title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 28,
            height: 1.15,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (product.brand?.isNotEmpty == true) ...[
          const SizedBox(height: 7),
          Text(
            'by ${product.brand}',
            style: TextStyle(color: AppColors.ink.withValues(alpha: 0.6)),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(
              Icons.star_rounded,
              color: AppColors.ratingStar,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              product.rating.toStringAsFixed(1),
              style: const TextStyle(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '  ·  Product #${product.id}',
              style: TextStyle(color: AppColors.ink.withValues(alpha: 0.58)),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${salePrice.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.deepCoral,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (product.discountPercentage > 0) ...[
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: AppColors.ink.withValues(alpha: 0.5),
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text(
                  '${product.discountPercentage.round()}% off',
                  style: const TextStyle(
                    color: AppColors.deepCoral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(
              inStock ? Icons.check_circle : Icons.cancel,
              size: 18,
              color: inStock ? Colors.green.shade700 : AppColors.deepCoral,
            ),
            const SizedBox(width: 6),
            Text(
              inStock ? '${product.stock} available' : 'Out of stock',
              style: TextStyle(
                color: inStock ? Colors.green.shade700 : AppColors.deepCoral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (cartQuantity == 0)
          ShopPrimaryButton(
            label: 'Add to cart',
            icon: Icons.add_shopping_cart_rounded,
            onPressed: product.stock > 0 ? onAddToCart : null,
          )
        else ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.palePeach),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 19,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Added to cart',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove one',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDecreaseQuantity,
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                ),
                Text(
                  '$cartQuantity',
                  style: const TextStyle(
                    color: AppColors.ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  tooltip: 'Add one',
                  visualDensity: VisualDensity.compact,
                  onPressed: cartQuantity < product.stock ? onAddToCart : null,
                  color: AppColors.deepCoral,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ShopPrimaryButton(
            label: 'Go to cart',
            icon: Icons.shopping_cart_rounded,
            onPressed: onGoToCart,
          ),
        ],
        const SizedBox(height: 18),
        const _BenefitLine(
          icon: Icons.local_shipping_outlined,
          text: 'Shipping details shown below',
        ),
        const SizedBox(height: 9),
        const _BenefitLine(
          icon: Icons.verified_outlined,
          text: 'Warranty and return information included',
        ),
      ],
    );
  }
}

class _BenefitLine extends StatelessWidget {
  const _BenefitLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.deepCoral),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(
            color: AppColors.ink.withValues(alpha: 0.72),
            fontSize: 13,
          ),
        ),
      ),
    ],
  );
}

class _InformationSection extends StatelessWidget {
  const _InformationSection({required this.title, required this.child});
  final String title;
  final Widget child;

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
        Text(
          title,
          style: const TextStyle(
            color: AppColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
                color: AppColors.palePeach.withValues(alpha: 0.8),
              ),
            ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.6),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final ProductReview review;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                review.reviewerName,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.star_rounded,
              size: 17,
              color: AppColors.ratingStar,
            ),
            Text(review.rating.toStringAsFixed(1)),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          review.comment,
          style: TextStyle(color: AppColors.ink.withValues(alpha: 0.75)),
        ),
        if (review.date.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            review.date,
            style: TextStyle(
              color: AppColors.ink.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
        const Divider(height: 18),
      ],
    ),
  );
}

String _titleCase(String value) => value
    .split(' ')
    .where((word) => word.isNotEmpty)
    .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

String _orDash(String? value) => value == null || value.isEmpty ? '—' : value;
