import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../provider/company_provider.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {
  bool _isEditing = false;
  String? _gstErrorText;

  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _gstNumberController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  
  String _city = "";
  String _state = "";
  String _country = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().fetchCompanyDetails().then((_) {
        final details = context.read<CompanyProvider>().companyDetails;
        if (details != null) {
          _updateControllers(details);
        }
      });
    });
  }

  void _updateControllers(dynamic details) {
    _companyNameController.text = details.companyName ?? "";
    _gstNumberController.text = (details.gstNo ?? "").toString().toUpperCase();
    _address1Controller.text = details.compAddress1 ?? "";
    _address2Controller.text = details.compAddress2 ?? "";
    _pincodeController.text = details.compPincode ?? "";
    _city = details.compCity ?? "";
    _state = details.compState ?? "";
    _country = details.compCountry ?? "";
  }

  Future<void> _handleSave() async {
    final gstValidationMessage = _validateGstNumber(
      _gstNumberController.text.trim(),
    );
    if (gstValidationMessage != null) {
      setState(() => _gstErrorText = gstValidationMessage);
      return;
    }

    final response = await context.read<CompanyProvider>().saveCompanyDetails(
      companyName: _companyNameController.text,
      address1: _address1Controller.text,
      address2: _address2Controller.text,
      city: _city,
      state: _state,
      country: _country,
      pincode: _pincodeController.text,
      gstNo: _normalizedGstNumber,
    );

    if (response.success) {
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.message ?? 'Company details updated successfully',
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        final apiMessage = response.message?.trim();
        if (apiMessage != null && _looksLikeGstError(apiMessage)) {
          setState(() => _gstErrorText = apiMessage);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              apiMessage?.isNotEmpty == true
                  ? apiMessage!
                  : 'Failed to update company details',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _gstNumberController.dispose();
    _address1Controller.dispose();
    _address2Controller.dispose();
    _pincodeController.dispose();
    super.dispose();
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
        title: const Text('Company Details', style: TextStyle(color: Colors.white)),
        actions: [
          Consumer<CompanyProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    ),
                  ),
                );
              }
              return IconButton(
                icon: Icon(_isEditing ? Icons.check : Icons.edit, color: Colors.white),
                onPressed: () {
                  if (_isEditing) {
                    _handleSave();
                  } else {
                    setState(() {
                      _isEditing = true;
                    });
                  }
                },
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<CompanyProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: provider.fetchCompanyDetails,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     _buildTextField("Company Name", _companyNameController),
                     const SizedBox(height: 16),
                     _buildTextField(
                       "Company GST Number",
                       _gstNumberController,
                       keyboardType: TextInputType.text,
                       errorText: _gstErrorText,
                       helperText:
                           'GSTIN must be 15 characters, for example 22AAAAA0000A1Z5.',
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[a-zA-Z0-9]'),
                          ),
                         LengthLimitingTextInputFormatter(15),
                         UpperCaseTextFormatter(),
                       ],
                       onChanged: (_) {
                         if (_gstErrorText != null) {
                           setState(() => _gstErrorText = null);
                         }
                       },
                     ),
                     const SizedBox(height: 16),
                    _buildTextField("Address Line 1", _address1Controller),
                    const SizedBox(height: 16),
                    _buildTextField("Address Line 2", _address2Controller),
                    const SizedBox(height: 16),
                    
                    if (_isEditing) ...[
                      const Text("Country, State, City", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
                      const SizedBox(height: 8),
                      SelectState(
                        onCountryChanged: (value) => setState(() => _country = value.replaceAll(' ', '')),
                        onStateChanged: (value) => setState(() => _state = value.replaceAll(' ', '')),
                        onCityChanged: (value) => setState(() => _city = value.replaceAll(' ', '')),
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
          },
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
          child: Text(value.isEmpty ? "Not Available" : value, style: const TextStyle(fontSize: 15, color: Colors.black87)),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
    String? errorText,
    String? helperText,
    List<TextInputFormatter>? inputFormatters,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          readOnly: !_isEditing,
          decoration: InputDecoration(
            isDense: true,
            filled: !_isEditing,
            fillColor: !_isEditing ? Colors.grey.shade50 : Colors.white,
            errorText: errorText,
            helperText: helperText,
            helperMaxLines: 2,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  String get _normalizedGstNumber => _gstNumberController.text.trim().toUpperCase();

  String? _validateGstNumber(String value) {
    if (value.isEmpty) {
      return 'Please enter GST number';
    }

    final normalized = value.toUpperCase();
    if (normalized.length != 15) {
      return 'GSTIN must be exactly 15 characters.';
    }

    final gstPattern = RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[A-Z0-9]{1}Z[A-Z0-9]{1}$',
    );
    if (!gstPattern.hasMatch(normalized)) {
      return 'Enter a valid GSTIN, for example 22AAAAA0000A1Z5.';
    }

    return null;
  }

  bool _looksLikeGstError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('gst') ||
        lower.contains('gstin') ||
        lower.contains('15 characters') ||
        lower.contains('15 digit') ||
        lower.contains('15-digit') ||
        lower.contains('invalid');
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  const UpperCaseTextFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
