import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';

class EditDocumentScreen extends StatefulWidget {
  final String title;
  final String label;
  final String initialNumber;
  final int? documentId; // ID of the document to edit

  const EditDocumentScreen({
    super.key,
    required this.title,
    required this.label,
    required this.initialNumber,
    this.documentId,
  });

  @override
  State<EditDocumentScreen> createState() => _EditDocumentScreenState();
}

class _EditDocumentScreenState extends State<EditDocumentScreen> {
  late TextEditingController _numberController;
  File? _frontImage;
  File? _backImage;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(text: widget.initialNumber == 'Not provided' ? '' : widget.initialNumber);
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (isFront) {
          _frontImage = File(image.path);
        } else {
          _backImage = File(image.path);
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (_numberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter ${widget.label}')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();
      final token = await SecureStorageService.getAccessToken();

      bool isAadhar = widget.title.toLowerCase().contains('aadhar');
      
      Uri url;
      if (isAadhar) {
        final String id = widget.documentId?.toString() ?? '6'; 
        url = Uri.parse("${ApiConstants.aadharCard}/$id");
      } else {
        // Based on the new Postman screenshot, if updating a PAN card, 
        // the URL should include the ID: /customer-pan-card/{id}
        if (widget.documentId != null) {
          url = Uri.parse("${ApiConstants.panCard}/${widget.documentId}");
        } else {
          url = Uri.parse(ApiConstants.panCard);
        }
      }

      final request = http.MultipartRequest('POST', url);
      
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      });

      request.fields['user_id'] = userId?.toString() ?? '';
      request.fields['role_id'] = roleId?.toString() ?? '';

      if (isAadhar) {
        request.fields['aadhar_number'] = _numberController.text;
        request.fields['_method'] = 'PUT';
        if (_frontImage != null) {
          request.files.add(await http.MultipartFile.fromPath('aadhar_front_path', _frontImage!.path));
        }
        if (_backImage != null) {
          request.files.add(await http.MultipartFile.fromPath('aadhar_back_path', _backImage!.path));
        }
      } else {
        // PAN fields as per the new Postman screenshot
        request.fields['pan_number'] = _numberController.text;
        
        // Add _method: PUT if we are updating an existing record
        if (widget.documentId != null) {
          request.fields['_method'] = 'PUT';
        }
        
        if (_frontImage != null) {
          request.files.add(await http.MultipartFile.fromPath('pan_card_front_path', _frontImage!.path));
        }
        if (_backImage != null) {
          request.files.add(await http.MultipartFile.fromPath('pan_card_back_path', _backImage!.path));
        }
      }

      debugPrint('Saving ${isAadhar ? "Aadhar" : "PAN"} to: $url');
      debugPrint('Fields: ${request.fields}');
      
      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('Save Status: ${response.statusCode}');
      debugPrint('Save Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${isAadhar ? "Aadhar" : "PAN"} updated successfully')),
          );
          Navigator.pop(context, true);
        }
      } else {
        final errorData = jsonDecode(response.body);
        final errorMsg = errorData['message'] ?? 'Failed to update document';
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Error saving document: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
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
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextField(
                      controller: _numberController,
                      decoration: const InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 25),
                    
                    _buildUploadBox(
                      title: "${widget.title} Front Image",
                      image: _frontImage,
                      onTap: () => _pickImage(true),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildUploadBox(
                      title: "${widget.title} Back Image",
                      image: _backImage,
                      onTap: () => _pickImage(false),
                    ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isSaving 
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        "Save",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadBox({required String title, File? image, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200, width: 2),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(image, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.green, width: 1.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.file_upload_outlined, color: Colors.green),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Click to upload",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$title in PNG or JPG (max. 2Mb)",
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
