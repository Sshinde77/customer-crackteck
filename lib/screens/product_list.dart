import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/product_category_model.dart';
import '../models/product_model.dart';
import '../widgets/app_loading_screen.dart';
import 'product_detail_screen.dart';

class ProductScreen extends StatefulWidget {
  final String? initialCategory;
  final int? initialCategoryId;
  final String? initialCategorySlug;

  const ProductScreen({
    super.key,
    this.initialCategory,
    this.initialCategoryId,
    this.initialCategorySlug,
  });

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<ProductData> _products = [];
  List<ProductData> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();

  static const int _allCategoriesValue = -1;
  bool _isLoadingCategories = true;
  String? _categoryError;
  List<ProductCategory> _categories = [];
  int _selectedCategoryId = _allCategoriesValue;
  String? _selectedCategorySlug;
  String? _selectedCategoryName;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId ?? _allCategoriesValue;
    _selectedCategorySlug = widget.initialCategorySlug?.trim();
    _selectedCategoryName = widget.initialCategory?.trim();
    _fetchCategories();
    _fetchProducts();
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      final response = await ApiService.instance.getProductCategories();

      if (!mounted) return;

      if (response.success && response.data != null) {
        final categories = response.data!;
        final ids = categories
            .where((c) => c.id != null)
            .map((c) => c.id)
            .toSet();

        int selectedId = _selectedCategoryId;
        String? selectedSlug = _selectedCategorySlug;
        String? selectedName = _selectedCategoryName;

        if (selectedId == _allCategoriesValue) {
          final slugFilter = (widget.initialCategorySlug ?? '').trim();
          final nameFilter = (widget.initialCategory ?? '').trim();

          ProductCategory? matched;
          if (slugFilter.isNotEmpty) {
            matched = categories
                .where(
                  (c) =>
                      (c.slug ?? '').toLowerCase() == slugFilter.toLowerCase(),
                )
                .cast<ProductCategory?>()
                .firstWhere((c) => c != null, orElse: () => null);
          }
          if (matched == null && nameFilter.isNotEmpty) {
            matched = categories
                .where(
                  (c) => (c.name ?? '').toLowerCase().contains(
                    nameFilter.toLowerCase(),
                  ),
                )
                .cast<ProductCategory?>()
                .firstWhere((c) => c != null, orElse: () => null);
          }

          if (matched?.id != null) {
            selectedId = matched!.id!;
            selectedSlug = matched.slug;
            selectedName = matched.name;
          }
        } else if (!ids.contains(selectedId)) {
          selectedId = _allCategoriesValue;
          selectedSlug = null;
          selectedName = null;
        } else {
          final matched = categories
              .where((c) => c.id == selectedId)
              .cast<ProductCategory?>()
              .firstWhere((c) => c != null, orElse: () => null);
          selectedSlug = matched?.slug;
          selectedName = matched?.name;
        }

        setState(() {
          _categories = categories;
          _isLoadingCategories = false;
          _selectedCategoryId = selectedId;
          _selectedCategorySlug = selectedSlug;
          _selectedCategoryName = selectedName;
        });

        _applyFilters();
        return;
      }

