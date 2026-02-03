class ProductCategoryResponse {
  final List<ProductCategory> categories;

  ProductCategoryResponse({required this.categories});

  factory ProductCategoryResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['categories'] ?? [];
    return ProductCategoryResponse(
      categories: raw.map((e) => ProductCategory.fromJson(e)).toList(),
    );
  }
}

class ProductCategory {
  final int? id;
  final String? name;
  final String? slug;
  final String? image;
  final int? sortOrder;
  final String? statusEcommerce;
  final String? status;
  final String? deletedAt;
  final String? createdAt;
  final String? updatedAt;

  ProductCategory({
    this.id,
    this.name,
    this.slug,
    this.image,
    this.sortOrder,
    this.statusEcommerce,
    this.status,
    this.deletedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      image: json['image'],
      sortOrder: json['sort_order'],
      statusEcommerce: json['status_ecommerce'],
      status: json['status'],
      deletedAt: json['deleted_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
