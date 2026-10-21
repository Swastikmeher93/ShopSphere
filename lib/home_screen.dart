import 'package:ecommerce_app/constants/app_colors.dart';
import 'package:ecommerce_app/provider/auth_provider.dart';
import 'package:ecommerce_app/provider/product_provider.dart';
import 'package:ecommerce_app/screens/profile_screen.dart';
import 'package:ecommerce_app/screens/widgets/cart_action_button.dart';
import 'package:ecommerce_app/screens/widgets/product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final user = ref.watch(authProvider).user;
    final name = user?.firstName ?? user?.username ?? 'Shopper';
    final productsAsync = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopesphere'),
        backgroundColor: AppColors.coral,
        foregroundColor: Colors.white,
        actions: [
          const CartActionButton(),
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ProfileScreen(),
              ),
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      backgroundColor: AppColors.cream,
      body: productsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.deepCoral),
        ),
        error: (error, stackTrace) => _ProductsError(
          onRetry: () => ref.invalidate(productProvider),
        ),
        data: (productResponse) => LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 1000
                ? 4
                : constraints.maxWidth >= 650
                    ? 3
                    : 2;

            final allProducts = productResponse.products;
            final categories = allProducts
                .map((product) => product.category)
                .where((category) => category.isNotEmpty)
                .toSet()
                .toList()
              ..sort();
            final query = _query.trim().toLowerCase();
            final products = allProducts.where((product) {
              final matchesCategory = _selectedCategory == null ||
                  product.category == _selectedCategory;
              final searchableText =
                  '${product.title} ${product.description} ${product.category} ${product.brand ?? ''}'
                      .toLowerCase();
              return matchesCategory &&
                  (query.isEmpty || searchableText.contains(query));
            }).toList(growable: false);

            return RefreshIndicator(
              color: AppColors.deepCoral,
              onRefresh: () async {
                ref.invalidate(productProvider);
                await ref.read(productProvider.future);
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $name!',
                            style: const TextStyle(
                              color: AppColors.ink,
                              fontSize: 25,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "Find something you'll love today.",
                            style: TextStyle(
                              color: AppColors.ink.withValues(alpha: 0.62),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _searchController,
                            onChanged: (value) => setState(() => _query = value),
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search products, brands...',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: 'Clear search',
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide(
                                  color: AppColors.palePeach.withValues(alpha: 0.8),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: const BorderSide(
                                  color: AppColors.deepCoral,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Categories',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 40,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _CategoryChip(
                                  label: 'All',
                                  selected: _selectedCategory == null,
                                  onTap: () => setState(() => _selectedCategory = null),
                                ),
                                ...categories.map((category) => _CategoryChip(
                                      label: _formatCategory(category),
                                      selected: _selectedCategory == category,
                                      onTap: () => setState(
                                          () => _selectedCategory = category),
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 23),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Discover',
                                  style: TextStyle(
                                    color: AppColors.ink,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              Text(
                                '${products.length} products',
                                style: TextStyle(
                                  color: AppColors.ink.withValues(alpha: 0.58),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (products.isEmpty)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: Text('No matching products found.')),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid.builder(
                        itemCount: products.length,
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 13,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.68,
                        ),
                        itemBuilder: (context, index) => ProductCard(
                          product: products[index],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

String _formatCategory(String category) => category
    .split('-')
    .map((word) => word.isEmpty
        ? word
        : '${word[0].toUpperCase()}${word.substring(1)}')
    .join(' ');

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: selected,
          onSelected: (_) => onTap(),
          selectedColor: AppColors.deepCoral,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.ink,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          side: BorderSide(
            color: selected ? AppColors.deepCoral : AppColors.palePeach,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        ),
      );
}

class _ProductsError extends StatelessWidget {
  const _ProductsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: AppColors.deepCoral,
            ),
            const SizedBox(height: 12),
            const Text(
              'Could not load products',
              style: TextStyle(
                color: AppColors.ink,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.ink.withValues(alpha: 0.65)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.deepCoral,
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
