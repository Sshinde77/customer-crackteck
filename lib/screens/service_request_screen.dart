import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/address_model.dart';
import '../models/quick_service_model.dart';
import '../provider/quick_service_provider.dart';
import '../services/api_service.dart';
import '../services/image_capture_service.dart';
import 'address_screen.dart';
import 'payment_screen.dart';
import 'service_detail_screen.dart';

class ServiceProductFormModel {
  QuickService? selectedQuickService;
  final TextEditingController typeController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController modelNoController = TextEditingController();
  final TextEditingController macAddressController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<File> selectedImages = [];

  void dispose() {
    typeController.dispose();
    nameController.dispose();
    modelNoController.dispose();
    macAddressController.dispose();
    purchaseDateController.dispose();
    brandController.dispose();
    descriptionController.dispose();
  }

  bool get isValid {
    return selectedQuickService != null &&
        typeController.text.trim().isNotEmpty &&
        nameController.text.trim().isNotEmpty &&
        selectedImages.isNotEmpty;
  }
}

class ServiceRequestScreen extends StatefulWidget {
  final String title;
  final Map<String, dynamic>? amcPlanData;

  const ServiceRequestScreen({
    super.key,
    required this.title,
    this.amcPlanData,
  });


  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  static const int _maxImagesPerProduct = 10;
  static const int _maxTotalImages = 20;
  static const int _maxImageBytesPerProduct = 20 * 1024 * 1024;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _preferredDateController =
      TextEditingController();
  final List<ServiceProductFormModel> _products = [ServiceProductFormModel()];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isPickingImage = false;
  bool _isDeviceTypeLoading = false;
  List<String> _deviceTypes = [];

  static const int _addAddressDropdownValue = -1;
  bool _isAddressLoading = false;
  List<AddressModel> _addresses = [];
  int? _selectedAddressId;

  bool get _isAmcRequest => widget.amcPlanData != null;

  int? get _selectedAmcPlanId {
    final rawPlanId = widget.amcPlanData?['planId'];
    if (rawPlanId is int) return rawPlanId;
    return int.tryParse('${rawPlanId ?? ''}');
  }

  String get _selectedAmcPlanName {
    return (widget.amcPlanData?['planName'] ?? 'Selected AMC Plan')
        .toString()
        .trim();
  }

