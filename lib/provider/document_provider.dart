import 'package:flutter/material.dart';
import '../models/aadhar_card_model.dart';
import '../models/pan_card_model.dart';
import '../services/api_service.dart';

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

    await Future.wait([fetchAadharDetails(), fetchPanDetails()]);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchAadharDetails() async {
    try {
      final response = await ApiService.instance.getAadharDetails();
      if (response.success) {
        _aadharCard = response.data;
      } else {
        _aadharCard = null;
      }
    } catch (e) {
      debugPrint("Error fetching Aadhar: $e");
    }
  }

  Future<void> fetchPanDetails() async {
    try {
      final response = await ApiService.instance.getPanDetails();
      if (response.success) {
        _panCard = response.data;
      } else {
        _panCard = null;
      }
    } catch (e) {
      debugPrint("Error fetching PAN: $e");
    }
  }
}
