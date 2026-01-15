import 'package:flutter/material.dart';
import '../models/quick_service_model.dart';
import '../services/api_service.dart';
import '../constants/app_strings.dart';

class QuickServiceProvider extends ChangeNotifier {
  List<QuickService> _quickServices = [];
  bool _isLoading = false;

  List<QuickService> get quickServices => _quickServices;
  bool get isLoading => _isLoading;

  Future<void> fetchQuickServices({String serviceType = 'quick_service'}) async {
    _isLoading = true;
    _quickServices = [];
    notifyListeners();

    try {
      final response = await ApiService.instance.getServicesList(
        roleId: AppStrings.roleId,
        serviceType: serviceType,
      );

      if (response.success) {
        _quickServices = response.data ?? [];
      }
    } catch (e) {
      debugPrint("Error fetching quick services: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
