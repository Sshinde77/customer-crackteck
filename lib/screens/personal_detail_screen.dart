import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/user_model.dart';
import '../models/api_response.dart';

class PersonalDetailScreen extends StatefulWidget {
  const PersonalDetailScreen({super.key});

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  bool _isEditing = false;
  bool _isLoading = true;
  bool _isSaving = false;
  
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  String _selectedGender = "male";

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId != null && roleId != null) {
        final ApiResponse<UserModel> response = await ApiService.instance.getProfile(
          userId: userId,
          roleId: roleId,
        );

        if (response.success && response.data != null) {
          final user = response.data!;
          _firstNameController.text = user.firstName ?? '';
          _lastNameController.text = user.lastName ?? '';
          _phoneController.text = user.phone ?? '';
          _emailController.text = user.email ?? '';
          _dobController.text = user.dob ?? '';
          _selectedGender = (user.gender?.toLowerCase() == 'female') ? 'female' : 'male';
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message ?? 'Failed to load profile')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfileData() async {
    setState(() => _isSaving = true);
    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId != null && roleId != null) {
        final response = await ApiService.instance.updateProfile(
          userId: userId,
          roleId: roleId,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          dob: _dobController.text.trim(),
          gender: _selectedGender,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? (response.success ? 'Profile updated successfully' : 'Failed to update profile'))),
          );
          if (response.success) {
            setState(() {
              _isEditing = false;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An unexpected error occurred')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

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
          if (!_isLoading)
            _isSaving 
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                )
              : IconButton(
                  icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white),
                  onPressed: () {
                    if (_isEditing) {
                      _updateProfileData();
                    } else {
                      setState(() {
                        _isEditing = true;
                      });
                    }
                  },
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField("First Name", _firstNameController),
                  const SizedBox(height: 16),
                  _buildTextField("Last Name", _lastNameController),
                  const SizedBox(height: 16),
                  _buildTextField("Phone Number", _phoneController, keyboardType: TextInputType.phone, isReadOnlyAlways: true),
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

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType, bool isDatePicker = false, IconData? suffixIcon, bool isReadOnlyAlways = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: isReadOnlyAlways || !_isEditing || isDatePicker,
          onTap: isDatePicker && _isEditing ? () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: controller.text.isNotEmpty ? (DateTime.tryParse(controller.text) ?? DateTime(2000)) : DateTime(2000),
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
            filled: isReadOnlyAlways || !_isEditing,
            fillColor: (isReadOnlyAlways || !_isEditing) ? Colors.grey.shade50 : Colors.white,
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
