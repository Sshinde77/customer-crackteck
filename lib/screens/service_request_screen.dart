import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_colors.dart';
import 'payment_screen.dart';

class ServiceRequestScreen extends StatefulWidget {
  final String title;

  const ServiceRequestScreen({super.key, required this.title});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedServiceType;
  String? _selectedDeviceType;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _modelNoController = TextEditingController();
  final TextEditingController _purchaseDateController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  final List<String> _serviceTypes = [
    'Windows PC Display Issues',
    'Mac PC Display Issues',
    'Windows PC Restart Issues',
    'Mac PC Restart Issues',
  ];

  final Map<String, Map<String, String>> _serviceDetails = {
    'Windows PC Display Issues': {
      'description': 'Visit charge of Rs 159 waived in final bill; spare part/repair cost extra.',
      'price': '500',
      'image': 'assests/computer.png',
    },
    'Mac PC Display Issues': {
      'description': 'Visit charge of Rs 159 waived in final bill; spare part/repair cost extra.',
      'price': '800',
      'image': 'assests/laptop.png',
    },
    'Windows PC Restart Issues': {
      'description': 'Visit charge of Rs 159 waived in final bill; spare part/repair cost extra.',
      'price': '400',
      'image': 'assests/computer.png',
    },
    'Mac PC Restart Issues': {
      'description': 'Visit charge of Rs 159 waived in final bill; spare part/repair cost extra.',
      'price': '700',
      'image': 'assests/laptop.png',
    },
  };

  final List<String> _deviceTypes = ['mac', 'linux', 'windows'];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
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
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
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

  void _submitRequest() {
    List<String> missingFields = [];

    if (_selectedServiceType == null) missingFields.add('Service Type');
    if (_selectedDeviceType == null) missingFields.add('Type');
    if (_nameController.text.trim().isEmpty) missingFields.add('Name');
    if (_selectedImage == null) missingFields.add('Image');

    if (missingFields.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select/enter: ${missingFields.join(', ')}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const PaymentScreen(),
        ),
      );
    }
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
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Service Type'),
                DropdownButtonFormField<String>(
                  value: _selectedServiceType,
                  items: _serviceTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedServiceType = value),
                  decoration: _inputDecoration('Select Service Type'),
                ),
                const SizedBox(height: 16),

                if (_selectedServiceType != null) ...[
                  _buildServiceDetailCard(_selectedServiceType!),
                  const SizedBox(height: 16),
                ],

                _buildLabel('Type'),
                DropdownButtonFormField<String>(
                  value: _selectedDeviceType,
                  items: _deviceTypes.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type));
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedDeviceType = value),
                  decoration: _inputDecoration('Select Type'),
                ),
                const SizedBox(height: 16),

                _buildLabel('Name'),
                TextFormField(
                  controller: _nameController,
                  decoration: _inputDecoration('Name'),
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
                ),
                const SizedBox(height: 16),

                _buildLabel('Description'),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: _inputDecoration('Enter Description'),
                ),
                const SizedBox(height: 16),

                _buildLabel('Image Picker'),
                GestureDetector(
                  onTap: () => _showImageSourceActionSheet(context),
                  child: Container(
                    width: double.infinity,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey.shade50,
                    ),
                    child: _selectedImage == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tap to pick image', style: TextStyle(color: Colors.grey)),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(_selectedImage!, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Submit Request',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildServiceDetailCard(String serviceType) {
    final details = _serviceDetails[serviceType]!;
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
            child: Image.asset(
              details['image']!,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceType,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  details['description']!,
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
                      '₹ ${details['price']}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
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
}
