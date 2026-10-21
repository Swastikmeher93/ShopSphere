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
    this.sku = '',
    this.warrantyInformation = '',
    this.shippingInformation = '',
    this.availabilityStatus = '',
    this.returnPolicy = '',
    this.minimumOrderQuantity = 1,
    this.tags = const [],
    this.reviews = const [],
    this.weight = 0,
    this.dimensions = '',
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
  final String sku;
  final String warrantyInformation;
  final String shippingInformation;
  final String availabilityStatus;
  final String returnPolicy;
  final int minimumOrderQuantity;
  final List<String> tags;
  final List<ProductReview> reviews;
  final double weight;
  final String dimensions;

  factory ProductElement.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final tags = (json['tags'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList(growable: false);
    final reviews = (json['reviews'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ProductReview.fromJson)
        .toList(growable: false);
    final rawDimensions = json['dimensions'];
    final dimensions = rawDimensions is Map<String, dynamic>
        ? ['width', 'height', 'depth']
            .where((key) => rawDimensions[key] != null)
            .map((key) => '$key ${rawDimensions[key]} cm')
            .join(', ')
        : '';

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
      sku: json['sku'] as String? ?? '',
      warrantyInformation: json['warrantyInformation'] as String? ?? '',
      shippingInformation: json['shippingInformation'] as String? ?? '',
      availabilityStatus: json['availabilityStatus'] as String? ?? '',
      returnPolicy: json['returnPolicy'] as String? ?? '',
      minimumOrderQuantity:
          (json['minimumOrderQuantity'] as num?)?.toInt() ?? 1,
      tags: tags,
      reviews: reviews,
      weight: (json['weight'] as num?)?.toDouble() ?? 0,
      dimensions: dimensions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'price': price,
        'discountPercentage': discountPercentage,
        'rating': rating,
        'stock': stock,
        'brand': brand,
        'images': images,
        'thumbnail': thumbnail,
        'sku': sku,
        'warrantyInformation': warrantyInformation,
        'shippingInformation': shippingInformation,
        'availabilityStatus': availabilityStatus,
        'returnPolicy': returnPolicy,
        'minimumOrderQuantity': minimumOrderQuantity,
        'tags': tags,
        'reviews': reviews
            .map((review) => {
                  'rating': review.rating,
                  'comment': review.comment,
                  'date': review.date,
                  'reviewerName': review.reviewerName,
                })
            .toList(growable: false),
        'weight': weight,
      };
}

class ProductReview {
  const ProductReview({
    required this.rating,
    required this.comment,
    required this.date,
    required this.reviewerName,
  });

  final double rating;
  final String comment;
  final String date;
  final String reviewerName;

  factory ProductReview.fromJson(Map<String, dynamic> json) => ProductReview(
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        comment: json['comment'] as String? ?? '',
        date: json['date'] as String? ?? '',
        reviewerName: json['reviewerName'] as String? ?? 'Shopper',
      );
}
