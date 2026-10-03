import 'dart:async';
import 'package:flutter/material.dart';
import '../core/utils/search_matcher.dart';
import '../models/diagnostic_category.dart';
import '../models/diagnostic_service.dart';
import '../models/promo_banner.dart';
import '../models/health_package.dart';
import '../models/lab_section.dart';
import '../models/user_profile.dart';
import '../models/home_collection.dart';
import '../services/home_collection_service.dart';
import '../models/specialist.dart';
import '../services/specialist_service.dart';
import '../services/home_defaults.dart';
import '../services/lab_section_service.dart';
import '../services/package_service.dart';
import '../services/catalog_service.dart';
import '../services/category_service.dart';
import '../services/banner_service.dart';

class CatalogProvider with ChangeNotifier {
  final CatalogService _catalogService = CatalogService();
  final CategoryService _categoryService = CategoryService();
  final BannerService _bannerService = BannerService();
  final PackageService _packageService = PackageService();
  final LabSectionService _labSectionService = LabSectionService();
  final HomeCollectionService _collectionService = HomeCollectionService();
  final SpecialistService _specialistService = SpecialistService();
  List<Specialist> _specialists = [];
  StreamSubscription<List<Specialist>>? _specialistsSub;

  List<DiagnosticService> _allServices = [];
  List<DiagnosticCategory> _categories = [];
  List<PromoBanner> _banners = [];
  List<HealthPackage> _packages = [];
  List<LabAudience> _labAudiences = [];
  bool _packagesLoaded = false;
  bool _labSectionsLoaded = false;
  List<HomeCollection> _collections = [];
  bool _collectionsLoaded = false;

  // Built-in home content derived from the catalog, cached per catalog list.
  List<DiagnosticService>? _defaultsSource;
  List<LabAudience> _defaultAudiences = const [];
  List<HomeCollection> _defaultCollections = const [];
  String _selectedCategoryFilter = 'All';
  String _searchQuery = '';
  final List<DiagnosticService> _cart = [];
  final Map<String, int> _cartPatients = {};

  StreamSubscription<List<DiagnosticService>>? _servicesSub;
  StreamSubscription<List<DiagnosticCategory>>? _categoriesSub;
  StreamSubscription<List<PromoBanner>>? _bannersSub;
  StreamSubscription<List<HealthPackage>>? _packagesSub;
  StreamSubscription<List<LabAudience>>? _labSub;
  StreamSubscription<List<HomeCollection>>? _collectionsSub;
  Timer? _loadingFallback;