  String? get _selectedAmcType {
    final selectedAmcMode = (widget.amcPlanData?['selectedAmcMode'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (selectedAmcMode == 'offline') {
      return 'onsite';
    }
    if (selectedAmcMode == 'online') {
      return 'remote';
    }

    final supportType = (widget.amcPlanData?['supportType'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    if (supportType == 'offline' ||
        supportType == 'off line' ||
        supportType == 'onsite' ||
        supportType == 'on site') {
      return 'onsite';
    }
    if (supportType == 'online' ||
        supportType == 'on line' ||
        supportType == 'remote') {
      return 'remote';
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fetchAddresses();
      _fetchDeviceTypes();
      if (!_isAmcRequest) {
        context.read<QuickServiceProvider>().fetchRequestServices(
              serviceType: _getServiceTypeFromTitle(),
            );
      }
    });
  }

  Future<void> _fetchDeviceTypes() async {
    setState(() => _isDeviceTypeLoading = true);
    try {
      final roleId = await SecureStorageService.getRoleId();
      final response = await ApiService.instance.getDeviceTypes(roleId: roleId);
      if (!mounted) return;

      if (response.success) {
        setState(() {
          _deviceTypes = response.data ?? [];
        });
      } else {
        _showSnackBar(response.message ?? 'Failed to load device types.');
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Failed to load device types.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeviceTypeLoading = false);
      }
    }
  }

  String _getServiceTypeFromTitle() {
    if (widget.amcPlanData != null) {
      return 'amc';
    }
    final title = widget.title.toLowerCase();
    if (title.contains('installation')) {
      return 'installation';
    } else if (title.contains('repairing')) {
      return 'repairing';
    } else if (title.contains('amc')) {
      return 'amc';
    } else if (title.contains('quick')) {
      return 'quick_service';
    }
    return 'quick_service'; // Default
  }

  Future<void> _pickImage(ServiceProductFormModel product, ImageSource source) async {
    if (_isPickingImage || _isLoading) return;
    if (_totalImagesCount() >= _maxTotalImages) {
      _showSnackBar('Maximum $_maxTotalImages images allowed in one request.');
      return;
    }
    if (product.selectedImages.length >= _maxImagesPerProduct) {
      _showSnackBar('Maximum $_maxImagesPerProduct images allowed per product.');
      return;
    }

    setState(() => _isPickingImage = true);

    try {
      final result = await ImageCaptureService.pickAndCompressImage(
        source: source,
        picker: _picker,
        maxBytes: 4 * 1024 * 1024,
      );

      if (!mounted) return;
      if (result.cancelled) return;

      if (result.shouldOpenSettings) {
        await _showPermissionDialog(
          source == ImageSource.camera ? 'Camera' : 'Photos',
        );
        return;
      }

      if (result.file == null) {
        _showSnackBar(result.message ?? 'Unable to capture/select image.');
        return;
      }

      final File compressedImage = result.file!;
      final int projectedBytes =
          _currentImagesBytes(product) + ImageCaptureService.safeLength(compressedImage);

      if (projectedBytes > _maxImageBytesPerProduct) {
        _showSnackBar(
          'Selected images are too large. Please remove some images or use smaller files.',
        );
        await ImageCaptureService.tryDelete(compressedImage);
        return;
      }

      setState(() {
        product.selectedImages.add(compressedImage);
      });
    } catch (_) {
      if (mounted) {
        _showSnackBar('Failed to add image. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _removeImage(ServiceProductFormModel product, int index) {
    if (index < 0 || index >= product.selectedImages.length) return;
    final File removedImage = product.selectedImages[index];
    setState(() {
      product.selectedImages.removeAt(index);
    });
    unawaited(ImageCaptureService.tryDelete(removedImage));
  }

  void _showImageSourceActionSheet(BuildContext context, ServiceProductFormModel product) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(product, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(product, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, ServiceProductFormModel product) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (!mounted || picked == null) return;
    setState(() {
      product.purchaseDateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    });
  }

  Future<void> _selectPreferredDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _preferredDateController.text =
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
    });
  }

  void _addProduct() {
    setState(() {
      _products.add(ServiceProductFormModel());
    });
  }

  void _removeProduct(int index) {
    if (_products.length > 1) {
      setState(() {
        final removedProduct = _products.removeAt(index);
        _disposeProduct(removedProduct);
      });
    }
  }

  void _disposeProduct(ServiceProductFormModel product) {
    for (final image in product.selectedImages) {
      unawaited(ImageCaptureService.tryDelete(image));
    }
    product.selectedImages.clear();
    product.dispose();
  }

  Future<void> _submitRequest() async {
    bool allValid = true;
    for (int i = 0; i < _products.length; i++) {
      final product = _products[i];
      final isProductValid =
          (_isAmcRequest || product.selectedQuickService != null) &&
          product.typeController.text.trim().isNotEmpty &&
          product.nameController.text.trim().isNotEmpty &&
          product.selectedImages.isNotEmpty;
      if (!isProductValid) {
        allValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete all required fields for Product ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        break;
      }
    }

    if (!allValid || !_formKey.currentState!.validate()) return;

    if (_isAddressLoading) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please wait while we load your addresses.')),
        );
      }
      return;
    }

