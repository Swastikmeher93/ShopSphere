class Product {
  const Product({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<ProductElement> products;
  final int total;
  final int skip;
  final int limit;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawProducts = json['products'] as List<dynamic>? ?? const [];
    return Product(
      products: rawProducts
          .whereType<Map<String, dynamic>>()
          .map(ProductElement.fromJson)
          .toList(growable: false),
      total: (json['total'] as num?)?.toInt() ?? 0,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? 0,
    );
  }
}

class ProductElement {
  const ProductElement({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.price,
    required this.discountPercentage,
    required this.rating,
    required this.stock,
    required this.thumbnail,
    this.brand,
    this.images = const [],
  });

  final int id;
  final String title;
  final String description;
  final String category;
  final double price;
  final double discountPercentage;
  final double rating;
  final int stock;
  final String? brand;
  final List<String> images;
  final String thumbnail;

  factory ProductElement.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);

    return ProductElement(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Untitled product',
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'uncategorized',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      discountPercentage:
          (json['discountPercentage'] as num?)?.toDouble() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      brand: json['brand'] as String?,
      images: images,
      thumbnail: json['thumbnail'] as String? ??
          (images.isNotEmpty ? images.first : ''),
    );
  }
}
