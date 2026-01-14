import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../provider/document_provider.dart';
import 'edit_document_screen.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentProvider>().fetchAllDocuments();
    });
  }

  Future<void> _navigateToEdit(bool isAadhar, String currentNumber, int? id) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDocumentScreen(
          title: isAadhar ? 'Aadhar Card details' : 'PAN Card details',
          label: isAadhar ? 'Aadhar no.' : 'PAN no.',
          initialNumber: currentNumber,
          documentId: id,
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        context.read<DocumentProvider>().fetchAllDocuments();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const String imageBaseUrl = "https://crackteck.co.in/";

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
      body: Consumer<DocumentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final aadhar = provider.aadharCard;
          final pan = provider.panCard;

          return RefreshIndicator(
            onRefresh: provider.fetchAllDocuments,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDocumentSection(
                    label: 'Aadhar no.',
                    maskedValue: aadhar?.aadharNumber ?? 'Not Available',
                    frontUrl: aadhar?.aadharFrontPath != null 
                        ? "$imageBaseUrl${aadhar!.aadharFrontPath}" 
                        : null,
                    backUrl: aadhar?.aadharBackPath != null 
                        ? "$imageBaseUrl${aadhar!.aadharBackPath}" 
                        : null,
                    onEdit: () => _navigateToEdit(true, aadhar?.aadharNumber ?? '', aadhar?.id),
                  ),
                  const SizedBox(height: 30),
                  _buildDocumentSection(
                    label: 'PAN no.',
                    maskedValue: pan?.panNumber ?? 'Not Available',
                    frontUrl: pan?.panCardFrontPath != null 
                        ? "$imageBaseUrl${pan!.panCardFrontPath}" 
                        : null,
                    backUrl: pan?.panCardBackPath != null 
                        ? "$imageBaseUrl${pan!.panCardBackPath}" 
                        : null,
                    onEdit: () => _navigateToEdit(false, pan?.panNumber ?? '', pan?.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentSection({
    required String label,
    required String maskedValue,
    String? frontUrl,
    String? backUrl,
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
              Expanded(child: _buildImagePreview(frontUrl)),
              const SizedBox(width: 15),
              Expanded(child: _buildImagePreview(backUrl)),
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

  Widget _buildImagePreview([String? url]) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _getImageWidget(url),
      ),
    );
  }

  Widget _getImageWidget(String? url) {
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        },
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    } else {
      return Image.network(
        'https://via.placeholder.com/150x100?text=Document',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.image, color: Colors.grey),
        ),
      );
    }
  }
}
