import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import '../constants/app_colors.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  bool _isEditing = false;

  final TextEditingController _companyNameController = TextEditingController(text: "Technofra");
  final TextEditingController _gstNumberController = TextEditingController(text: "27AAACT1234A1Z1");
  final TextEditingController _address1Controller = TextEditingController(text: "456 MG Road");
  final TextEditingController _address2Controller = TextEditingController(text: "Apt 45C");
  final TextEditingController _pincodeController = TextEditingController(text: "411001");
  
  String _city = "Pune";
  String _state = "Maharashtra";
  String _country = "India";

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
        title: const Text('Company Details', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white),
            onPressed: () {
              setState(() {
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
            _buildTextField("Company Name", _companyNameController),
            const SizedBox(height: 16),
            _buildTextField("Company GST Number", _gstNumberController),
            const SizedBox(height: 16),
            _buildTextField("Address Line 1", _address1Controller),
            const SizedBox(height: 16),
            _buildTextField("Address Line 2", _address2Controller),
            const SizedBox(height: 16),
            
            if (_isEditing) ...[
              const Text("Country, State, City", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
              const SizedBox(height: 8),
              SelectState(
                onCountryChanged: (value) => setState(() => _country = value),
                onStateChanged: (value) => setState(() => _state = value),
                onCityChanged: (value) => setState(() => _city = value),
              ),
            ] else ...[
               _buildStaticRow("Country", _country),
               _buildStaticRow("State", _state),
               _buildStaticRow("City", _city),
            ],

            const SizedBox(height: 16),
            _buildTextField("Pincode", _pincodeController, keyboardType: TextInputType.number),
          ],
        ),
      ),
    );
  }

  Widget _buildStaticRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: !_isEditing,
          decoration: InputDecoration(
            isDense: true,
            filled: !_isEditing,
            fillColor: !_isEditing ? Colors.grey.shade50 : Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
