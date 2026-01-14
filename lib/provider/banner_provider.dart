import 'package:flutter/material.dart';
import '../models/banner_model.dart';
import '../services/api_service.dart';
import '../constants/app_strings.dart';

class BannerProvider extends ChangeNotifier {
  List<BannerModel> _banners = [];
  bool _isLoading = false;

  List<BannerModel> get banners => _banners;
  bool get isLoading => _isLoading;

  Future<void> fetchBanners() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.instance.getBanners(
        roleId: AppStrings.roleId,
      );

      if (response.success) {
        _banners = response.data ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching banners: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
