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
    this.warehouseProduct,
  });

  factory ProductData.fromJson(Map<String, dynamic> json) {
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
      warehouseProduct: json['warehouse_product'] != null
          ? WarehouseProduct.fromJson(json['warehouse_product'])
          : null,
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
