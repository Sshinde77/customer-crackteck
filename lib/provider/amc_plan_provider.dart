import 'package:flutter/material.dart';
import '../models/amc_plan_model.dart';
import '../services/api_service.dart';
import '../constants/app_strings.dart';

class AmcPlanProvider extends ChangeNotifier {
  List<AmcPlanItem> _amcPlans = [];
  AmcPlanDetailResponse? _planDetail;
  bool _isLoading = false;
  bool _isLoadingDetail = false;
  String? _errorMessage;
  String? _detailErrorMessage;

  List<AmcPlanItem> get amcPlans => _amcPlans;
  AmcPlanDetailResponse? get planDetail => _planDetail;
  bool get isLoading => _isLoading;
  bool get isLoadingDetail => _isLoadingDetail;
  String? get errorMessage => _errorMessage;
  String? get detailErrorMessage => _detailErrorMessage;

  Future<void> fetchAmcPlans() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.instance.getAmcPlans(
        roleId: AppStrings.roleId,
      );

      if (response.success) {
        _amcPlans = response.data ?? [];
        _errorMessage = null;
      } else {
        _errorMessage = response.message ?? 'Failed to fetch AMC plans';
      }
    } catch (e) {
      debugPrint("Error fetching AMC plans: $e");
      _errorMessage = 'An error occurred while fetching AMC plans';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAmcPlanDetails({required int planId}) async {
    _isLoadingDetail = true;
    _detailErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.instance.getAmcPlanDetails(
        planId: planId,
        roleId: AppStrings.roleId,
      );

      if (response.success) {
        _planDetail = response.data;
        _detailErrorMessage = null;
      } else {
        _detailErrorMessage =
            response.message ?? 'Failed to fetch AMC plan details';
      }
    } catch (e) {
      debugPrint("Error fetching AMC plan details: $e");
      _detailErrorMessage = 'An error occurred while fetching plan details';
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearDetailError() {
    _detailErrorMessage = null;
    notifyListeners();
  }

  void clearPlanDetail() {
    _planDetail = null;
    _detailErrorMessage = null;
    notifyListeners();
  }
}
