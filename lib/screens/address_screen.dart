import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import '../constants/app_colors.dart';

class AddressModel {
  String addressLine1;
  String addressLine2;
  String city;
  String state;
  String country;
  String pincode;
  bool isDefault;

  AddressModel({
    required this.addressLine1,
    required this.addressLine2,
    required this.city,
    required this.state,
    required this.country,
    required this.pincode,
    this.isDefault = false,
  });
}

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool _isAdding = false;
  int? _editingIndex;

  final List<AddressModel> _addresses = [
    AddressModel(
      addressLine1: "456 MG Road",
      addressLine2: "Apt 45C",
      city: "Pune",
      state: "Maharashtra",
      country: "India",
      pincode: "411001",
      isDefault: true,
    ),
  ];

  // Controllers for editing/adding
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  void _clearControllers() {
    _address1Controller.clear();
    _address2Controller.clear();
    _pincodeController.clear();
    _selectedCountry = null;
    _selectedState = null;
    _selectedCity = null;
  }

  void _prepareEdit(int index) {
    final address = _addresses[index];
    _address1Controller.text = address.addressLine1;
    _address2Controller.text = address.addressLine2;
    _pincodeController.text = address.pincode;
    _selectedCountry = address.country;
    _selectedState = address.state;
    _selectedCity = address.city;
    setState(() {
      _editingIndex = index;
      _isAdding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Addresses', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Add Address Button at the Top Right
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    if (_isAdding) {
                      _isAdding = false;
                    } else {
                      _isAdding = true;
                      _editingIndex = null;
                      _clearControllers();
                    }
                  });
                },
                icon: Icon(_isAdding ? Icons.close : Icons.add, color: AppColors.primary),
                label: Text(
                  _isAdding ? "Cancel" : "Add Address",
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            if (_isAdding || _editingIndex != null) _buildAddressForm(),

            const SizedBox(height: 16),

            // List of addresses
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _addresses.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                return _buildAddressCard(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(int index) {
    final address = _addresses[index];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                address.isDefault ? "Default Address" : "Address ${index + 1}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (!address.isDefault)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () {
                    setState(() {
                      _addresses.removeAt(index);
                    });
                  },
                ),
            ],
          ),
          const Divider(height: 20),
          
          _buildStaticRow(Icons.location_on_outlined, "Address Line 1", address.addressLine1),
          _buildStaticRow(Icons.location_city_outlined, "Address Line 2", address.addressLine2),
          _buildStaticRow(Icons.map_outlined, "City", address.city),
          _buildStaticRow(Icons.landscape_outlined, "State", address.state),
          _buildStaticRow(Icons.public_outlined, "Country", address.country),
          _buildStaticRow(Icons.pin_outlined, "Pincode", address.pincode),

          const SizedBox(height: 10),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _prepareEdit(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade100,
                foregroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.edit_location_alt_outlined),
              label: const Text("Edit Address"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressForm() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingIndex != null ? "Edit Address" : "Add New Address",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
          const SizedBox(height: 20),
          _buildInput("Address Line 1", _address1Controller),
          _buildInput("Address Line 2", _address2Controller),
          
          const Text("Select Location", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
          SelectState(
            onCountryChanged: (value) => setState(() => _selectedCountry = value),
            onStateChanged: (value) => setState(() => _selectedState = value),
            onCityChanged: (value) => setState(() => _selectedCity = value),
          ),
          
          const SizedBox(height: 15),
          _buildInput("Pincode", _pincodeController, keyboardType: TextInputType.number),
          
          const SizedBox(height: 10),
          Row(
            children: [
              if (_editingIndex != null)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _editingIndex = null;
                          _clearControllers();
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Cancel"),
                    ),
                  ),
                ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_address1Controller.text.isEmpty || _selectedCountry == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please fill required fields")),
                      );
                      return;
                    }

                    setState(() {
                      if (_editingIndex != null) {
                        // Update existing
                        _addresses[_editingIndex!] = AddressModel(
                          addressLine1: _address1Controller.text,
                          addressLine2: _address2Controller.text,
                          city: _selectedCity ?? "",
                          state: _selectedState ?? "",
                          country: _selectedCountry ?? "",
                          pincode: _pincodeController.text,
                          isDefault: _addresses[_editingIndex!].isDefault,
                        );
                        _editingIndex = null;
                      } else {
                        // Add new
                        _addresses.add(AddressModel(
                          addressLine1: _address1Controller.text,
                          addressLine2: _address2Controller.text,
                          city: _selectedCity ?? "",
                          state: _selectedState ?? "",
                          country: _selectedCountry ?? "",
                          pincode: _pincodeController.text,
                        ));
                        _isAdding = false;
                      }
                      _clearControllers();
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_editingIndex != null ? "Update" : "Add Now", style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStaticRow(IconData icon, String label, String value) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value.isNotEmpty ? value : "N/A", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
      ),
    );
  }
}