    if (_addresses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add an address to continue.')),
        );
      }
      await _goToAddressScreen();
      return;
    }

    if (_selectedAddressId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an address.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final customerId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (customerId == null || roleId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User session expired. Please login again.')),
          );
        }
        return;
      }

      final List<Map<String, dynamic>> productData = _products.map((p) {
        return {
          'name': p.nameController.text.trim(),
          'type': p.typeController.text.trim(),
          'model_no': p.modelNoController.text.trim(),
          'mac_address': p.macAddressController.text.trim(),
          'sku': _isAmcRequest
              ? ''
              : p.selectedQuickService?.itemCode ?? '',
          'service_type_id': _isAmcRequest ? null : p.selectedQuickService?.id,
          'hsn': '', // HSN is not in UI, sending empty
          'purchase_date': p.purchaseDateController.text.trim(),
          'brand': p.brandController.text.trim(),
          'description': p.descriptionController.text.trim(),
          'images': p.selectedImages,
        };
      }).toList();

      final response = await ApiService.instance.submitQuickServiceRequest(
        customerId: customerId,
        roleId: roleId,
        serviceType: _getServiceTypeFromTitle(),
        customerAddressId: _selectedAddressId!,
        products: productData,
        amcPlanId: _isAmcRequest ? _selectedAmcPlanId : null,
        amcType: _isAmcRequest ? _selectedAmcType : null,
        preferredDate: _preferredDateController.text.trim(),
      );

      if (mounted) {
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Request submitted successfully')),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const PaymentScreen(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Failed to submit request')),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit request. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _preferredDateController.dispose();
    for (var product in _products) {
      _disposeProduct(product);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  

                    // Add Product Button Aligned Right
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isLoading ? null : _addProduct,
                        icon: const Icon(Icons.add, color: AppColors.primary),
                        label: const Text(
                          'Add Product',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    ..._products.asMap().entries.map((entry) {
                      return _buildProductForm(entry.value, entry.key);
                    }),

                     const SizedBox(height: 16),
                     _buildLabel('Preferred Date'),
                     TextFormField(
                       controller: _preferredDateController,
                       readOnly: true,
                       enabled: !_isLoading,
                       onTap: () => _selectPreferredDate(context),
                       decoration: _inputDecoration('Select preferred date').copyWith(
                         suffixIcon: const Icon(
                           Icons.calendar_today,
                           color: AppColors.primary,
                         ),
                       ),
                     ),
                     const SizedBox(height: 16),
                     _buildLabel('Service Address'),
                     _buildAddressSection(),
                   
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Submit Request',
                                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchAddresses() async {
    if (_isAddressLoading) return;
    if (!mounted) return;
    setState(() {
      _isAddressLoading = true;
    });

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId == null || roleId == null) {
        if (!mounted) return;
        setState(() {
          _addresses = [];
          _selectedAddressId = null;
        });
        return;
      }

      final response = await ApiService.instance.getAddresses(userId: userId, roleId: roleId);

      if (!mounted) return;

      if (response.success && response.data != null) {
        final fetched = response.data!.where((a) => a.id != null).toList();

        int? nextSelectedId = _selectedAddressId;
        final ids = fetched.map((e) => e.id).toSet();

        if (nextSelectedId == null || !ids.contains(nextSelectedId)) {
          final primary = fetched.where((a) => a.isDefault).toList();
          nextSelectedId = (primary.isNotEmpty ? primary.first.id : (fetched.isNotEmpty ? fetched.first.id : null));
        }

        setState(() {
          _addresses = fetched;
          _selectedAddressId = nextSelectedId;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? 'Failed to load addresses')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load addresses. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAddressLoading = false;
        });
      }
    }
  }

  Future<void> _goToAddressScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddressScreen()),
    );
    if (!mounted) return;
    await _fetchAddresses();
  }

  String _formatAddress(AddressModel address) {
    final branch = (address.branchName ?? '').trim();
    final title = branch.isEmpty ? 'Address' : branch;
    final line1 = address.addressLine1.trim();
    final line2 = address.addressLine2.trim();
    final city = address.city.trim();
    final state = address.state.trim();

    final parts = <String>[
      if (line1.isNotEmpty) line1,
      if (line2.isNotEmpty) line2,
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ];

    if (parts.isEmpty) return title;
    return '$title - ${parts.join(', ')}';
  }

  Widget _buildAddressSection() {
    if (_isAddressLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: const [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading addresses...'),
          ],
        ),
      );
    }

    if (_addresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Expanded(child: Text('No address found. Please add one to continue.')),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _goToAddressScreen,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Add Address'),
            ),
          ],
        ),
      );
    }

    final dropdownItems = <DropdownMenuItem<int>>[
      ..._addresses.map((address) {
        return DropdownMenuItem<int>(
          value: address.id,
          child: Text(
            _formatAddress(address),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      }),
      const DropdownMenuItem<int>(
        value: _addAddressDropdownValue,
        child: Text('Add Address'),
      ),
    ];

    return DropdownButtonFormField<int>(
      initialValue: _selectedAddressId,
      isExpanded: true,
      items: dropdownItems,
      onChanged: _isLoading
          ? null
          : (value) async {
              if (value == _addAddressDropdownValue) {
                setState(() => _selectedAddressId = null);
                await _goToAddressScreen();
                return;
              }
              setState(() => _selectedAddressId = value);
            },
      validator: (value) {
        if (_addresses.isEmpty) return null;
        if (value == null) return 'Please select an address';
        if (value == _addAddressDropdownValue) return 'Please select an address';
        return null;
      },
      decoration: _inputDecoration('Select Address'),
    );
  }

  Widget _buildProductForm(ServiceProductFormModel product, int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (index > 0) ...[
          const Divider(height: 40, thickness: 1, color: Colors.grey),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Product ${index + 1}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: _isLoading ? null : () => _removeProduct(index),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        _buildLabel(_isAmcRequest ? 'Selected AMC Plan' : 'Service Type'),
        if (_isAmcRequest)
          _buildAmcPlanCard()
        else
          Consumer<QuickServiceProvider>(
            builder: (context, provider, child) {
              if (provider.isRequestLoading) {
                return const Center(
                    child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(),
                ));
              }

              if (provider.requestServices.isEmpty) {
                return const Center(child: Text('No services available'));
              }

              return DropdownButtonFormField<QuickService>(
                initialValue: provider.requestServices.contains(product.selectedQuickService) ? product.selectedQuickService : null,
                hint: const Text('Select Service Type'),
                isExpanded: true,
                items: provider.requestServices.map((service) {
                  return DropdownMenuItem<QuickService>(
                      value: service,
                      child: Text(
                        service.serviceName ?? 'Unnamed Service',
                        overflow: TextOverflow.ellipsis,
                      ));
                }).toList(),
                onChanged: _isLoading ? null : (value) => setState(() => product.selectedQuickService = value),
                decoration: _inputDecoration('Select Service Type'),
              );
            },
          ),
        const SizedBox(height: 16),

        if (!_isAmcRequest && product.selectedQuickService != null) ...[
          _buildServiceDetailCard(product.selectedQuickService!),
          const SizedBox(height: 16),
        ],

        _buildLabel('Product Name'),
        TextFormField(
          controller: product.nameController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Enter product name'),
        ),
        const SizedBox(height: 16),

        _buildLabel('Product Type'),
        DropdownButtonFormField<String>(
          value: _deviceTypes.contains(product.typeController.text.trim())
              ? product.typeController.text.trim()
              : null,
          isExpanded: true,
          items: _deviceTypes
              .map(
                (type) => DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: (_isLoading || _isDeviceTypeLoading || _deviceTypes.isEmpty)
              ? null
              : (value) {
                  setState(() {
                    product.typeController.text = value ?? '';
                  });
                },
          decoration: _inputDecoration(
            _isDeviceTypeLoading ? 'Loading product types...' : 'Select product type',
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel('Product Brand'),
        TextFormField(
          controller: product.brandController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Enter brand'),
        ),
        const SizedBox(height: 16),

        _buildLabel('Model Number'),
        TextFormField(
          controller: product.modelNoController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Enter model number'),
        ),
        const SizedBox(height: 16),

        _buildLabel('MAC Address'),
        TextFormField(
          controller: product.macAddressController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Enter MAC address (optional)'),
        ),
        const SizedBox(height: 16),

        _buildLabel('Purchase Date'),
        TextFormField(
          controller: product.purchaseDateController,
          readOnly: true,
          enabled: !_isLoading,
          onTap: () => _selectDate(context, product),
          decoration: _inputDecoration('Select Purchase Date').copyWith(
            suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel('Description'),
        TextFormField(
          controller: product.descriptionController,
          enabled: !_isLoading,
          maxLines: 3,
          decoration: _inputDecoration('Enter Description'),
        ),
        const SizedBox(height: 16),

        _buildLabel('Images'),
        InkWell(
          onTap: (_isLoading || _isPickingImage)
              ? null
              : () => _showImageSourceActionSheet(context, product),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.camera_alt, color: AppColors.primary),
                SizedBox(width: 12),
                Text(
                  'Add Photos',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                Spacer(),
              ],
            ),
          ),
        ),
        if (product.selectedImages.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: product.selectedImages.length,
              itemBuilder: (context, imgIndex) {
                return Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 100,
                      height: 100,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey.shade100,
                      ),
                      child: Image.file(
                        product.selectedImages[imgIndex],
                        fit: BoxFit.cover,
                        cacheWidth: 400,
                        cacheHeight: 400,
                        filterQuality: FilterQuality.low,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 12,
                      child: GestureDetector(
                        onTap: _isLoading ? null : () => _removeImage(product, imgIndex),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServiceDetailCard(QuickService service) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 100,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(child: Icon(Icons.miscellaneous_services, size: 40, color: Colors.grey)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.serviceName ?? 'Unnamed Service',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  service.diagnosisList?.join(', ') ?? 'No diagnosis available',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Starts at ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    Text(
                      '₹ ${service.serviceCharge ?? "0.00"}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(with GST)',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ServiceDetailScreen(
                            service: service,
                            imagePath: 'assests/computer.png',
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      'View Details',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmcPlanCard() {
    final supportType = (widget.amcPlanData?['supportType'] ?? '')
        .toString()
        .trim();
    final normalizedSupportType = supportType.toLowerCase();
    final hidePriceForOffline =
        normalizedSupportType == 'offline' ||
        normalizedSupportType == 'off line' ||
        normalizedSupportType == 'onsite' ||
        normalizedSupportType == 'on site';
    final duration = '${widget.amcPlanData?['duration'] ?? '-'}';
    final totalVisits = '${widget.amcPlanData?['totalVisits'] ?? '-'}';
    final totalCost = '${widget.amcPlanData?['totalCost'] ?? '-'}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _selectedAmcPlanName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (supportType.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Support Type: $supportType',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 6),
          Text(
            'Duration: $duration months',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            'Visits: $totalVisits',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          if (!hidePriceForOffline) ...[
            const SizedBox(height: 4),
            Text(
              'Total Cost: Rs $totalCost',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
    );
  }

  int _currentImagesBytes(ServiceProductFormModel product) {
    return product.selectedImages.fold<int>(
      0,
      (sum, file) => sum + ImageCaptureService.safeLength(file),
    );
  }

  int _totalImagesCount() {
    return _products.fold<int>(
      0,
      (sum, product) => sum + product.selectedImages.length,
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showPermissionDialog(String permissionName) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text(
            '$permissionName permission is required to continue. You can enable it from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
