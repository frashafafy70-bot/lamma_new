import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/features/trips/presentation/pages/trips_services_page.dart';

class SearchView extends StatefulWidget {
  final String activeRole;

  const SearchView({super.key, required this.activeRole});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);
  final Color royalGreen = const Color(0xFF1B4332);

  String _selectedCategory = 'الكل';
  final List<String> _categories = ['الكل', 'رحلات وتوصيل', 'استشارات قانونية', 'متاجر', 'خدمات طبية'];

  // 🟢 قاعدة بيانات محلية ذكية للخدمات عشان البحث يشتغل طلقة بدون أخطاء فايربيز
  final List<Map<String, dynamic>> _allServices = [
    {'title': 'طلب كابتن فوراً', 'category': 'رحلات وتوصيل', 'icon': Icons.local_taxi_rounded, 'color': const Color(0xFFF3C444), 'route': const TripsServicesPage()},
    {'title': 'توصيل طلبات (دليفري)', 'category': 'رحلات وتوصيل', 'icon': Icons.delivery_dining_rounded, 'color': const Color(0xFFF3C444), 'route': const TripsServicesPage()},
    {'title': 'استشارة محامي', 'category': 'استشارات قانونية', 'icon': Icons.gavel_rounded, 'color': const Color(0xFF0F172A), 'route': null},
    {'title': 'توكيل رسمي', 'category': 'استشارات قانونية', 'icon': Icons.description_rounded, 'color': const Color(0xFF0F172A), 'route': null},
    {'title': 'تسوق من الماركت', 'category': 'متاجر', 'icon': Icons.storefront_rounded, 'color': const Color(0xFF1B4332), 'route': null},
    {'title': 'صيدليات', 'category': 'متاجر', 'icon': Icons.local_pharmacy_rounded, 'color': const Color(0xFF1B4332), 'route': null},
    {'title': 'حجز كشف طبي', 'category': 'خدمات طبية', 'icon': Icons.medical_services_rounded, 'color': Colors.blueAccent, 'route': null},
  ];

  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchResults = []; // تبدأ فارغة لطلب كتابة شيء
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // 🟢 الهيدر الفخم مع شريط البحث
          Container(
            padding: EdgeInsets.only(top: 60.h, left: 20.w, right: 20.w, bottom: 20.h),
            decoration: BoxDecoration(
              color: primaryNavy,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30.r), bottomRight: Radius.circular(30.r)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('البحث الشامل', style: TextStyle(fontFamily: 'Cairo', fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 20.h),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15.r),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _performSearch,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp),
                    decoration: InputDecoration(
                      hintText: 'عن ماذا تبحث؟ (كابتن، محامي، توصيل...)',
                      hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade400),
                      prefixIcon: Icon(Icons.search_rounded, color: goldAccent),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: Colors.grey.shade400),
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

          // 🟢 الفلاتر (الكاتيجوري)
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
                    label: Text(category, style: TextStyle(fontFamily: 'Cairo', fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : primaryNavy)),
                    selected: isSelected,
                    selectedColor: goldAccent,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: isSelected ? goldAccent : Colors.grey.shade300),
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

          // 🟢 عرض النتائج أو الحالات الفارغة
          Expanded(
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_searchController.text.isEmpty && _selectedCategory == 'الكل') {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 80.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text('اكتب ما تبحث عنه للبدء', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sentiment_dissatisfied_rounded, size: 80.sp, color: Colors.grey.shade300),
            SizedBox(height: 16.h),
            Text('لا توجد نتائج مطابقة لبحثك', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, color: Colors.grey.shade500)),
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.r),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            leading: CircleAvatar(
              backgroundColor: (service['color'] as Color).withValues(alpha: 0.1),
              child: Icon(service['icon'], color: service['color']),
            ),
            title: Text(service['title'], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp, color: primaryNavy)),
            subtitle: Text(service['category'], style: TextStyle(fontFamily: 'Cairo', fontSize: 12.sp, color: Colors.grey.shade600)),
            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey.shade400),
            onTap: () {
              if (service['route'] != null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => service['route']));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('هذه الخدمة قيد التجهيز', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: primaryNavy));
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