import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/features/trips/presentation/pages/trips_services_page.dart';

import 'package:lamma_new/theme/app_colors.dart';

class SearchView extends StatefulWidget {
  final String activeRole;

  const SearchView({super.key, required this.activeRole});

  @override
  State<SearchView> createState() => _SearchViewState();
}

// 🟢 تفعيل AutomaticKeepAliveClientMixin عشان العميل ميخسرش نتايج البحث لو قلب بين التابات
class _SearchViewState extends State<SearchView> with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'الكل';
  
  // 🟢 تحويل القوائم الثابتة لـ static const لتوفير استهلاك الذاكرة (Memory Management)
  static const List<String> _categories = ['الكل', 'رحلات وتوصيل', 'استشارات قانونية', 'متاجر', 'خدمات طبية'];

  static const List<Map<String, dynamic>> _allServices = [
    {'title': 'طلب سائق فوراً', 'category': 'رحلات وتوصيل', 'icon': Icons.local_taxi_rounded, 'color': LammaColors.accentGold, 'route': TripsServicesPage()},
    {'title': 'توصيل طلبات (دليفري)', 'category': 'رحلات وتوصيل', 'icon': Icons.delivery_dining_rounded, 'color': LammaColors.accentGold, 'route': TripsServicesPage()},
    {'title': 'استشارة محامي', 'category': 'استشارات قانونية', 'icon': Icons.gavel_rounded, 'color': LammaColors.primaryNavy, 'route': null},
    {'title': 'توكيل رسمي', 'category': 'استشارات قانونية', 'icon': Icons.description_rounded, 'color': LammaColors.primaryNavy, 'route': null},
    {'title': 'تسوق من الماركت', 'category': 'متاجر', 'icon': Icons.storefront_rounded, 'color': LammaColors.royalGreen, 'route': null},
    {'title': 'صيدليات', 'category': 'متاجر', 'icon': Icons.local_pharmacy_rounded, 'color': LammaColors.royalGreen, 'route': null},
    {'title': 'حجز كشف طبي', 'category': 'خدمات طبية', 'icon': Icons.medical_services_rounded, 'color': LammaColors.info, 'route': null},
  ];

  List<Map<String, dynamic>> _searchResults = [];

  @override
  bool get wantKeepAlive => true; // 🟢 الحفاظ على الشاشة حية في الخلفية

  @override
  void initState() {
    super.initState();
    _searchResults = []; 
  }

  void _performSearch(String query) {
    if (query.isEmpty && _selectedCategory == 'الكل') {
      setState(() { _searchResults = []; });
      return;
    }

    setState(() {
      _searchResults = _allServices.where((service) {
        final matchesCategory = _selectedCategory == 'الكل' || service['category'] == _selectedCategory;
        final matchesQuery = service['title'].toString().toLowerCase().contains(query.toLowerCase()) || 
                             service['category'].toString().toLowerCase().contains(query.toLowerCase());
        return matchesCategory && matchesQuery;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 🟢 ضروري جداً لعمل الـ KeepAlive

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: LammaColors.backgroundLight,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.only(top: 60.h, left: 20.w, right: 20.w, bottom: 20.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LammaColors.primaryNavy, LammaColors.royalGreen],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30.r), bottomRight: Radius.circular(30.r)),
                boxShadow: const [ // 🟢 تفعيل const مع لون Hex لتسريع الرسم
                  BoxShadow(color: Color(0x4D1B4332), blurRadius: 15, offset: Offset(0, 5))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Text('البحث الشامل', style: TextStyle(fontFamily: 'Cairo', fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  SizedBox(height: 20.h),
                  Container(
                    decoration: BoxDecoration(
                      color: LammaColors.cardWhite,
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _performSearch,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, color: LammaColors.textDark),
                      decoration: InputDecoration(
                        hintText: 'عن ماذا تبحث؟ (سائق، محامي، توصيل...)',
                        hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: LammaColors.textMuted),
                        prefixIcon: const Icon(Icons.search_rounded, color: LammaColors.accentGold),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, color: LammaColors.textMuted),
                                onPressed: () {
                                  _searchController.clear();
                                  _performSearch('');
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
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
                      label: Text(
                        category, 
                        style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? LammaColors.primaryNavy : LammaColors.textDark)
                      ),
                      selected: isSelected,
                      selectedColor: LammaColors.accentGold,
                      backgroundColor: LammaColors.cardWhite,
                      showCheckmark: false,
                      side: BorderSide(color: isSelected ? LammaColors.accentGold : LammaColors.dividerColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
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
              child: _buildBodyContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_searchController.text.isEmpty && _selectedCategory == 'الكل') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(25.w),
              decoration: const BoxDecoration(
                shape: BoxShape.circle, 
                color: Color(0x80EEEEEE) // 🟢 Hex لـ dividerColor مع opacity 0.5
              ),
              child: Icon(Icons.search_rounded, size: 60.sp, color: LammaColors.textMuted),
            ),
            SizedBox(height: 16.h),
            Text('اكتب ما تبحث عنه للبدء', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: LammaColors.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded, size: 80.sp, color: LammaColors.textMuted),
            SizedBox(height: 16.h),
            Text('لا توجد نتائج مطابقة لبحثك', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: LammaColors.textMuted)),
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
            color: LammaColors.cardWhite,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: LammaColors.dividerColor),
            boxShadow: const [ // 🟢 Const shadow
              BoxShadow(color: Color(0x0A000000), blurRadius: 15, offset: Offset(0, 5))
            ],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: CircleAvatar(
              backgroundColor: (service['color'] as Color).withOpacity(0.1),
              child: Icon(service['icon'], color: service['color']),
            ),
            title: Text(service['title'], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: LammaColors.textDark)),
            subtitle: Text(service['category'], style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: LammaColors.textMuted)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: LammaColors.textMuted),
            onTap: () {
              if (service['route'] != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => service['route']));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('هذه الخدمة قيد التجهيز', style: TextStyle(fontFamily: 'Cairo', color: Colors.white)), 
                    backgroundColor: LammaColors.primaryNavy,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                  )
                );
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