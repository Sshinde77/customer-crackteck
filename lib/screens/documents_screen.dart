import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'edit_document_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  // State variables for Aadhar
  String _aadharNumber = '*******121';
  File? _aadharFront;
  File? _aadharBack;

  // State variables for PAN
  String _panNumber = '*****121';
  File? _panFront;
  File? _panBack;

  Future<void> _navigateToEdit(bool isAadhar) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDocumentScreen(
          title: isAadhar ? 'Aadhar Card details' : 'PAN Card details',
          label: isAadhar ? 'Aadhar no.' : 'PAN no.',
          initialNumber: isAadhar ? _aadharNumber : _panNumber,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        if (isAadhar) {
          _aadharNumber = result['number'];
          _aadharFront = result['frontImage'];
          _aadharBack = result['backImage'];
        } else {
          _panNumber = result['number'];
          _panFront = result['frontImage'];
          _panBack = result['backImage'];
        }
      });
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
        title: const Text(
          'Documents',
          style: TextStyle(color: Colors.white),
        ),

      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Aadhar Section
              _buildDocumentSection(
                label: 'Aadhar no.',
                maskedValue: _aadharNumber,
                frontImage: _aadharFront,
                backImage: _aadharBack,
                onEdit: () => _navigateToEdit(true),
              ),
              
              const SizedBox(height: 30),

              // PAN Section
              _buildDocumentSection(
                label: 'PAN no.',
                maskedValue: _panNumber,
                frontImage: _panFront,
                backImage: _panBack,
                onEdit: () => _navigateToEdit(false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentSection({
    required String label,
    required String maskedValue,
    File? frontImage,
    File? backImage,
    required VoidCallback onEdit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            maskedValue,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(child: _buildImagePreview(frontImage)),
              const SizedBox(width: 15),
              Expanded(child: _buildImagePreview(backImage)),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: onEdit,
            icon: const Text(
              'Edit',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            label: const Icon(Icons.edit, color: Colors.red, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(File? file) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: file != null
            ? Image.file(file, fit: BoxFit.cover)
            : Image.network(
                'https://via.placeholder.com/150x100?text=Document',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Center(
                  child: Icon(Icons.image, color: Colors.grey),
                ),
              ),
      ),
    );
  }
}
