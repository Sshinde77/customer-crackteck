class BannerResponse {
  final List<BannerModel>? banners;

  BannerResponse({this.banners});

  factory BannerResponse.fromJson(Map<String, dynamic> json) {
    return BannerResponse(
      banners: json['banners'] != null
          ? (json['banners'] as List).map((i) => BannerModel.fromJson(i)).toList()
          : null,
    );
  }
}

class BannerModel {
  final int? id;
  final String? bannerPath;
  final String? createdAt;
  final String? updatedAt;

  BannerModel({this.id, this.bannerPath, this.createdAt, this.updatedAt});

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'],
      bannerPath: json['banner_path'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
