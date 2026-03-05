import 'package:flutter/material.dart';
import '../models/quick_service_model.dart';
import '../services/api_service.dart';

class QuickServiceProvider extends ChangeNotifier {
  List<QuickService> _homeQuickServices = const [];
  List<QuickService> _requestServices = const [];
  QuickService? _fixedQuickService;
  QuickService? _selectedService;
  bool _isHomeLoading = false;
  bool _isRequestLoading = false;
  bool _isHomeInitialized = false;
  String? _homeErrorMessage;
  String? _requestErrorMessage;

  // Home-only state
  List<QuickService> get homeQuickServices => _homeQuickServices;
  QuickService? get fixedQuickService => _fixedQuickService;
  List<QuickService> get otherHomeQuickServices {
    final fixed = _fixedQuickService;
    if (fixed == null) return _homeQuickServices;
    return _homeQuickServices
        .where((service) => !_isSameService(service, fixed))
        .toList(growable: false);
  }

  bool get isHomeLoading => _isHomeLoading;
  String? get homeErrorMessage => _homeErrorMessage;

  // Request-screen state
  List<QuickService> get requestServices => _requestServices;
  bool get isRequestLoading => _isRequestLoading;
  String? get requestErrorMessage => _requestErrorMessage;

  // Navigation-only selection state
  QuickService? get selectedService => _selectedService;

  // Backward-compatible aliases used by existing screens.
  List<QuickService> get quickServices => _requestServices;
  bool get isLoading => _isHomeLoading;
  String? get errorMessage => _homeErrorMessage;
  List<QuickService> get otherServices => otherHomeQuickServices;

  Future<void> fetchHomeQuickServices({bool forceRefresh = false}) async {
    if (_isHomeInitialized && !forceRefresh) return;

    _isHomeLoading = true;
    _homeErrorMessage = null;
    notifyListeners();

    try {
      final response = await ApiService.instance.getQuickServices();

      if (response.success) {
        final fetched = response.data ?? const <QuickService>[];
        _homeQuickServices = List<QuickService>.unmodifiable(fetched);
        _isHomeInitialized = true;
        _initializeFixedQuickServiceIfNeeded();
      } else {
        _homeQuickServices = const [];
        _homeErrorMessage = response.message;
      }
    } catch (e) {
      debugPrint("Error fetching home quick services: $e");
      _homeQuickServices = const [];
      _homeErrorMessage = 'Failed to fetch quick services';
    } finally {
      _isHomeLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRequestServices({required String serviceType}) async {
    _isRequestLoading = true;
    _requestErrorMessage = null;
    _requestServices = const [];
    notifyListeners();

    try {
      final normalizedType = serviceType.trim().toLowerCase();

      final response = normalizedType == 'quick_service'
          ? await ApiService.instance.getQuickServices()
          : await ApiService.instance.getServicesList(
              serviceType: normalizedType,
            );

      if (response.success) {
        final fetched = response.data ?? const <QuickService>[];
        _requestServices = List<QuickService>.unmodifiable(fetched);
      } else {
        _requestServices = const [];
        _requestErrorMessage = response.message;
      }
    } catch (e) {
      debugPrint("Error fetching request services: $e");
      _requestServices = const [];
      _requestErrorMessage = 'Failed to fetch services';
    } finally {
      _isRequestLoading = false;
      notifyListeners();
    }
  }

  // Backward-compatible wrapper.
  Future<void> fetchQuickServices({String serviceType = 'quick_service'}) {
    return fetchRequestServices(serviceType: serviceType);
  }

  // Selection is for navigation flow only; no Home/UI rebuild required.
  void setSelectedServiceForNavigation(QuickService service) {
    _selectedService = service;
  }

  // Backward-compatible alias.
  void selectService(QuickService service) {
    setSelectedServiceForNavigation(service);
  }

  void clearSelectedService() {
    _selectedService = null;
  }

  void _initializeFixedQuickServiceIfNeeded() {
    if (_fixedQuickService == null && _homeQuickServices.isNotEmpty) {
      _fixedQuickService = _homeQuickServices.first;
    }
  }

  bool _isSameService(QuickService a, QuickService b) {
    if (a.id != null && b.id != null) return a.id == b.id;
    if ((a.itemCode ?? '').isNotEmpty && (b.itemCode ?? '').isNotEmpty) {
      return a.itemCode == b.itemCode;
    }
    return a.serviceName == b.serviceName;
  }
}
