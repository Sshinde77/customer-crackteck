class ProductModel {
  final List<ProductData>? products;

  ProductModel({this.products});

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      products: json['products'] != null
          ? (json['products'] as List).map((i) => ProductData.fromJson(i)).toList()
          : null,
    );
  }
}

class ProductData {
  final int? id;
  final int? warehouseProductId;
  final String? sku;
  final String? metaTitle;
  final String? metaDescription;
  final String? metaKeywords;
  final String? metaProductUrlSlug;
  final String? ecommerceShortDescription;
  final String? ecommerceFullDescription;
  final String? ecommerceTechnicalSpecification;
  final String? ecommerceStatus;
  final String? createdAt;
  final String? updatedAt;
  final int? categoryId;
  final String? categoryName;
  final String? categorySlug;
  final WarehouseProduct? warehouseProduct;

  ProductData({
    this.id,
    this.warehouseProductId,
    this.sku,
    this.metaTitle,
    this.metaDescription,
    this.metaKeywords,
    this.metaProductUrlSlug,
    this.ecommerceShortDescription,
    this.ecommerceFullDescription,
    this.ecommerceTechnicalSpecification,
    this.ecommerceStatus,
    this.createdAt,
    this.updatedAt,
    this.categoryId,
    this.categoryName,
    this.categorySlug,
    this.warehouseProduct,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic>? warehouseJson =
        json['warehouse_product'] is Map<String, dynamic> ? json['warehouse_product'] as Map<String, dynamic> : null;

    int? tryParseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value);
      return null;
    }

    String? readString(dynamic value) {
      return value is String ? value : null;
    }

    final Map<String, dynamic>? categoryMap =
        json['category'] is Map<String, dynamic> ? json['category'] as Map<String, dynamic> : null;
    final Map<String, dynamic>? productCategoryMap =
        json['product_category'] is Map<String, dynamic> ? json['product_category'] as Map<String, dynamic> : null;

    final int? resolvedCategoryId =
        tryParseInt(json['category_id']) ??
        tryParseInt(json['product_category_id']) ??
        tryParseInt(json['category']) ??
        tryParseInt(json['product_category']) ??
        tryParseInt(json['categoryId']) ??
        tryParseInt(json['productCategoryId']) ??
        tryParseInt(categoryMap?['id']) ??
        tryParseInt(productCategoryMap?['id']) ??
        tryParseInt(warehouseJson?['category_id']) ??
        tryParseInt(warehouseJson?['product_category_id']) ??
        tryParseInt(warehouseJson?['category']) ??
        tryParseInt(warehouseJson?['product_category']) ??
        tryParseInt(warehouseJson?['categoryId']) ??
        tryParseInt(warehouseJson?['productCategoryId']);

    final String? resolvedCategory =
        readString(json['category_name']) ??
        readString(json['product_category_name']) ??
        readString(json['category']) ??
        readString(json['product_category']) ??
        readString(categoryMap?['name']) ??
        readString(productCategoryMap?['name']) ??
        readString(warehouseJson?['category_name']) ??
        readString(warehouseJson?['product_category_name']) ??
        readString(warehouseJson?['category']) ??
        readString(warehouseJson?['product_category']);

    final String? resolvedCategorySlug =
        readString(json['category_slug']) ??
        readString(json['product_category_slug']) ??
        readString(json['slug']) ??
        readString(categoryMap?['slug']) ??
        readString(productCategoryMap?['slug']) ??
        readString(warehouseJson?['category_slug']) ??
        readString(warehouseJson?['product_category_slug']) ??
        readString(warehouseJson?['slug']);

    return ProductData(
      id: json['id'],
      warehouseProductId: json['warehouse_product_id'],
      sku: json['sku'],
      metaTitle: json['meta_title'],
      metaDescription: json['meta_description'],
      metaKeywords: json['meta_keywords'],
      metaProductUrlSlug: json['meta_product_url_slug'],
      ecommerceShortDescription: json['ecommerce_short_description'],
      ecommerceFullDescription: json['ecommerce_full_description'],
      ecommerceTechnicalSpecification: json['ecommerce_technical_specification'],
      ecommerceStatus: json['ecommerce_status'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      categoryId: resolvedCategoryId,
      categoryName: resolvedCategory,
      categorySlug: resolvedCategorySlug,
      warehouseProduct: warehouseJson != null ? WarehouseProduct.fromJson(warehouseJson) : null,
    );
  }
}

class WarehouseProduct {
  final int? id;
  final String? vendorName;
  final String? productName;
  final String? hsnCode;
  final String? sku;
  final String? modelNo;
  final String? serialNo;
  final String? shortDescription;
  final String? fullDescription;
  final String? technicalSpecification;
  final String? costPrice;
  final String? discountPrice;
  final String? tax;
  final String? sellingPrice;
  final String? finalPrice;
  final int? stockQuantity;
  final String? stockStatus;
  final String? mainProductImage;
  final List<String>? additionalProductImages;

  WarehouseProduct({
    this.id,
    this.vendorName,
    this.productName,
    this.hsnCode,
    this.sku,
    this.modelNo,
    this.serialNo,
    this.shortDescription,
    this.fullDescription,
    this.technicalSpecification,
    this.costPrice,
    this.discountPrice,
    this.tax,
    this.sellingPrice,
    this.finalPrice,
    this.stockQuantity,
    this.stockStatus,
    this.mainProductImage,
    this.additionalProductImages,
  });

  factory WarehouseProduct.fromJson(Map<String, dynamic> json) {
    return WarehouseProduct(
      id: json['id'],
      vendorName: json['vendor_name'],
      productName: json['product_name'],
      hsnCode: json['hsn_code'],
      sku: json['sku'],
      modelNo: json['model_no'],
      serialNo: json['serial_no'],
      shortDescription: json['short_description'],
      fullDescription: json['full_description'],
      technicalSpecification: json['technical_specification'],
      costPrice: json['cost_price'],
      discountPrice: json['discount_price'],
      tax: json['tax'],
      sellingPrice: json['selling_price'],
      finalPrice: json['final_price'],
      stockQuantity: json['stock_quantity'],
      stockStatus: json['stock_status'],
      mainProductImage: json['main_product_image'],
      additionalProductImages: json['additional_product_images'] != null
          ? List<String>.from(json['additional_product_images'])
          : null,
    );
  }
}
