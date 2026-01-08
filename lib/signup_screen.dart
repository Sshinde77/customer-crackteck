import 'package:flutter/material.dart';
import 'package:country_state_city_picker/country_state_city_picker.dart';
import 'login.dart';
import 'services/api_service.dart';
import 'models/api_response.dart';
import 'otp_screen.dart';
import 'routes/route_generator.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController firstNameCtrl = TextEditingController();
  final TextEditingController lastNameCtrl = TextEditingController();
  final TextEditingController phoneCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController addressLine1Ctrl = TextEditingController();
  final TextEditingController addressLine2Ctrl = TextEditingController();
  final TextEditingController pincodeCtrl = TextEditingController();
  final TextEditingController companyCtrl = TextEditingController();
  final TextEditingController gstCtrl = TextEditingController();
  final TextEditingController customerTypeCtrl =
  TextEditingController(text: "Customer App");

  String? selectedGender;
  String? selectedCountry;
  String? selectedState;
  String? selectedCity;

  bool agreeTerms = false;
  bool isLoading = false;

  static const Color green = Color(0xFF1F8B00);
  static const List<String> genders = ["Male", "Female", "Other"];

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressLine1Ctrl.dispose();
    addressLine2Ctrl.dispose();
    pincodeCtrl.dispose();
    companyCtrl.dispose();
    gstCtrl.dispose();
    customerTypeCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (!agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept terms and conditions")),
      );
      return;
    }

    if (selectedCountry == null || selectedState == null || selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select country, state and city")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final Map<String, String> fields = {
        'first_name': firstNameCtrl.text.trim(),
        'last_name': lastNameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim(),
        'email': emailCtrl.text.trim(),
        'gender': (selectedGender ?? '').toLowerCase(),
        'customer_type': customerTypeCtrl.text.trim(),
        'address': addressLine1Ctrl.text.trim(),
        'address2': addressLine2Ctrl.text.trim(),
        'city': selectedCity ?? '',
        'state': selectedState ?? '',
        'country': selectedCountry ?? '',
        'pincode': pincodeCtrl.text.trim(),
        'company_name': companyCtrl.text.trim(),
        'gst_no': gstCtrl.text.trim(),
        'role_id': '4', // Default for customer
      };

      final ApiResponse response = await ApiService.instance.signup(fields: fields);

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message ?? "Signup successful!")),
        );
        // Navigate to OTP screen after successful signup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoginScreen(
              roleId: 4,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? "Signup failed. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Hi, Welcome!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  "Please sign up to continue",
                  style: TextStyle(fontSize: 14, color: Colors.black54),
                ),
                const SizedBox(height: 24),

                _inputField(
                  hint: "First Name",
                  controller: firstNameCtrl,
                  validator: (v) =>
                  v!.isEmpty ? "Please enter first name" : null,
                ),

                _inputField(
                  hint: "Last Name",
                  controller: lastNameCtrl,
                  validator: (v) =>
                  v!.isEmpty ? "Please enter last name" : null,
                ),

                _inputField(
                  hint: "Number",
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  prefix: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text("+91"),
                  ),
                  validator: (v) =>
                  v!.length != 10 ? "Enter valid 10-digit number" : null,
                ),

                _inputField(
                  hint: "Email",
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Please enter email";
                    }
                    final emailRegex = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(v)) {
                      return "Enter valid email";
                    }
                    return null;
                  },
                ),

                _dropdownField(
                  hint: "Gender",
                  value: selectedGender,
                  items: genders,
                  onChanged: (val) => setState(() => selectedGender = val),
                  validator: (v) =>
                  v == null ? "Please select gender" : null,
                ),

                _inputField(
                  hint: "Customer Type",
                  controller: customerTypeCtrl,
                  readOnly: true,
                ),

                _inputField(
                  hint: "Address line 1",
                  controller: addressLine1Ctrl,
                  validator: (v) =>
                  v!.isEmpty ? "Please enter address line 1" : null,
                ),

                _inputField(
                  hint: "Address line 2",
                  controller: addressLine2Ctrl,
                ),

                /// 🌍 Country / State / City Picker
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: SelectState(
                      style: const TextStyle(fontSize: 14),
                      onCountryChanged: (value) {
                        setState(() {
                          selectedCountry = value;
                          selectedState = null;
                          selectedCity = null;
                        });
                      },
                      onStateChanged: (value) {
                        setState(() {
                          selectedState = value;
                          selectedCity = null;
                        });
                      },
                      onCityChanged: (value) {
                        setState(() {
                          selectedCity = value;
                        });
                      },
                    ),
                  ),
                ),

                  _inputField(
                  hint: "Pin code",
                  controller: pincodeCtrl,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "Please enter pin code";
                    }
                    if (v.length != 6) {
                      return "Enter valid 6-digit pin code";
                    }
                    return null;
                  },
                ),

                _inputField(
                  hint: "Company Name (Optional)",
                  controller: companyCtrl,
                ),

                _inputField(
                  hint: "GST No. (Optional)",
                  controller: gstCtrl,
                ),

                Row(
                  children: [
                    Checkbox(
                      value: agreeTerms,
                      activeColor: green,
                      onChanged: (v) =>
                          setState(() => agreeTerms = v!),
                    ),
                    const Expanded(
                      child: Text(
                        "I agree to the terms and conditions",
                        style:
                        TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: isLoading ? null : _handleSignUp,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Sign Up",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      "Already have an account? Login",
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _inputField({
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    Widget? prefix,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: prefix,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black26),
          ),
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String hint,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: value,
        validator: validator,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border:
          OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.black12),
          ),
        ),
        items: items
            .map((e) =>
            DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
      ),
    );
  }
}
