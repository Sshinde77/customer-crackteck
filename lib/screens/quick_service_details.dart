import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import 'payment_screen.dart';

class QuickServiceDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> serviceData;

  const QuickServiceDetailsScreen({super.key, required this.serviceData});

  @override
  State<QuickServiceDetailsScreen> createState() => _QuickServiceDetailsScreenState();
}

class _QuickServiceDetailsScreenState extends State<QuickServiceDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPcType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modelNoController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  final List<File> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  bool get _isFormValid {
    return _selectedPcType != null &&
        _nameController.text.trim().isNotEmpty &&
        _brandController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _purchaseDateController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelNoController.dispose();
    _purchaseDateController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
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
                              widget.serviceData['title'] ?? 'Windows PC Display Issues',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Visit charge of Rs 159 waived in final bill; spare part/repair cost extra.',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Starts at ',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                ),
                                const Text(
                                  '₹ 500',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
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
                const SizedBox(height: 24),

                // PC Type
                _buildLabel('PC Type'),
                DropdownButtonFormField<String>(
                  value: _selectedPcType,
                  decoration: _inputDecoration('Select'),
                  items: ['Windows', 'Mac', 'Linux'].map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedPcType = val;
                    });
                  },
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.green),
                ),
                const SizedBox(height: 16),

                _buildLabel('Name'),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Name'),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),

                _buildLabel('Model No'),
                TextFormField(
                  controller: _modelNoController,
                  decoration: _inputDecoration('Enter Model No'),
                ),
                const SizedBox(height: 16),

                _buildLabel('Purchase Date'),
                TextFormField(
                  controller: _purchaseDateController,
                  readOnly: true,
                  onTap: () => _selectDate(context),
                  decoration: _inputDecoration('Select Purchase Date').copyWith(
                    suffixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),

                _buildLabel('Brand'),
                TextFormField(
                  controller: _brandController,
                  decoration: _inputDecoration('Enter Brand'),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),

                _buildLabel('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration('Enter Description'),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 16),

                // Add Photos
                InkWell(
                  onTap: _pickImage,
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
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: FileImage(_selectedImages[index]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 12,
                              child: GestureDetector(
                                onTap: () => _removeImage(index),
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
        borderSide: const BorderSide(color: Colors.green),
      ),
    );
  }
}