      setState(() {
        _categoryError = response.message ?? 'Failed to load categories';
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _categoryError = 'An unexpected error occurred';
        _isLoadingCategories = false;
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.instance.getProducts();

      if (response.success && response.data != null) {
        setState(() {
          _products = response.data!.products ?? [];
          _applyFilters();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    String query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((p) {
        final nameMatches = (p.warehouseProduct?.productName ?? '')
            .toLowerCase()
            .contains(query);
        final int? categoryIdFilter = _selectedCategoryId == _allCategoriesValue
            ? null
            : _selectedCategoryId;
        final categoryNameFilter = _selectedCategoryName?.trim();
        final categorySlugFilter = _selectedCategorySlug?.trim();
        final bool hasNameFilter =
            categoryNameFilter != null && categoryNameFilter.isNotEmpty;
        final bool hasSlugFilter =
            categorySlugFilter != null && categorySlugFilter.isNotEmpty;
        if (categoryIdFilter == null && !hasNameFilter && !hasSlugFilter) {
          return nameMatches;
        }

        final parentCategory = p.warehouseProduct?.parentCategorie;
        final int? productCategoryId =
            parentCategory?.id ??
            p.warehouseProduct?.parentCategoryId ??
            p.categoryId;
        final String productCategorySlug =
            (parentCategory?.slug ?? p.categorySlug ?? '').toLowerCase();
        final String productCategoryName =
            (parentCategory?.name ?? p.categoryName ?? '').toLowerCase();

        bool categoryMatches = true;
        if (categoryIdFilter != null) {
          if (productCategoryId != null) {
            categoryMatches = productCategoryId == categoryIdFilter;
          } else if (hasSlugFilter) {
            categoryMatches =
                productCategorySlug == categorySlugFilter.toLowerCase();
          } else if (hasNameFilter) {
            categoryMatches = productCategoryName.contains(
              categoryNameFilter.toLowerCase(),
            );
          } else {
            categoryMatches = false;
          }
        } else if (hasSlugFilter) {
          categoryMatches =
              productCategorySlug == categorySlugFilter.toLowerCase();
        } else if (hasNameFilter) {
          categoryMatches = productCategoryName.contains(
            categoryNameFilter.toLowerCase(),
          );
        }

        return nameMatches && categoryMatches;
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _currentTitle() {
    if (_selectedCategoryId != _allCategoriesValue) {
      final name = (_selectedCategoryName ?? '').trim();
      if (name.isNotEmpty) return name;
    }
    final initial = (widget.initialCategory ?? '').trim();
    if (initial.isNotEmpty) return initial;
    return 'Product';
  }

  Widget _buildCategoryFilter() {
    final container = Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.category_outlined, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: _isLoadingCategories
                ? Row(
                    children: const [
                      SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Loading categories...'),
                    ],
                  )
                : _categoryError != null
                ? Text(
                    'Categories unavailable',
                    style: TextStyle(color: Colors.grey.shade600),
                    overflow: TextOverflow.ellipsis,
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedCategoryId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int>(
                          value: _allCategoriesValue,
                          child: Text('All Categories'),
                        ),
                        ..._categories.where((c) => c.id != null).map((c) {
                          return DropdownMenuItem<int>(
                            value: c.id!,
                            child: Text(
                              c.name ?? 'Unnamed',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        if (value == _selectedCategoryId) return;

                        if (value == _allCategoriesValue) {
                          setState(() {
                            _selectedCategoryId = _allCategoriesValue;
                            _selectedCategorySlug = null;
                            _selectedCategoryName = null;
                          });
                          _applyFilters();
                          return;
                        }

                        final matched = _categories
                            .where((c) => c.id == value)
                            .cast<ProductCategory?>()
                            .firstWhere((c) => c != null, orElse: () => null);

                        setState(() {
                          _selectedCategoryId = value;
                          _selectedCategorySlug = matched?.slug;
                          _selectedCategoryName = matched?.name;
                        });
                        _applyFilters();
                      },
                    ),
                  ),
          ),
          if (_categoryError != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _fetchCategories,
              tooltip: 'Retry',
            ),
          if (_categoryError == null &&
              !_isLoadingCategories &&
              _selectedCategoryId != _allCategoriesValue)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _selectedCategoryId = _allCategoriesValue;
                  _selectedCategorySlug = null;
                  _selectedCategoryName = null;
                });
                _applyFilters();
              },
              tooltip: 'Clear',
            ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: container,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,

        /// APP BAR
        appBar: AppBar(
          backgroundColor: const Color(0xFF1F8B00),
          elevation: 0,

          title: Text(
            _currentTitle(),
            style: const TextStyle(color: Colors.white),
          ),
        ),

        body: Column(
          children: [
            /// SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) => _applyFilters(),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// CATEGORY FILTER
            _buildCategoryFilter(),

            /// PRODUCT GRID
            Expanded(
              child: _isLoading
                  ? const AppLoadingScreen(message: 'Loading products.')
                  : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _fetchProducts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _filteredProducts.isEmpty
                  ? const Center(child: Text('No products found'))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio:
                                0.68, // Slightly taller to fit 2 lines comfortably
                          ),
                      itemBuilder: (context, index) {
                        return _productCard(context, _filteredProducts[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// PRODUCT CARD
  Widget _productCard(BuildContext context, ProductData product) {
    final wp = product.warehouseProduct;
    final String imageUrl = wp?.mainProductImage != null
        ? "https://crackteck.co.in/${wp!.mainProductImage}"
        : "";

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// IMAGE - Fixed square container
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                      )
                    : const Icon(Icons.image, color: Colors.grey, size: 40),
              ),
            ),
          ),

          const SizedBox(height: 8),

          /// PRICE
          Text(
            "₹ ${wp?.finalPrice ?? '0'}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),

          const SizedBox(height: 2),

          /// NAME - Fixed height for 2 lines to keep layout uniform
          SizedBox(
            height: 32, // Height enough for 2 lines of text
            child: Text(
              wp?.productName ?? 'Unnamed Product',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.2,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
