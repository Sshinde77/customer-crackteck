import 'package:flutter/material.dart';
import '../models/aadhar_card_model.dart';
import '../models/pan_card_model.dart';
import '../constants/api_constants.dart';
import '../constants/core/secure_storage_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DocumentProvider extends ChangeNotifier {
  AadharCard? _aadharCard;
  PanCard? _panCard;
  bool _isLoading = false;

  AadharCard? get aadharCard => _aadharCard;
  PanCard? get panCard => _panCard;
  bool get isLoading => _isLoading;

  Future<void> fetchAllDocuments() async {
    _isLoading = true;
    notifyListeners();
    
    await Future.wait([
      fetchAadharDetails(),
      fetchPanDetails(),
    ]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAadharDetails() async {
    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();
      final token = await SecureStorageService.getAccessToken();

      final url = Uri.parse(ApiConstants.aadharCard).replace(
        queryParameters: {
          'user_id': userId?.toString() ?? '',
          'role_id': roleId?.toString() ?? '',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _aadharCard = AadharCardResponse.fromJson(jsonResponse).aadharCard;
      } else if (response.statusCode == 404) {
        _aadharCard = null;
      }
    } catch (e) {
      debugPrint("Error fetching Aadhar: $e");
    }
  }

  Future<void> fetchPanDetails() async {
    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();
      final token = await SecureStorageService.getAccessToken();

      final url = Uri.parse(ApiConstants.panCard).replace(
        queryParameters: {
          'user_id': userId?.toString() ?? '',
          'role_id': roleId?.toString() ?? '',
        },
      );

      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(ApiConstants.requestTimeout);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _panCard = PanCardResponse.fromJson(jsonResponse).panCard;
      } else if (response.statusCode == 404) {
        _panCard = null;
      }
    } catch (e) {
      debugPrint("Error fetching PAN: $e");
    }
  }
}
