import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class WorkProgressTrackerScreen extends StatefulWidget {
  const WorkProgressTrackerScreen({super.key});

  @override
  State<WorkProgressTrackerScreen> createState() => _WorkProgressTrackerScreenState();
}

class _WorkProgressTrackerScreenState extends State<WorkProgressTrackerScreen> {
  bool isApproved = false;
  bool isRejected = false;
  Map<String, dynamic>? productData;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      productData = args;
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject Product'),
          content: TextField(
            controller: _reasonController,
            decoration: const InputDecoration(
              hintText: 'Enter reason for rejection',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_reasonController.text.isNotEmpty) {
                  setState(() {
                    isRejected = true;
                    isApproved = false;
                  });
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Submit', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String productName = productData?['productName'] ?? 'General Service';
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Work Progress tracker',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExecutiveCard(),
            const SizedBox(height: 24),
            Text(
              productName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            _buildTimeline(productName),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutiveCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage('https://img.freepik.com/free-photo/young-bearded-man-with-striped-shirt_273609-5677.jpg'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Denil Rao',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Field Executive',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
                Text(
                  'ID No. 1010101010',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                onPressed: () {},
              ),
              const SizedBox(
                height: 30,
                child: VerticalDivider(color: Colors.grey),
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined, color: Colors.green),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline(String productName) {
    // Dynamic content based on product
    bool isWindows = productName.contains('Windows');
    
    return Column(
      children: [
        _buildTimelineItem(
          title: isWindows ? 'Initial Scan' : 'External Inspection',
          status: 'completed',
          images: true,
        ),
        _buildTimelineItem(
          title: isWindows ? 'System Integrity Check' : 'Internal Cleaning',
          status: isApproved ? 'completed' : (isRejected ? 'failed' : 'failed'),
          subtitle: isWindows ? 'Registry errors found' : 'Heavy dust accumulation',
          subtitleColor: isApproved ? Colors.grey : Colors.red,
          images: true,
          showActionCard: true,
        ),
        _buildTimelineItem(
          title: isWindows ? 'Driver Updates' : 'Component Testing',
          status: 'completed',
          images: true,
        ),
        _buildTimelineItem(
          title: isWindows ? 'Patching Completed' : 'Final Assembly',
          status: 'completed',
          images: true,
        ),
        _buildTimelineItem(
          title: 'Quality Assurance',
          status: 'completed',
          isLast: true,
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required String title,
    required String status,
    String? subtitle,
    Color? subtitleColor,
    bool images = false,
    bool showActionCard = false,
    bool isLast = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Icon(
                status == 'completed' ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: status == 'completed' ? Colors.green : Colors.red,
                size: 20,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: TextStyle(color: subtitleColor, fontSize: 14),
                    ),
                  ),
                if (images)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Row(
                      children: [
                        _buildSmallImage(),
                        const SizedBox(width: 8),
                        _buildSmallImage(),
                      ],
                    ),
                  ),
                if (showActionCard) _buildActionCard(isApproved, isRejected),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallImage() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Image.network(
        productData?['imageUrl'] ?? 'https://media.istockphoto.com/id/1344440040/photo/computer-processor-cpu-isolated-on-white.jpg?s=612x612&w=0&k=20&c=L_YF230UoW4pM3h_uW8Gv6x5Y3B7V_h0H0o0k0g=',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildActionCard(bool approved, bool rejected) {
    String name = productData?['productName'] ?? 'Product';
    String price = productData?['price'] ?? '0';
    String img = productData?['imageUrl'] ?? 'https://m.media-amazon.com/images/I/51fS8K9-fFL._AC_UF894,1000_QL80_.dart';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 90,
                height: 90,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.network(
                  img,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          '₹ $price',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '28% off',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Incl. Shipping & all Taxes',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text(
                          'Qty: 1',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        if (approved) ...[
                          const SizedBox(width: 30),
                          const Text(
                            'Approved',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                        if (rejected) ...[
                          const SizedBox(width: 30),
                          const Text(
                            'Rejected',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (!approved && !rejected) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _showRejectDialog,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      isApproved = true;
                      isRejected = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
