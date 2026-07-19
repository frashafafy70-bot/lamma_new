import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/features/trips/presentation/pages/trips_services_page.dart';

// 🟢 استدعاء ملف الترجمة الخاص بالمشروع
import 'package:lamma_new/l10n/app_localizations.dart';
import 'package:lamma_new/core/theme/app_colors.dart';

class SearchView extends StatefulWidget {
  final String activeRole;

  const SearchView({super.key, required this.activeRole});

  @override
  State<SearchView> createState() => _SearchViewState();
}

// 🟢 تفعيل AutomaticKeepAliveClientMixin عشان العميل ميخسرش نتايج البحث لو قلب بين التابات
class _SearchViewState extends State<SearchView>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  bool _isInitialized = false;
  late String _selectedCategory;
  late List<String> _categories;
  late List<Map<String, dynamic>> _allServices;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  bool get wantKeepAlive => true; // 🟢 الحفاظ على الشاشة حية في الخلفية

  @override
  void initState() {
    super.initState();
    _searchResults = [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 🟢 تهيئة القوائم هنا للوصول إلى الترجمة (وفرنا الذاكرة عن طريق تعريف المتغيرات مرة واحدة كـ late)
    final l10n = AppLocalizations.of(context)!;

    _categories = [
      l10n.allCategory,
      l10n.tripsAndDeliveryCategory,
      l10n.legalConsultationsCategory,
      l10n.storesCategory,
      l10n.medicalServicesCategory,
    ];

    _allServices = [
      {
        'title': l10n.requestDriverService,
        'category': l10n.tripsAndDeliveryCategory,
        'icon': Icons.local_taxi_rounded,
        'color': AppColors.accentGold,
        'route': const TripsServicesPage()
      },
      {
        'title': l10n.deliveryService,
        'category': l10n.tripsAndDeliveryCategory,
        'icon': Icons.delivery_dining_rounded,
        'color': AppColors.accentGold,
        'route': const TripsServicesPage()
      },
      {
        'title': l10n.lawyerConsultationService,
        'category': l10n.legalConsultationsCategory,
        'icon': Icons.gavel_rounded,
        'color': AppColors.primaryNavy,
        'route': null
      },
      {
        'title': l10n.officialPowerOfAttorneyService,
        'category': l10n.legalConsultationsCategory,
        'icon': Icons.description_rounded,
        'color': AppColors.primaryNavy,
        'route': null
      },
      {
        'title': l10n.marketShoppingService,
        'category': l10n.storesCategory,
        'icon': Icons.storefront_rounded,
        'color': AppColors.royalGreen,
        'route': null
      },
      {
        'title': l10n.pharmaciesService,
        'category': l10n.storesCategory,
        'icon': Icons.local_pharmacy_rounded,
        'color': AppColors.royalGreen,
        'route': null
      },
      {
        'title': l10n.bookMedicalAppointmentService,
        'category': l10n.medicalServicesCategory,
        'icon': Icons.medical_services_rounded,
        'color': AppColors.info,
        'route': null
      },
    ];

    if (!_isInitialized) {
      _selectedCategory = l10n.allCategory;
      _isInitialized = true;
    }
  }

  void _performSearch(String query) {
    final l10n = AppLocalizations.of(context)!;

    if (query.isEmpty && _selectedCategory == l10n.allCategory) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _searchResults = _allServices.where((service) {
        final matchesCategory = _selectedCategory == l10n.allCategory ||
            service['category'] == _selectedCategory;
        final matchesQuery = service['title']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            service['category']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase());
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🟢 ضروري جداً لعمل الـ KeepAlive
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: AppColors.backgroundLight,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                  top: 60.h, left: 20.w, right: 20.w, bottom: 20.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primaryNavy, AppColors.royalGreen],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30.r),
                    bottomRight: Radius.circular(30.r)),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x4D1B4332),
                      blurRadius: 15,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text(l10n.comprehensiveSearch,
                        style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      style:
                          TextStyle(fontSize: 15.sp, color: AppColors.textDark),
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        hintStyle: TextStyle(
                            fontSize: 14.sp, color: AppColors.textMuted),
                        prefixIcon: Icon(Icons.search_rounded,
                            color: AppColors.accentGold),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: AppColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 16.h),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            SizedBox(
              height: 40.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;
                  return Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: ChoiceChip(
                      label: Text(category,
                          style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primaryNavy
                                  : AppColors.textDark)),
                      selected: isSelected,
                      selectedColor: AppColors.accentGold,
                      backgroundColor: AppColors.cardWhite,
                      showCheckmark: false,
                      side: BorderSide(
                          color: isSelected
                              ? AppColors.accentGold
                              : AppColors.dividerColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r)),
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                          _performSearch(_searchController.text);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: _buildBodyContent(l10n),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(AppLocalizations l10n) {
    if (_searchController.text.isEmpty &&
        _selectedCategory == l10n.allCategory) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(25.w),
              decoration: const BoxDecoration(
                  shape: BoxShape.circle, color: Color(0x80EEEEEE)),
              child: Icon(Icons.search_rounded,
                  size: 60.sp, color: AppColors.textMuted),
            ),
            SizedBox(height: 16.h),
            Text(l10n.typeToStartSearching,
                style: TextStyle(
                    fontSize: 16.sp,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded,
                size: 80.sp, color: AppColors.textMuted),
            SizedBox(height: 16.h),
            Text(l10n.noMatchingResults,
                style: TextStyle(fontSize: 16.sp, color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 100.h),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final service = _searchResults[index];
        return Container(
          margin: EdgeInsets.only(bottom: 12.h),
          decoration: BoxDecoration(
            color: AppColors.cardWhite,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.dividerColor),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 15,
                  offset: Offset(0, 5))
            ],
          ),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: CircleAvatar(
              backgroundColor: (service['color'] as Color).withOpacity(0.1),
              child: Icon(service['icon'], color: service['color']),
            ),
            title: Text(service['title'],
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: AppColors.textDark)),
            subtitle: Text(service['category'],
                style: TextStyle(fontSize: 12.sp, color: AppColors.textMuted)),
            trailing: Icon(Icons.arrow_forward_ios_rounded,
                size: 16, color: AppColors.textMuted),
            onTap: () {
              if (service['route'] != null) {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => service['route']));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(l10n.serviceUnderPreparation,
                      style: const TextStyle(color: Colors.white)),
                  backgroundColor: AppColors.primaryNavy,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.r)),
                ));
              }
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
