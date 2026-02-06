import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/address_model.dart';
import '../models/quick_service_model.dart';
import '../services/api_service.dart';
import 'address_screen.dart';
import 'payment_screen.dart';
import 'service_detail_screen.dart';

class ProductFormModel {
  String? selectedPcType;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController modelNoController = TextEditingController();
  final TextEditingController purchaseDateController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final List<File> selectedImages = [];

  void dispose() {
    nameController.dispose();
    modelNoController.dispose();
    purchaseDateController.dispose();
    brandController.dispose();
    descriptionController.dispose();
  }

  bool get isValid {
    return selectedPcType != null &&
        nameController.text.trim().isNotEmpty &&
        brandController.text.trim().isNotEmpty &&
        descriptionController.text.trim().isNotEmpty;
  }
}

class QuickServiceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;

  const QuickServiceDetailsScreen({super.key, required this.serviceData});

  @override
  State<QuickServiceDetailsScreen> createState() => _QuickServiceDetailsScreenState();
}

class _QuickServiceDetailsScreenState extends State<QuickServiceDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<ProductFormModel> _products = [ProductFormModel()];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  static const int _addAddressDropdownValue = -1;
  bool _isAddressLoading = false;
  List<AddressModel> _addresses = [];
  int? _selectedAddressId;

  bool get _isFormValid {
    return _products.every((product) => product.isValid);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAddresses();
    });
  }

  Future<void> _pickImage(ProductFormModel product) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          product.selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, ProductFormModel product) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        // Formatting to YYYY-MM-DD as seen in Postman screenshot
        product.purchaseDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _removeImage(ProductFormModel product, int index) {
    setState(() {
      product.selectedImages.removeAt(index);
    });
  }

  void _addProduct() {
    setState(() {
      _products.add(ProductFormModel());
    });
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

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

      final String serviceType =
          (widget.serviceData['service_type'] ?? 'quick_service').toString();
      final int? amcPlanId = widget.serviceData['amc_plan_id'] is int
          ? widget.serviceData['amc_plan_id'] as int
          : int.tryParse('${widget.serviceData['amc_plan_id'] ?? ''}');
      final QuickService? service =
          widget.serviceData['serviceData'] as QuickService?;
      final dynamic rawServiceTypeId = service?.id ?? widget.serviceData['id'];
      final int? serviceTypeId = rawServiceTypeId is int
          ? rawServiceTypeId
          : int.tryParse('${rawServiceTypeId ?? ''}');

      final List<Map<String, dynamic>> productData = _products.map((p) {
        return {
          'name': p.nameController.text.trim(),
          'type': p.selectedPcType ?? '',
          'model_no': p.modelNoController.text.trim(),
          if (serviceTypeId != null) 'service_type_id': serviceTypeId,
          'purchase_date': p.purchaseDateController.text.trim(),
          'brand': p.brandController.text.trim(),
          'description': p.descriptionController.text.trim(),
          'images': p.selectedImages,
        };
      }).toList();

      final response = await ApiService.instance.submitQuickServiceRequest(
        customerId: customerId,
        roleId: roleId,
        serviceType: serviceType,
        products: productData,
        amcPlanId: serviceType == 'amc' ? amcPlanId : null,
        customerAddressId: _selectedAddressId!,
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var product in _products) {
      product.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final QuickService? service = widget.serviceData['serviceData'] as QuickService?;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Quick Service',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
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
                    // Service Summary Card
                    Container(
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
                            child: Image.asset(
                              widget.serviceData['image'] ?? 'assests/computer.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  service?.serviceName ?? widget.serviceData['title'] ?? 'Windows PC Display Issues',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service?.diagnosisList?.join(', ') ?? 'Visit charge of Rs 159 waived in final bill; spare part/repair cost extra.',
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text(
                                      'Starts at ',
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                    ),
                                    Text(
                                      '₹ ${service?.serviceCharge ?? "500"}',
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
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
                                            imagePath: widget.serviceData['image'] ?? 'assests/computer.png',
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
                    ),

                    const SizedBox(height: 16),

                

                    // Add Product Button Aligned Right (Below the service summary card)
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
                      int index = entry.key;
                      ProductFormModel product = entry.value;
                      return _buildProductForm(product, index);
                    }),

                    const SizedBox(height: 32),
                        _buildLabel('Service Address'),
                    _buildAddressSection(),
                    const SizedBox(height: 16),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isFormValid && !_isLoading) ? _submitRequest : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (_isFormValid && !_isLoading) ? AppColors.primary : Colors.grey.shade400,
                          disabledBackgroundColor: Colors.grey.shade400,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Submit request',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildProductForm(ProductFormModel product, int index) {
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
                onPressed: () {
                  setState(() {
                    _products.removeAt(index);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
        // PC Type
        _buildLabel('PC Type'),
        DropdownButtonFormField<String>(
          value: product.selectedPcType,
          decoration: _inputDecoration('Select'),
          items: ['Windows', 'Mac', 'Linux'].map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: _isLoading
              ? null
              : (val) {
                  setState(() {
                    product.selectedPcType = val;
                  });
                },
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.green),
        ),
        const SizedBox(height: 16),

        _buildLabel('Name'),
        TextFormField(
          controller: product.nameController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Name'),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),

        _buildLabel('Model No'),
        TextFormField(
          controller: product.modelNoController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Enter Model No'),
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

        _buildLabel('Brand'),
        TextFormField(
          controller: product.brandController,
          enabled: !_isLoading,
          decoration: _inputDecoration('Enter Brand'),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),

        _buildLabel('Description'),
        TextFormField(
          controller: product.descriptionController,
          enabled: !_isLoading,
          maxLines: 3,
          decoration: _inputDecoration('Enter Description'),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Add Photos
        InkWell(
          onTap: _isLoading ? null : () => _pickImage(product),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.camera_alt, color: Colors.green),
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

        // Image Preview List
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
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: FileImage(product.selectedImages[imgIndex]),
                          fit: BoxFit.cover,
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

  Future<void> _fetchAddresses() async {
    if (_isAddressLoading) return;
    setState(() {
      _isAddressLoading = true;
    });

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId == null || roleId == null) {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load addresses: $e')),
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
      value: _selectedAddressId,
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54),
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
}
