import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/api_service.dart';
import '../constants/core/secure_storage_service.dart';
import '../models/address_model.dart';
import '../models/api_response.dart';
import '../widgets/app_loading_screen.dart';
import '../widgets/india_country_state_city_picker.dart';

class AddressScreen extends StatefulWidget {
  const AddressScreen({super.key});

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  bool _isAdding = false;
  int? _editingIndex;
  bool _isLoading = true;
  bool _isSaving = false;

  List<AddressModel> _addresses = [];

  // Controllers for editing/adding
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  String? _normalizeCountry(String? raw) {
    if (raw == null) return null;
    final withoutFlags = raw.replaceAll(
      RegExp(r'[\u{1F1E6}-\u{1F1FF}]', unicode: true),
      '',
    );
    return withoutFlags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);
    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId != null && roleId != null) {
        final ApiResponse<List<AddressModel>> response = await ApiService.instance.getAddresses(
          userId: userId,
          roleId: roleId,
        );

        if (response.success && response.data != null) {
          setState(() {
            _addresses = response.data!;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(response.message ?? 'Failed to load addresses')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching addresses: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addNewAddress() async {
    if (_address1Controller.text.isEmpty || _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId != null && roleId != null) {
        final response = await ApiService.instance.storeAddress(
          userId: userId,
          roleId: roleId,
          branchName: _branchNameController.text.trim().isEmpty ? "Home" : _branchNameController.text.trim(),
          address1: _address1Controller.text.trim(),
          address2: _address2Controller.text.trim(),
          city: _selectedCity ?? "",
          state: _selectedState ?? "",
          country: _selectedCountry ?? "",
          pincode: _pincodeController.text.trim(),
          isPrimary: _addresses.isEmpty, // Make primary if it's the first address
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Address saved')),
          );
          if (response.success) {
            _isAdding = false;
            _clearControllers();
            _fetchAddresses(); // Refresh list
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving address: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _updateAddress() async {
    if (_editingIndex == null) return;
    
    final addressId = _addresses[_editingIndex!].id;
    if (addressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cannot update address: Missing ID")),
      );
      return;
    }

    if (_address1Controller.text.isEmpty || _selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill required fields")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();

      if (userId != null && roleId != null) {
        final response = await ApiService.instance.updateAddress(
          addressId: addressId,
          userId: userId,
          roleId: roleId,
          branchName: _branchNameController.text.trim(),
          address1: _address1Controller.text.trim(),
          address2: _address2Controller.text.trim(),
          city: _selectedCity ?? "",
          state: _selectedState ?? "",
          country: _selectedCountry ?? "",
          pincode: _pincodeController.text.trim(),
          isPrimary: _addresses[_editingIndex!].isDefault,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.message ?? 'Address updated')),
          );
          if (response.success) {
            setState(() {
              _editingIndex = null;
              _clearControllers();
            });
            _fetchAddresses(); // Refresh list
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating address: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _clearControllers() {
    _branchNameController.clear();
    _address1Controller.clear();
    _address2Controller.clear();
    _pincodeController.clear();
    _selectedCountry = 'India';
    _selectedState = null;
    _selectedCity = null;
  }

  void _prepareEdit(int index) {
    final address = _addresses[index];
    _branchNameController.text = address.branchName ?? '';
    _address1Controller.text = address.addressLine1;
    _address2Controller.text = address.addressLine2;
    _pincodeController.text = address.pincode;
    _selectedCountry = _normalizeCountry(address.country);
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
      body: _isLoading
          ? const AppLoadingScreen(message: 'Loading your saved addresses.')
          : RefreshIndicator(
              onRefresh: _fetchAddresses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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

                    if (_addresses.isEmpty && !_isAdding && _editingIndex == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.only(top: 50),
                          child: Text("No addresses found. Add one now!"),
                        ),
                      ),

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
                address.isDefault ? "Primary Address" : (address.branchName ?? "Address ${index + 1}"),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              if (!address.isDefault)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () {
                    // TODO: Integrate delete API
                  },
                ),
            ],
          ),
          const Divider(height: 20),
          
          _buildStaticRow(Icons.location_on_outlined, "Address Line 1", address.addressLine1),
          _buildStaticRow(Icons.location_city_outlined, "Address Line 2", address.addressLine2),
          _buildStaticRow(Icons.map_outlined, "City", address.city),
          _buildStaticRow(Icons.landscape_outlined, "State", address.state),
          _buildStaticRow(Icons.public_outlined, "Country", _normalizeCountry(address.country) ?? address.country),
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
          _buildInput("Branch Name (e.g. Home, Office)", _branchNameController),
          _buildInput("Address Line 1", _address1Controller),
          _buildInput("Address Line 2", _address2Controller),
          
          const Text("Select Location", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black54)),
          IndiaCountryStateCityPicker(
            key: ValueKey<String>('location_${_editingIndex ?? 'new'}_${_selectedCountry ?? ''}_${_selectedState ?? ''}_${_selectedCity ?? ''}'),
            initialCountry: _selectedCountry ?? 'India',
            initialState: _selectedState,
            initialCity: _selectedCity,
            onCountryChanged: (value) => setState(() => _selectedCountry = _normalizeCountry(value)),
            onStateChanged: (value) => setState(() => _selectedState = value.trim().isEmpty ? null : value),
            onCityChanged: (value) => setState(() => _selectedCity = value.trim().isEmpty ? null : value),
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
                  onPressed: _isSaving ? null : () {
                    if (_editingIndex != null) {
                      _updateAddress();
                    } else {
                      _addNewAddress();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_editingIndex != null ? "Update" : "Add Now", style: const TextStyle(color: Colors.white)),
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
