import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import '../models/quick_service_model.dart';
import 'payment_screen.dart';

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

  bool get _isFormValid {
    return _products.every((product) => product.isValid);
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
        product.purchaseDateController.text = "${picked.day}/${picked.month}/${picked.year}";
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
        child: SingleChildScrollView(
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Add Product Button Aligned Right (Below the service summary card)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _addProduct,
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

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isFormValid
                        ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentScreen(),
                              ),
                            );
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isFormValid ? AppColors.primary : Colors.grey.shade400,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Submit request',
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          onChanged: (val) {
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
          decoration: _inputDecoration('Name'),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),

        _buildLabel('Model No'),
        TextFormField(
          controller: product.modelNoController,
          decoration: _inputDecoration('Enter Model No'),
        ),
        const SizedBox(height: 16),

        _buildLabel('Purchase Date'),
        TextFormField(
          controller: product.purchaseDateController,
          readOnly: true,
          onTap: () => _selectDate(context, product),
          decoration: _inputDecoration('Select Purchase Date').copyWith(
            suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
          ),
        ),
        const SizedBox(height: 16),

        _buildLabel('Brand'),
        TextFormField(
          controller: product.brandController,
          decoration: _inputDecoration('Enter Brand'),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),

        _buildLabel('Description'),
        TextFormField(
          controller: product.descriptionController,
          maxLines: 3,
          decoration: _inputDecoration('Enter Description'),
          onChanged: (val) => setState(() {}),
        ),
        const SizedBox(height: 16),

        // Add Photos
        InkWell(
          onTap: () => _pickImage(product),
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
                        onTap: () => _removeImage(product, imgIndex),
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
