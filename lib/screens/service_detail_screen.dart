import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/quick_service_model.dart';

class ServiceDetailScreen extends StatelessWidget {
  final QuickService? service;
  final String imagePath;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    required this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    final List<String> diagnosis = service?.diagnosisList ?? [];
    final String status = (service?.status ?? 'unknown').toUpperCase();
    final bool isActive = (service?.status ?? '').toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Service Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service?.serviceName ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          service?.serviceType ?? 'N/A',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.shade50 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Service Type', service?.serviceType ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow('Service Name', service?.serviceName ?? 'N/A'),
            const SizedBox(height: 12),
            _buildInfoRow('Service Charge', ' ${service?.serviceCharge ?? '0.00'}'),
            const SizedBox(height: 12),
            _buildInfoRow('Status', status),
            const SizedBox(height: 20),
            const Text(
              'Diagnosis List',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (diagnosis.isEmpty)
              Text(
                'No diagnosis available',
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: diagnosis.map((item) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          item,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