  CatalogProvider() {
    _loadServices();
    _loadCategories();
    _startServicesSync();
    _startCategoriesSync();
    _startBannersSync();
    _packagesSub = _packageService.streamPackages().listen((list) {
      _packages = list;
      _packagesLoaded = true;
      notifyListeners();
    });
    _labSub = _labSectionService.streamAudiences().listen((list) {
      _labAudiences = list;
      _labSectionsLoaded = true;
      notifyListeners();
    });
    _specialistsSub = _specialistService.streamSpecialists().listen((list) {
      _specialists = list;
      notifyListeners();
    });
    _collectionsSub = _collectionService.streamCollections().listen((list) {
      _collections = list;
      _collectionsLoaded = true;
      notifyListeners();
    });
    // Never leave the home skeleton up forever if the backend is unreachable.
    _loadingFallback = Timer(const Duration(seconds: 6), () {
      if (_packagesLoaded && _labSectionsLoaded && _collectionsLoaded) return;
      _packagesLoaded = true;
      _labSectionsLoaded = true;
      _collectionsLoaded = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _servicesSub?.cancel();
    _categoriesSub?.cancel();
    _bannersSub?.cancel();
    _packagesSub?.cancel();
    _labSub?.cancel();
    _collectionsSub?.cancel();
    _specialistsSub?.cancel();
    _loadingFallback?.cancel();
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
  List<HealthPackage> get packages => _packages.where((p) => p.isActive).toList();
  List<HealthPackage> get featuredPackages => packages.where((p) => p.isFeatured).toList();
  /// Admin sections, or ready-made ones built from the catalog until the admin creates any.
  List<LabAudience> get labAudiences {
    if (_labAudiences.isNotEmpty) return _labAudiences.where((a) => a.isActive).toList();
    _ensureDefaults();
    return _defaultAudiences;
  }

  /// Home "Consult specialists" doctors; the original five until the admin adds their own.
  List<Specialist> get specialists =>
      _specialists.isNotEmpty ? _specialists.where((s) => s.isActive).toList() : SpecialistService.defaults;

  /// Curated home sections (Fever, Lifestyle, Athlete…), with the same built-in fallback.
  List<HomeCollection> get homeCollections {
    if (_collections.isNotEmpty) return _collections.where((c) => c.isActive).toList();
    _ensureDefaults();
    return _defaultCollections;
  }

  void _ensureDefaults() {
    final source = allServices;
    if (identical(source, _defaultsSource)) return;
    _defaultsSource = source;
    _defaultAudiences = HomeDefaults.audiences(source);
    _defaultCollections = HomeDefaults.collections(source);
  }

  bool get isLabDataLoading => !_packagesLoaded || !_labSectionsLoaded || !_collectionsLoaded;

  /// Catalog services that are themselves packages (e.g. "Precision Full Body Health Checkup").
  List<DiagnosticService> get catalogPackages => allServices
      .where((s) => s.category == ServiceCategory.healthPackage || s.categoryId == 'cat_packages')
      .toList();

  List<PromoBanner> bannersFor(String placement) => banners.where((b) => b.placement == placement).toList();

  HealthPackage? packageById(String id) {
    for (final p in packages) {
      if (p.id == id) return p;
    }
    return null;
  }

  DiagnosticService? serviceById(String id) {
    for (final s in allServices) {
      if (s.id == id) return s;
    }
    return null;
  }

  /// Packages and tests linked to a sub-category (or the whole audience when [sub] is null).
  ({List<HealthPackage> packages, List<DiagnosticService> tests}) itemsFor(LabAudience audience, [LabSubcategory? sub]) {
    final subs = sub != null ? [sub] : audience.subcategories;
    return _resolve(subs.expand((s) => s.packageIds), subs.expand((s) => s.testIds));
  }

  /// Items from every audience/sub-category that matches the patient's sex and age.
  /// Falls back to all active packages when nothing is targeted at them.
  ({List<HealthPackage> packages, List<DiagnosticService> tests}) recommendedFor(UserProfile? user) {
    final sex = user?.sex;
    final age = (user != null && user.age > 0) ? user.age : null;
    final subs = labAudiences
        .where((a) => a.matches(sex, age))
        .expand((a) => a.subcategories)
        .where((s) => s.fitsAge(age))
        .toList();
    final result = _resolve(subs.expand((s) => s.packageIds), subs.expand((s) => s.testIds));
    if (result.packages.isEmpty && result.tests.isEmpty) {
      return (packages: packages, tests: const <DiagnosticService>[]);
    }
    return result;
  }

  /// Packages and tests inside one collection group / sub-category.
  ({List<HealthPackage> packages, List<DiagnosticService> tests}) groupItems(LabSubcategory group) =>
      _resolve(group.packageIds, group.testIds);

  ({List<HealthPackage> packages, List<DiagnosticService> tests}) _resolve(
      Iterable<String> packageIds, Iterable<String> testIds) {
    final pkgs = <HealthPackage>[];
    for (final id in packageIds.toSet()) {
      final p = packageById(id);
      if (p != null) pkgs.add(p);
    }
    final tests = <DiagnosticService>[];
    for (final id in testIds.toSet()) {
      final t = serviceById(id);
      if (t != null) tests.add(t);
    }
    return (packages: pkgs, tests: tests);
  }
  String get selectedCategoryFilter => _selectedCategoryFilter;
  String get searchQuery => _searchQuery;
  List<DiagnosticService> get cart => _cart;

  int get cartCount => _cart.length;
  double get cartTotal => _cart.fold(0, (sum, item) => sum + item.price * patientsFor(item.id));
  double get cartMrpTotal =>
      _cart.fold(0, (sum, item) => sum + (item.originalPrice ?? item.price) * patientsFor(item.id));
  int patientsFor(String serviceId) => _cartPatients[serviceId] ?? 1;

  void setPatients(String serviceId, int count) {
    if (!isInCart(serviceId)) return;
    _cartPatients[serviceId] = count.clamp(1, 6);
    notifyListeners();
  }

  /// Cart lines as bookable services; a line for N patients is priced ×N.
  List<DiagnosticService> get cartForBooking => _cart.map((s) {
        final n = patientsFor(s.id);
        if (n == 1) return s;
        return s.copyWith(
          title: '${s.title} (×$n patients)',
          price: s.price * n,
          originalPrice: s.originalPrice != null ? s.originalPrice! * n : null,
        );
      }).toList();

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

  List<DiagnosticService> get filteredServices =>
      servicesFor(query: _searchQuery, category: _selectedCategoryFilter);

  /// Search text fields of a test, title first (used for ranking).
  static List<String?> searchFieldsOf(DiagnosticService s) =>
      [s.title, s.categoryName, s.description, s.badge, s.sampleType, ...s.includedTests];

  static List<String?> packageSearchFieldsOf(HealthPackage p) => [p.name, p.offerText, p.tag, 'health package full body'];

  /// Admin health packages matching [query], best first.
  List<HealthPackage> searchPackages(String query) {
    if (query.trim().isEmpty) return const [];
    return SearchMatcher.rank(packages, query, (p) {
      final testNames = p.resolveTests(allServices).map((t) => t.title);
      return [...packageSearchFieldsOf(p), ...testNames];
    });
  }

  /// Tests in [category] (or 'All') matching [query], best match first.
  List<DiagnosticService> servicesFor({required String query, required String category}) {
    final inCategory = _servicesInCategory(category);
    return SearchMatcher.rank(inCategory, query, searchFieldsOf);
  }

  List<DiagnosticService> _servicesInCategory(String categoryFilter) {
    final list = _allServices.isNotEmpty ? _allServices : CatalogService.initialServices;
    return list.where((service) {
      if (categoryFilter == 'All') return true;

      // Legacy broad filters
      if (categoryFilter == 'Home Visits') {
        return service.isHomeVisitAvailable;
      }
      if (categoryFilter == 'In-House Tests' || categoryFilter == 'In-House') {
        return service.isInHouseAvailable;
      }

      final filterLower = categoryFilter.trim().toLowerCase();

      // 1. Digital X-Ray filter - STRICT: ONLY X-Ray tests!
      if (filterLower.contains('x-ray') || filterLower.contains('xray')) {
        final titleLower = service.title.toLowerCase();
        final catLower = service.categoryName.toLowerCase();

        // Strict exclusions: Blood, ECG, USG, PFT, Physio, Packages
        if (service.categoryId == 'cat_blood' ||
            service.iconType == 'blood' ||
            catLower.contains('blood') ||
            titleLower.contains('blood') ||
            titleLower.contains('cbc') ||
            titleLower.contains('lipid') ||
            titleLower.contains('thyroid') ||
            titleLower.contains('glucose') ||
            titleLower.contains('sugar') ||
            titleLower.contains('diabetes') ||
            titleLower.contains('hemoglobin') ||
            titleLower.contains('hba1c') ||
            titleLower.contains('serum')) {
          return false;
        }
        if (service.categoryId == 'cat_ecg' || service.iconType == 'ecg' || titleLower.contains('ecg') || catLower.contains('ecg')) return false;
        if (service.categoryId == 'cat_usg' || service.iconType == 'usg' || titleLower.contains('ultrasound') || catLower.contains('ultrasound')) return false;
        if (service.categoryId == 'cat_pft' || service.iconType == 'pft' || titleLower.contains('pft') || catLower.contains('pft')) return false;
        if (service.categoryId == 'cat_physio' || service.iconType == 'physio' || service.category == ServiceCategory.physiotherapy) return false;
        if (service.categoryId == 'cat_packages' || service.category == ServiceCategory.healthPackage) return false;

        return service.categoryId == 'cat_xray' ||
            service.iconType == 'xray' ||
            catLower.contains('x-ray') ||
            catLower.contains('xray') ||
            titleLower.contains('x-ray') ||
            titleLower.contains('xray') ||
            titleLower.contains('radiograph');
      }

      // 2. Blood Tests filter - STRICT: ONLY Blood tests!
      if (filterLower.contains('blood')) {
        final titleLower = service.title.toLowerCase();
        final catLower = service.categoryName.toLowerCase();
        final isXray = service.iconType == 'xray' ||
            service.categoryId == 'cat_xray' ||
            titleLower.contains('x-ray') ||
            titleLower.contains('xray') ||
            titleLower.contains('radiograph') ||
            catLower.contains('x-ray') ||
            catLower.contains('xray');
        final isPhysio = service.category == ServiceCategory.physiotherapy || service.categoryId == 'cat_physio';
        final isPackage = service.categoryId == 'cat_packages' || service.category == ServiceCategory.healthPackage;
        final isEcg = service.categoryId == 'cat_ecg' || service.iconType == 'ecg';
        final isUsg = service.categoryId == 'cat_usg' || service.iconType == 'usg';
        final isPft = service.categoryId == 'cat_pft' || service.iconType == 'pft';
        if (isXray || isPhysio || isPackage || isEcg || isUsg || isPft) return false;

        return service.categoryId == 'cat_blood' ||
            service.iconType == 'blood' ||
            catLower.contains('blood') ||
            titleLower.contains('blood') ||
            titleLower.contains('cbc') ||
            titleLower.contains('lipid') ||
            titleLower.contains('thyroid') ||
            titleLower.contains('diabetes') ||
            titleLower.contains('sugar') ||
            titleLower.contains('glucose');
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
    _cartPatients.remove(serviceId);
    notifyListeners();
  }

  void clearCart() {
    _cart.clear();
    _cartPatients.clear();
    notifyListeners();
  }

  bool isInCart(String serviceId) {
    return _cart.any((item) => item.id == serviceId);
  }
}
