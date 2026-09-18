import 'dart:async';
import 'package:flutter/material.dart';
import '../models/diagnostic_category.dart';
import '../models/diagnostic_service.dart';
import '../models/promo_banner.dart';
import '../services/catalog_service.dart';
import '../services/category_service.dart';
import '../services/banner_service.dart';

class CatalogProvider with ChangeNotifier {
  final CatalogService _catalogService = CatalogService();
  final CategoryService _categoryService = CategoryService();
  final BannerService _bannerService = BannerService();

  List<DiagnosticService> _allServices = [];
  List<DiagnosticCategory> _categories = [];
  List<PromoBanner> _banners = [];
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  final List<DiagnosticService> _cart = [];

  StreamSubscription<List<DiagnosticService>>? _servicesSub;
  StreamSubscription<List<DiagnosticCategory>>? _categoriesSub;
  StreamSubscription<List<PromoBanner>>? _bannersSub;

  CatalogProvider() {
    _loadServices();
    _loadCategories();
    _startServicesSync();
    _startCategoriesSync();
    _startBannersSync();
  }

  @override
  void dispose() {
    _servicesSub?.cancel();
    _categoriesSub?.cancel();
    _bannersSub?.cancel();
    super.dispose();
  }

  void _startServicesSync() {
    _servicesSub?.cancel();
    _servicesSub = _catalogService.streamServices().listen((services) {
      _allServices = services;
      notifyListeners();
    });
  }

  void _startCategoriesSync() {
    _categoriesSub?.cancel();
    _categoriesSub = _categoryService.streamCategories().listen((cats) {
      _categories = cats;
      notifyListeners();
    });
  }

  void _startBannersSync() {
    _bannersSub?.cancel();
    _bannersSub = _bannerService.streamBanners().listen((banners) {
      _banners = banners;
      notifyListeners();
    });
  }

