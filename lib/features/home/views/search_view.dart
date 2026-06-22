import 'package:flutter/material.dart';

// ⚠️ تنبيه: تأكد من صحة مسارات الصفحات التالية بناءً على هيكل مجلداتك
import '../../legal/presentation/pages/legal_services_page.dart';
import '../../medical/medical_services_page.dart';
import '../../trips/presentation/pages/trips_services_page.dart';

class SearchView extends StatefulWidget {
  final String activeRole;

  const SearchView({super.key, required this.activeRole});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final Color primaryNavy = const Color(0xFF0F172A);
  String _searchQuery = '';

  final List<Map<String, dynamic>> _allServices = [
    {'title': 'الاستشارات القانونية', 'subtitle': 'محامون، قضايا، استشارات', 'icon': Icons.gavel_rounded, 'color': Colors.amber, 'type': 'legal'},
    {'title': 'حاسبة المواريث', 'subtitle': 'الفرز الشرعي للتركات', 'icon': Icons.calculate_rounded, 'color': Colors.amber, 'type': 'legal'},
    {'title': 'صياغة العقود', 'subtitle': 'بيع، إيجار، شركات', 'icon': Icons.edit_document, 'color': Colors.amber, 'type': 'legal'},
    {'title': 'الخدمات الطبية', 'subtitle': 'أطباء، تمريض، رعاية', 'icon': Icons.medical_services_rounded, 'color': Colors.green, 'type': 'medical'},
    {'title': 'حجز مشوار (تاكسي)', 'subtitle': 'توصيل رحلات آمنة', 'icon': Icons.local_taxi_rounded, 'color': Colors.blue, 'type': 'trips'},
    {'title': 'الخدمات العامة', 'subtitle': 'صيانة، تنظيف، أخرى', 'icon': Icons.dashboard_customize_rounded, 'color': Colors.purple, 'type': 'general'},
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> searchResults = [];
    if (_searchQuery.isNotEmpty) {
      searchResults = _allServices.where((service) {
        return service['title'].toLowerCase().contains(_searchQuery.toLowerCase()) || 
               service['subtitle'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20, left: 20, right: 20),
          decoration: BoxDecoration(color: primaryNavy, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25))),
          child: TextField(
            textDirection: TextDirection.rtl,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            style: const TextStyle(fontFamily: 'Cairo'),
            decoration: InputDecoration(
              hintText: 'ابحث عن خدمة، استشارة، أو مشوار...', hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: primaryNavy),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
        ),
        Expanded(
          child: _searchQuery.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.manage_search_rounded, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text('اكتب ما تبحث عنه لتظهر النتائج', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            : searchResults.isEmpty
              ? Center(child: Text('لا توجد نتائج مطابقة لـ "$_searchQuery"', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, fontFamily: 'Cairo', fontWeight: FontWeight.bold)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    var item = searchResults[index];
                    return Card(
                      elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        leading: CircleAvatar(backgroundColor: (item['color'] as Color).withValues(alpha: 0.1), child: Icon(item['icon'], color: item['color'])),
                        title: Text(item['title'], style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(item['subtitle'], style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600, fontSize: 13)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: () {
                          if (item['type'] == 'legal') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LegalServicesPage(isLawyer: widget.activeRole == 'lawyer')));
                          } else if (item['type'] == 'medical') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalServicesPage(medicalRole: (widget.activeRole == 'doctor' || widget.activeRole == 'nurse') ? 'provider' : 'patient')));
                          } else if (item['type'] == 'trips') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TripsServicesPage(isDriver: widget.activeRole == 'captain')));
                          }
                        },
                      ),
                    );
                  },
                )
        )
      ],
    );
  }
}