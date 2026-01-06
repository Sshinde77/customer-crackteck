import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 🔽 Quick Add expand / collapse
  bool _showAllQuickAdd = false;

  // 🔽 Banner slider
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Up to 20% Off on\nCleaning Services',
      'color': const Color(0xFFC0E8FF),
    },
    {
      'title': 'Get Expert Repair\nin 30 Minutes',
      'color': const Color(0xFFFFE0B2),
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        _bannerIndex = (_bannerIndex + 1) % _banners.length;
        _bannerController.animateToPage(
          _bannerIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // 🔹 Green Header
          _header(),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _searchBar(),

                  /// 🔹 QUICK SERVICE
                  _sectionTitle('Quick Service'),
                  SizedBox(
                    height: 250,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: const [
                        _QuickServiceCard(
                          title: 'Windows PC Restart Issues',
                          image: Icons.desktop_windows_outlined,
                        ),
                        _QuickServiceCard(
                          title: 'Mac PC Restart Issues',
                          image: Icons.laptop_mac_outlined,
                        ),
                        _QuickServiceCard(
                          title: 'Windows Update Issues',
                          image: Icons.system_update_alt_outlined,
                        ),
                      ],
                    ),
                  ),

                  /// 🔹 QUICK ADD
                  const SizedBox(height: 16),
                  _sectionTitle('Quick Add'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _showAllQuickAdd ? _allQuickAdd.length : 3,
                      itemBuilder: (context, index) {
                        final item = _showAllQuickAdd ? _allQuickAdd[index] : _shortQuickAdd[index];
                        return _quickAddItem(item);
                      },
                    ),
                  ),

                  /// 🔽 Expand / Collapse Arrow
                  Center(
                    child: IconButton(
                      icon: Icon(
                        _showAllQuickAdd
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        size: 36,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _showAllQuickAdd = !_showAllQuickAdd;
                        });
                      },
                    ),
                  ),

                  /// 🔹 PROMOTIONAL AUTO SLIDER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 160,
                      child: PageView.builder(
                        controller: _bannerController,
                        itemCount: _banners.length,
                        onPageChanged: (index) => setState(() => _bannerIndex = index),
                        itemBuilder: (_, index) {
                          final banner = _banners[index];
                          return _promoBanner(banner);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  /// 🔹 ENQUIRY SECTION
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: const Color(0xFFFFE5D0),
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.headset_mic_outlined, color: Colors.orange, size: 36),
                                const SizedBox(height: 4),
                                const Text(
                                  'Enquiry',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'Assistance 24 hour',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(20),
                                bottomRight: Radius.circular(20),
                              ),
                              child: Opacity(
                                opacity: 0.9,
                                child: Container(
                                  width: 150,
                                  alignment: Alignment.centerRight,
                                  child: Icon(Icons.support_agent, size: 100, color: Colors.orange.withOpacity(0.2)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 20),
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on, color: Colors.white, size: 28),
              const SizedBox(width: 4),
              const Text(
                'CRACKTECK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 1.2,
                ),
              ),
              const Text(
                '®',
                style: TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          ),
          Stack(
            children: [
              const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
              Positioned(
                right: 2,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 18),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 28),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _quickAddItem(Map<String, dynamic> item) {
    return Column(
      children: [
        Container(
          height: 80,
          width: 80,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: item['image'] != null
              ? Image.asset(
                  item['image'] as String,
                  fit: BoxFit.contain,
                )
              : const Center(
                  child: Text('Other', style: TextStyle(fontWeight: FontWeight.w500)),
                ),
        ),
        const SizedBox(height: 8),
        Text(
          item['label'] as String,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _promoBanner(Map<String, dynamic> banner) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: banner['color'] as Color,
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  banner['title'] as String,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A1D37),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Book Now',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.north_east, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(bottomRight: Radius.circular(16)),
              child: Opacity(
                opacity: 0.8,
                child: Icon(Icons.person, size: 140, color: Colors.blue.withOpacity(0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickServiceCard extends StatelessWidget {
  final String title;
  final IconData image;

  const _QuickServiceCard({
    required this.title,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(image, size: 60, color: Colors.black45),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Visit charge of Rs 159 waived in final bill; spare part/repair cost extra.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final List<Map<String, dynamic>> _shortQuickAdd = [
  {'label': 'Computer', 'image': 'assests/computer.png'},
  {'label': 'Laptop', 'image': 'assests/laptop.png'},
  {'label': 'CCTV', 'image': 'assests/cctv.png'},
];

final List<Map<String, dynamic>> _allQuickAdd = [
  {'label': 'Computer', 'image': 'assests/computer.png'},
  {'label': 'Laptop', 'image': 'assests/laptop.png'},
  {'label': 'CCTV', 'image': 'assests/cctv.png'},
  {'label': 'Printer', 'image': 'assests/printer.png'},
  {'label': 'Server', 'image': 'assests/server.png'},
  {'label': 'EPBX', 'image': 'assests/epbx.png'},
  {'label': 'Bio Metric', 'image': 'assests/Bio_metric.png'},
  {'label': 'Router', 'image': 'assests/router.png'},
  {'label': 'Other', 'image': null},
];
