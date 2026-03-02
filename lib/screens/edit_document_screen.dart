import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_colors.dart';
import '../constants/core/secure_storage_service.dart';
import '../services/api_service.dart';
import '../services/image_capture_service.dart';

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
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    _numberController = TextEditingController(
      text: widget.initialNumber.trim() == 'Not provided' ? '' : widget.initialNumber,
    );
  }

  @override
  void dispose() {
    unawaited(ImageCaptureService.tryDelete(_frontImage));
    unawaited(ImageCaptureService.tryDelete(_backImage));
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isFront) async {
    if (_isSaving || _isPickingImage) return;
    setState(() => _isPickingImage = true);

    try {
      final result = await ImageCaptureService.pickAndCompressImage(
        source: ImageSource.gallery,
        picker: _picker,
        maxBytes: 2 * 1024 * 1024,
      );

      if (!mounted) return;
      if (result.cancelled) return;

      if (result.shouldOpenSettings) {
        await _showPermissionDialog('Photos');
        return;
      }

      if (result.file == null) {
        _showSnackBar(result.message ?? 'Unable to select image.');
        return;
      }

      final File? previousImage = isFront ? _frontImage : _backImage;
      setState(() {
        if (isFront) {
          _frontImage = result.file;
        } else {
          _backImage = result.file;
        }
      });
      if (previousImage != null) {
        await ImageCaptureService.tryDelete(previousImage);
      }
    } catch (_) {
      if (mounted) {
        _showSnackBar('Failed to select image. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (_numberController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter ${widget.label}')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = await SecureStorageService.getUserId();
      final roleId = await SecureStorageService.getRoleId();
      if (userId == null || roleId == null) {
        throw Exception('Missing user/role. Please login again.');
      }

      bool isAadhar = widget.title.toLowerCase().contains('aadhar');

      final api = ApiService.instance;
      final result = isAadhar
          ? await api.uploadAadhar(
              userId: userId,
              roleId: roleId,
              aadharNumber: _numberController.text.trim(),
              frontImage: _frontImage,
              backImage: _backImage,
              documentId: widget.documentId,
            )
          : await api.uploadPan(
              userId: userId,
              roleId: roleId,
              panNumber: _numberController.text.trim(),
              frontImage: _frontImage,
              backImage: _backImage,
              documentId: widget.documentId,
            );

      if (!result.success) {
        throw Exception(result.message ?? 'Failed to save document');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? '${isAadhar ? "Aadhar" : "PAN"} saved')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}')),
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
                      onTap: (_isSaving || _isPickingImage) ? null : () => _pickImage(true),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildUploadBox(
                      title: "${widget.title} Back Image",
                      image: _backImage,
                      onTap: (_isSaving || _isPickingImage) ? null : () => _pickImage(false),
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

  Widget _buildUploadBox({required String title, File? image, required VoidCallback? onTap}) {
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
                child: Image.file(
                  image,
                  fit: BoxFit.cover,
                  cacheWidth: 600,
                  cacheHeight: 600,
                  filterQuality: FilterQuality.low,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
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

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _showPermissionDialog(String permissionName) async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text(
            '$permissionName permission is required to continue. You can enable it from app settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }
}
