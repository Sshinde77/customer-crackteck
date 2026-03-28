import 'package:flutter/material.dart';
import '../models/company_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

class CompanyProvider extends ChangeNotifier {
  CompanyDetails? _companyDetails;
  bool _isLoading = false;

  CompanyDetails? get companyDetails => _companyDetails;
  bool get isLoading => _isLoading;

  Future<void> fetchCompanyDetails() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await ApiService.instance.getCompanyDetails();
      if (response.success) {
        _companyDetails = response.data;
      }
    } catch (e) {
      debugPrint("Error fetching company details: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<ApiResponse> saveCompanyDetails({
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
      final response = await ApiService.instance.storeCompanyDetails(
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
        return response;
      }
      return response;
    } catch (e) {
      debugPrint("Error saving company details: $e");
      return ApiResponse(success: false, message: 'Failed to save company details');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
