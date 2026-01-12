import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class PersonalDetailScreen extends StatefulWidget {
  const PersonalDetailScreen({super.key});

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  bool _isEditing = false;
  
  final TextEditingController _firstNameController = TextEditingController(text: "Roshan");
  final TextEditingController _lastNameController = TextEditingController(text: "Yadav");
  final TextEditingController _phoneController = TextEditingController(text: "8928339535");
  final TextEditingController _emailController = TextEditingController(text: "support@technofraaaa.in");
  final TextEditingController _dobController = TextEditingController(text: "2000-11-20");
  String _selectedGender = "male";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personal Details', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() {
                if (_isEditing) {
                  // Logic to save data can go here
                }
                _isEditing = !_isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField("First Name", _firstNameController),
            const SizedBox(height: 16),
            _buildTextField("Last Name", _lastNameController),
            const SizedBox(height: 16),
            _buildTextField("Phone Number", _phoneController, keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildTextField("Email Address", _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 16),
            _buildTextField("Date of Birth", _dobController, isDatePicker: true, suffixIcon: Icons.calendar_today),
            const SizedBox(height: 16),
            const Text("Gender", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
            Row(
              children: [
                _buildGenderRadio("Male", "male"),
                const SizedBox(width: 20),
                _buildGenderRadio("Female", "female"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType, bool isDatePicker = false, IconData? suffixIcon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: !_isEditing || isDatePicker,
          onTap: isDatePicker && _isEditing ? () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime(2000),
              firstDate: DateTime(1950),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              setState(() {
                controller.text = pickedDate.toString().split(' ')[0];
              });
            }
          } : null,
          decoration: InputDecoration(
            isDense: true,
            filled: !_isEditing,
            fillColor: !_isEditing ? Colors.grey.shade50 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            suffixIcon: suffixIcon != null ? Icon(suffixIcon, size: 20, color: Colors.grey) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildGenderRadio(String label, String value) {
    return Row(
      children: [
        Radio<String>(
          value: value,
          groupValue: _selectedGender,
          activeColor: AppColors.primary,
          onChanged: _isEditing ? (val) {
            setState(() => _selectedGender = val!);
          } : null,
        ),
        Text(label),
      ],
    );
  }
}
