import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/catalog_provider.dart';
import 'widgets/test_card.dart';

class CatalogScreen extends StatefulWidget {
  final String? initialCategory;

  const CatalogScreen({super.key, this.initialCategory});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Home Visits',
    'In-House Tests',
    'Physiotherapy',
    'Health Packages',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<CatalogProvider>().setCategoryFilter(widget.initialCategory!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final services = catalog.filteredServices;
    final dynamicCategories = ['All', ...catalog.categories.map((c) => c.name)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnostics & Services'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (val) => catalog.setSearchQuery(val),
                  decoration: InputDecoration(
                    hintText: 'Search Blood test, X-Ray, ECG, PFT, Physio...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              catalog.setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    fillColor: AppColors.background,
                  ),
                ),
                const SizedBox(height: 12),

                // Dynamic Category Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: dynamicCategories.map((category) {
                      final isSelected = catalog.selectedCategoryFilter.toLowerCase() == category.toLowerCase() ||
                          (category == 'All' && catalog.selectedCategoryFilter == 'All');
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => catalog.setCategoryFilter(category),
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 12,
                          ),
                          side: BorderSide(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Services List
          Expanded(
            child: services.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted),
                          const SizedBox(height: 12),
                          const Text(
                            'No Tests or Services Found',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try searching for another keyword or change your filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: () {
                              _searchController.clear();
                              catalog.setSearchQuery('');
                              catalog.setCategoryFilter('All');
                            },
                            child: const Text('Reset All Filters'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      return TestCard(service: services[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