  List<DiagnosticService> get allServices => _allServices.isNotEmpty ? _allServices : CatalogService.initialServices;
  List<DiagnosticCategory> get categories => _categories.isNotEmpty ? _categories : CategoryService.defaultCategories;
  List<PromoBanner> get banners => _banners.where((b) => b.isActive).toList();
  List<PromoBanner> get allBanners => _banners;
  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;
  List<DiagnosticService> get cart => _cart;

  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.price);

  Future<void> _loadServices() async {
    _allServices = await _catalogService.getAllServices();
    notifyListeners();
  }

  Future<void> _loadCategories() async {
    _categories = await _categoryService.getAllCategories();
    notifyListeners();
  }

  Future<void> loadBanners() async {
    _banners = await _bannerService.getBanners();
    notifyListeners();
  }

  void refreshCatalog() {
    _loadServices();
    _loadCategories();
    loadBanners();
  }

  void setCategoryFilter(String category) {
    _selectedCategoryFilter = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  List<DiagnosticService> get filteredServices {
    final list = _allServices.isNotEmpty ? _allServices : CatalogService.initialServices;
    return list.where((service) {
      final matchesSearch = _searchQuery.isEmpty ||
          service.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.categoryName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          service.description.toLowerCase().contains(_searchQuery.toLowerCase());

      if (!matchesSearch) return false;

      if (_selectedCategoryFilter == 'All') return true;

      // Legacy broad filters
      if (_selectedCategoryFilter == 'Home Visits') {
        return service.isHomeVisitAvailable;
      }
      if (_selectedCategoryFilter == 'In-House Tests' || _selectedCategoryFilter == 'In-House') {
        return service.isInHouseAvailable && service.category == ServiceCategory.inHouseDiagnostic;
      }

      final filterLower = _selectedCategoryFilter.trim().toLowerCase();

      // 1. Digital X-Ray filter - STRICT: ONLY X-Ray tests!
      if (filterLower.contains('x-ray') || filterLower.contains('xray')) {
        return service.categoryId == 'cat_xray' ||
            service.iconType == 'xray' ||
            service.categoryName.toLowerCase().contains('x-ray') ||
            service.categoryName.toLowerCase().contains('xray') ||
            service.title.toLowerCase().contains('x-ray') ||
            service.title.toLowerCase().contains('xray');
      }

      // 2. Blood Tests filter - STRICT: ONLY Blood tests!
      if (filterLower.contains('blood')) {
        final isXray = service.iconType == 'xray' ||
            service.title.toLowerCase().contains('x-ray') ||
            service.title.toLowerCase().contains('xray');
        final isPhysio = service.category == ServiceCategory.physiotherapy;
        final isPackage = service.categoryId == 'cat_packages' || service.category == ServiceCategory.healthPackage;
        if (isXray || isPhysio || isPackage) return false;

        return service.categoryId == 'cat_blood' ||
            service.iconType == 'blood' ||
            service.categoryName.toLowerCase().contains('blood') ||
            service.title.toLowerCase().contains('blood') ||
            service.title.toLowerCase().contains('cbc') ||
            service.title.toLowerCase().contains('lipid') ||
            service.title.toLowerCase().contains('thyroid') ||
            service.title.toLowerCase().contains('diabetes');
      }

      // 3. ECG & Cardiology - STRICT: ONLY ECG / Cardio tests!
      if (filterLower.contains('ecg') || filterLower.contains('cardio') || filterLower.contains('heart')) {
        return service.categoryId == 'cat_ecg' ||
            service.iconType == 'ecg' ||
            service.iconType == 'stress_test' ||
            service.categoryName.toLowerCase().contains('ecg') ||
            service.title.toLowerCase().contains('ecg') ||
            service.title.toLowerCase().contains('stress test') ||
            service.title.toLowerCase().contains('echocardiography');
      }

      // 4. Ultrasound (USG) - STRICT: ONLY Sonography / USG tests!
      if (filterLower.contains('ultrasound') || filterLower.contains('usg') || filterLower.contains('sonography')) {
        return service.categoryId == 'cat_usg' ||
            service.iconType == 'usg' ||
            service.categoryName.toLowerCase().contains('ultrasound') ||
            service.categoryName.toLowerCase().contains('usg') ||
            service.title.toLowerCase().contains('ultrasound');
      }

      // 5. PFT (Lung Test) - STRICT: ONLY PFT / Spirometry tests!
      if (filterLower.contains('pft') || filterLower.contains('spirometry') || filterLower.contains('lung')) {
        return service.categoryId == 'cat_pft' ||
            service.iconType == 'pft' ||
            service.categoryName.toLowerCase().contains('pft') ||
            service.title.toLowerCase().contains('pft') ||
            service.title.toLowerCase().contains('spirometry');
      }

      // 6. Physiotherapy - STRICT: ONLY Physiotherapy & Rehab tests!
      if (filterLower.contains('physio')) {
        return service.categoryId == 'cat_physio' ||
            service.category == ServiceCategory.physiotherapy ||
            service.iconType == 'physio' ||
            service.categoryName.toLowerCase().contains('physio');
      }

      // 7. Health Packages - STRICT: Full Body & Master packages!
      if (filterLower.contains('package') || filterLower.contains('full body')) {
        return service.categoryId == 'cat_packages' ||
            service.category == ServiceCategory.healthPackage ||
            service.categoryName.toLowerCase().contains('package') ||
            service.includedTests.length > 5;
      }

      // 8. Dynamic category matching (e.g. newly created categories by Admin)
      return (service.categoryId != null && service.categoryId!.toLowerCase() == filterLower) ||
          service.categoryName.trim().toLowerCase() == filterLower;
    }).toList();
  }

  void addToCart(DiagnosticService service) {
    if (!_cart.any((item) => item.id == service.id)) {
      _cart.add(service);
      notifyListeners();
    }
  }

  void removeFromCart(String serviceId) {
    _cart.removeWhere((item) => item.id == serviceId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    notifyListeners();
  }

  bool isInCart(String serviceId) {
    return _cart.any((item) => item.id == serviceId);
  }
}
