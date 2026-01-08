import 'package:flutter/material.dart';
import '../routes/app_routes.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,

        /// AppBar
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F8B00),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Payment',
            style: TextStyle(color: Colors.white),
          ),
        ),

        /// Body
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// Offers
              const Text(
                'Offers',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Enter Offer Code',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Online
              const Text(
                'Online',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [

                    /// Google Pay
                    _paymentTile(
                      index: 0,
                      icon: Icons.account_balance_wallet,
                      title: 'Google Pay',
                      amount: '₹ 2,500',
                    ),

                    const Divider(height: 1),

                    /// PhonePe
                    _paymentTile(
                      index: 1,
                      icon: Icons.payment,
                      title: 'PhonePe',
                      amount: '₹ 2,500',
                    ),

                    const Divider(height: 1),

                    /// Add new UPI
                    ListTile(
                      leading: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.green,
                      ),
                      title: const Text('Add New UPI ID'),
                      onTap: () {},
                    ),
                  ],
                ),
              ),

              const Spacer(),

              /// Done Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F8B00),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    if (selectedIndex == -1) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select a payment method'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment Successful'),
                        backgroundColor: Color(0xFF1F8B00),
                      ),
                    );

                    // Redirect to home screen/dashboard
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.hometab,
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Payment Tile Widget
  Widget _paymentTile({
    required int index,
    required IconData icon,
    required String title,
    required String amount,
  }) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            amount,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Checkbox(
            value: selectedIndex == index,
            onChanged: (val) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),
        ],
      ),
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
    );
  }
}
