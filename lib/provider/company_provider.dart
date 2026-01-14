import 'package:flutter/material.dart';
import '../models/company_model.dart';
import '../services/api_service.dart';
import '../constants/core/secure_storage_service.dart';

class CompanyProvider extends ChangeNotifier {
  CompanyDetails? _companyDetails;
  bool _isLoading = false;

  CompanyDetails? get companyDetails => _companyDetails;
  bool get isLoading => _isLoading;

  Future<void> fetchCompanyDetails() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId != null && roleId != null) {
        final response = await ApiService.instance.getCompanyDetails(
          userId: userId,
          roleId: roleId,
        );

        if (response.success) {
          _companyDetails = response.data;
        }
      }
    } catch (e) {
      debugPrint("Error fetching company details: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveCompanyDetails({
    required String companyName,
    required String address1,
    required String address2,
    required String city,
    required String state,
    required String country,
    required String pincode,
    required String gstNo,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId != null && roleId != null) {
        final response = await ApiService.instance.storeCompanyDetails(
          userId: userId,
          roleId: roleId,
          companyName: companyName,
          address1: address1,
          address2: address2,
          city: city,
          state: state,
          country: country,
          pincode: pincode,
          gstNo: gstNo,
          companyId: _companyDetails?.id,
        );

        if (response.success) {
          await fetchCompanyDetails();
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint("Error saving company details: $e");
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
