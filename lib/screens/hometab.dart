import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../provider/banner_provider.dart';
import '../provider/quick_service_provider.dart';
import '../models/quick_service_model.dart';
import '../models/product_category_model.dart';
import '../services/api_service.dart';
import 'product_list.dart';

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

  // Quick Add categories
  bool _isLoadingCategories = true;
  String? _categoryError;
  List<ProductCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<BannerProvider>().fetchBanners().then((_) {
        if (!mounted) return;
        _startAutoSlide();
      });
      context.read<QuickServiceProvider>().fetchHomeQuickServices();
      _fetchProductCategories();
    });
  }

  Future<void> _fetchProductCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final response = await ApiService.instance.getProductCategories();
      if (!mounted) return;
      if (response.success && response.data != null) {
        setState(() {
          _categories = response.data!;
          _isLoadingCategories = false;
        });
      } else {
        setState(() {
          _categoryError = response.message ?? 'Failed to load categories';
          _isLoadingCategories = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categoryError = 'An unexpected error occurred';
        _isLoadingCategories = false;
      });
    }
  }

  void _startAutoSlide() {
    final banners = context.read<BannerProvider>().banners;
    if (banners.isEmpty) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_bannerController.hasClients) {
        final totalBanners = context.read<BannerProvider>().banners.length;
        if (totalBanners > 0) {
          _bannerIndex = (_bannerIndex + 1) % totalBanners;
          _bannerController.animateToPage(
            _bannerIndex,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
          );
        }
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
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 🔹 Green Header
            _header(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 QUICK SERVICE
                    Consumer<QuickServiceProvider>(
                      builder: (context, provider, child) {
                        if (provider.isHomeLoading) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Quick Service'),
                              SizedBox(
                                height: 160,
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            ],
                          );
                        }

                        if (provider.fixedQuickService == null) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _sectionTitle('Quick Service'),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text(
                                  provider.homeErrorMessage ??
                                      'No quick services available',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        }

                        final fixedQuickService = provider.fixedQuickService!;
                        final otherServices = provider.otherHomeQuickServices;
                        final quickServicesForHome = <QuickService>[
                          fixedQuickService,
                          ...otherServices,
                        ];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle('Quick Service'),
                            SizedBox(
                              height: 250,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                itemCount: quickServicesForHome.length,
                                itemBuilder: (context, index) {
                                  final service = quickServicesForHome[index];
                                  final isFixed = index == 0;
                                  final imagePath = isFixed
                                      ? 'assests/computer.png'
                                      : 'assests/laptop.png';

                                  return _QuickServiceCard(
                                    title: service.serviceName ?? 'N/A',
                                    image: imagePath,
                                    serviceData: service,
                                    onTap: () => _openQuickServiceDetails(
                                      service,
                                      imagePath: imagePath,
                                      updateSelection: !isFixed,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    /// 🔹 QUICK ADD
                    const SizedBox(height: 16),
                    _sectionTitle('Quick Add'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _isLoadingCategories
                          ? const SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : _categoryError != null
                          ? SizedBox(
                              height: 120,
                              child: Center(
                                child: Text(
                                  _categoryError!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.85,
                                  ),
                              itemCount: _visibleQuickAddItems.length,
                              itemBuilder: (context, index) {
                                final item = _visibleQuickAddItems[index];
                                return _quickAddItem(context, item);
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
                      child: Consumer<BannerProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return Container(
                              height: 160,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          if (provider.banners.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return SizedBox(
                            height: 160,
                            child: PageView.builder(
                              controller: _bannerController,
                              itemCount: provider.banners.length,
                              onPageChanged: (index) =>
                                  setState(() => _bannerIndex = index),
                              itemBuilder: (_, index) {
                                final banner = provider.banners[index];
                                final imageUrl = banner.bannerPath != null
                                    ? "https://crackteck.co.in/${banner.bannerPath}"
                                    : "";
                                return _promoBanner(imageUrl);
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    /// 🔹 ENQUIRY SECTION
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.serviceEnquiry,
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
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
                                    const Icon(
                                      Icons.headset_mic_outlined,
                                      color: Colors.orange,
                                      size: 36,
                                    ),
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
                                      child: Icon(
                                        Icons.support_agent,
                                        size: 100,
                                        color: Colors.orange.withOpacity(0.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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
      ),
    );
  }

  List<_QuickAddItem> get _allQuickAddItems {
    final items = _categories
        .where((c) => (c.name ?? '').trim().isNotEmpty)
        .map(
          (c) => _QuickAddItem(
            categoryId: c.id,
            label: c.name!.trim(),
            slug: c.slug,
            imageUrl: c.image != null
                ? 'https://crackteck.co.in/${c.image}'
                : null,
          ),
        )
        .toList();

    items.add(
      const _QuickAddItem(
        categoryId: null,
        label: 'Other',
        slug: null,
        imageUrl: null,
        isOther: true,
      ),
    );
    return items;
  }

  List<_QuickAddItem> get _visibleQuickAddItems {
    if (_showAllQuickAdd) return _allQuickAddItems;
    final categoryItems = _allQuickAddItems.where((i) => !i.isOther).toList();
    final visible = categoryItems.take(2).toList();
    visible.add(
      const _QuickAddItem(
        categoryId: null,
        label: 'Other',
        slug: null,
        imageUrl: null,
        isOther: true,
      ),
    );
    return visible;
  }

  void _openQuickServiceDetails(
    QuickService service, {
    required String imagePath,
    bool updateSelection = false,
  }) {
    if (updateSelection) {
      context.read<QuickServiceProvider>().setSelectedServiceForNavigation(
        service,
      );
    }

    Navigator.pushNamed(
      context,
      AppRoutes.quickServiceDetails,
      arguments: {
        'title': service.serviceName ?? 'N/A',
        'image': imagePath,
        'serviceData': service,
      },
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.notification);
            },
            child: Stack(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                Positioned(
                  right: 2,
                  top: 2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 8,
                      minHeight: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _quickAddItem(BuildContext context, _QuickAddItem item) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductScreen(
              initialCategory: item.isOther ? null : item.label,
              initialCategoryId: item.isOther ? null : item.categoryId,
              initialCategorySlug: item.isOther ? null : item.slug,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            height: 80,
            width: 80,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: item.imageUrl != null
                ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.image_not_supported,
                      color: Colors.grey,
                    ),
                  )
                : const Center(
                    child: Text(
                      'Other',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _promoBanner(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey),
          ),
        ),
      ),
    );
  }
}

class _QuickServiceCard extends StatelessWidget {
  final String title;
  final String image;
  final QuickService? serviceData;
  final double width = 190;
  final EdgeInsetsGeometry margin = const EdgeInsets.only(right: 12);
  final VoidCallback? onTap;

  const _QuickServiceCard({
    required this.title,
    required this.image,
    this.serviceData,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap:
          onTap ??
          () {
            Navigator.pushNamed(
              context,
              AppRoutes.quickServiceDetails,
              arguments: {
                'title': title,
                'image': image,
                'serviceData': serviceData,
              },
            );
          },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        margin: margin,
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
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Image.asset(image, fit: BoxFit.contain),
                ),
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
                    serviceData?.diagnosisList?.join(', ') ??
                        'No diagnosis available',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAddItem {
  final int? categoryId;
  final String label;
  final String? slug;
  final String? imageUrl;
  final bool isOther;

  const _QuickAddItem({
    required this.categoryId,
    required this.label,
    required this.slug,
    required this.imageUrl,
    this.isOther = false,
  });
}
