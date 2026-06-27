import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart'; 

class SearchView extends StatefulWidget {
  final String activeRole; 

  const SearchView({super.key, required this.activeRole});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = ['الكل', 'رحلات وتوصيل', 'استشارات قانونية', 'خدمات طبية'];
  int _selectedCategoryIndex = 0;

  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel(); 
    super.dispose();
  }

  Future<void> _performSearch() async {
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    List<Map<String, dynamic>> tempResults = [];
    String query = _searchQuery.trim().toLowerCase();

    try {
      if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 1) {
        var tripsSnap = await FirebaseFirestore.instance
            .collection('trips')
            .where('status', isEqualTo: 'available')
            .get();

        for (var doc in tripsSnap.docs) {
          var data = doc.data();
          String fromCity = (data['fromCity'] ?? '').toString().toLowerCase();
          String toCity = (data['toCity'] ?? '').toString().toLowerCase();

          if (fromCity.contains(query) || toCity.contains(query)) {
            tempResults.add({
              'id': doc.id,
              'type': 'trip',
              'title': 'رحلة: ${data['fromCity']} ⬅️ ${data['toCity']}',
              'subtitle': 'الكابتن: ${data['driverName']} | السعر: ${data['price']} ج',
              'icon': Icons.local_taxi_rounded,
              'color': Colors.blue,
              'data': data
            });
          }
        }
      }

      if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 2) {
        var lawyersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('activeRole', isEqualTo: 'lawyer')
            .get();

        for (var doc in lawyersSnap.docs) {
          var data = doc.data();
          String name = (data['name'] ?? '').toString().toLowerCase();
          
          if (name.contains(query)) {
            tempResults.add({
              'id': doc.id,
              'type': 'lawyer',
              'title': data['name'] ?? 'محامي',
              'subtitle': 'استشارات قانونية محترفة',
              'icon': Icons.gavel_rounded,
              'color': goldAccent,
              'data': data
            });
          }
        }
      }

      if (_selectedCategoryIndex == 0 || _selectedCategoryIndex == 3) {
        var medicalSnap = await FirebaseFirestore.instance
            .collection('users')
            .where('activeRole', whereIn: ['doctor', 'nurse'])
            .get();

        for (var doc in medicalSnap.docs) {
          var data = doc.data();
          String name = (data['name'] ?? '').toString().toLowerCase();
          String role = data['activeRole'] == 'doctor' ? 'طبيب' : 'تمريض';
          
          if (name.contains(query)) {
            tempResults.add({
              'id': doc.id,
              'type': 'medical',
              'title': data['name'] ?? role,
              'subtitle': 'رعاية صحية ($role)',
              'icon': Icons.medical_services_rounded,
              'color': Colors.teal,
              'data': data
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = tempResults;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("خطأ في البحث: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء البحث', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)))
        );
      }
    }
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _performSearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 20.h,
              bottom: 20.h,
              left: 20.w,
              right: 20.w,
            ),
            decoration: BoxDecoration(
              color: primaryNavy,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30.r)),
              boxShadow: [
                BoxShadow(color: primaryNavy.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'البحث الشامل',
                  style: TextStyle(color: Colors.white, fontSize: 24.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
                ),
                SizedBox(height: 16.h),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                  decoration: InputDecoration(
                    hintText: 'عن ماذا تبحث؟ (كابتن، محامي، طبيب...)',
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
                    prefixIcon: Icon(Icons.search_rounded, color: goldAccent, size: 24.sp),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: Colors.grey, size: 20.sp),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged('');
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(
            height: 60.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                bool isSelected = _selectedCategoryIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedCategoryIndex = index);
                    _performSearch(); 
                  },
                  child: Container(
                    margin: EdgeInsets.only(left: 8.w),
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? goldAccent : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(color: isSelected ? goldAccent : Colors.grey.shade300),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _categories[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryNavy,
                        fontFamily: 'Cairo',
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
  
          Expanded(
            child: _searchQuery.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_rounded, size: 80.sp, color: Colors.grey.shade300),
                        SizedBox(height: 16.h),
                        Text('اكتب ما تبحث عنه للبدء', style: TextStyle(color: Colors.grey.shade500, fontSize: 16.sp, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : _isLoading
                    ? Center(child: CircularProgressIndicator(color: goldAccent))
                    : _searchResults.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sentiment_dissatisfied_rounded, size: 80.sp, color: Colors.grey.shade400),
                                SizedBox(height: 16.h),
                                Text('لا توجد نتائج مطابقة لـ "$_searchQuery"', style: TextStyle(color: Colors.grey.shade600, fontSize: 16.sp, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.only(top: 8.h, left: 16.w, right: 16.w, bottom: 20.h),
                            itemCount: _searchResults.length,
                            itemBuilder: (context, index) {
                              var item = _searchResults[index];
                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.only(bottom: 12.h),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  leading: Container(
                                    padding: EdgeInsets.all(10.w),
                                    decoration: BoxDecoration(
                                      color: (item['color'] as Color).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12.r)
                                    ),
                                    child: Icon(item['icon'], color: item['color'], size: 24.sp),
                                  ),
                                  title: Text(item['title'], style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp)),
                                  subtitle: Text(item['subtitle'], style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600, fontSize: 13.sp)),
                                  trailing: Icon(Icons.arrow_forward_ios_rounded, size: 16.sp, color: Colors.grey.shade400),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('الانتقال إلى التفاصيل...', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)))
                                    );
                                  },
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}