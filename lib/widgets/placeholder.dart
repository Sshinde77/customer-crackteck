import 'package:flutter/material.dart';

class ComingSoonScreen extends StatefulWidget {
  final int roleId;
  final String roleName;
  final int currentIndex; // which tab is active in bottom nav

  const ComingSoonScreen({
    super.key,
    required this.roleId,
    required this.roleName,
    this.currentIndex = 1,
  });

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar with back button and NO title
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E7C10),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // ✅ Center Coming Soon
      body: const Center(
        child: Text(
          "Coming Soon",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),



    );
  }
}
