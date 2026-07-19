import 'package:flutter/material.dart';

class MedicalServicesPage extends StatefulWidget {
  final String medicalRole; // 'patient' للمريض، أو 'provider' للطبيب/التمريض
  final String? medicalName;
  final String? medicalSpecialty;

  const MedicalServicesPage({
    super.key,
    required this.medicalRole,
    this.medicalName,
    this.medicalSpecialty,
  });

  @override
  State<MedicalServicesPage> createState() => _MedicalServicesPageState();
}

class _MedicalServicesPageState extends State<MedicalServicesPage> {
  String _activeCategory = 'عيادات خاصة';

  // 🩺 قاعدة البيانات المحلية للأطباء
  final List<Map<String, String>> _doctors = [
    {
      'name': 'د. محمود الشربيني',
      'spec': 'أخصائي باطنة وقلب',
      'loc': 'ميت سلسيل - أمام المحطة',
      'time': '٧ م - ١٠ م'
    },
    {
      'name': 'د. أحمد السعيد البرعي',
      'spec': 'أخصائي طب الأطفال وحديثي الولادة',
      'loc': 'المنصورة - المشاية السفلية',
      'time': '٣ م - ٨ م'
    },
  ];

  // 💊 قاعدة البيانات المحلية للصيدليات
  final List<Map<String, String>> _pharmacies = [
    {
      'name': 'صيدلية الشفاء',
      'loc': 'ميت سلسيل - الشارع الرئيسي',
      'status': 'مفتوح ٢٤ ساعة 🌙'
    },
    {
      'name': 'صيدلية العدالة الرقمية',
      'loc': 'المنصورة - خلف المحكمة',
      'status': 'مفتوح حتى ٢ فجراً'
    },
  ];

  // 💉 قاعدة البيانات المحلية للتمريض
  final List<Map<String, String>> _nurses = [
    {
      'name': 'الأخصائي/ محمد سعد',
      'desc': 'تمريض منزلي، تركيب محاليل ورعاية حثيثة',
      'loc': 'متاح زيارات بميت سلسيل والمراكز المجاورة'
    },
    {
      'name': 'الممرضة/ سارة أحمد',
      'desc': 'رعاية مسنين وغيار جراحي معقم بالكامل',
      'loc': 'متاحة بالمنصورة وضواحيها'
    },
  ];

  // 🔘 زر القائمة الجانبية
  Widget _buildSideMenuButton(String name, IconData icon) {
    bool isSelected = _activeCategory == name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Colors.red[800] : Colors.white,
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          elevation: isSelected ? 2 : 0,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.grey[200]!)),
        ),
        onPressed: () => setState(() => _activeCategory = name),
        icon: Icon(icon,
            size: 22, color: isSelected ? Colors.white : Colors.red[800]),
        label: Text(name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  // 🃏 كارت عرض تفاصيل الخدمة الطبية
  Widget _buildMedicalCard(
      {required String title,
      required String subtitle,
      required String footer,
      required IconData icon}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
            backgroundColor: Colors.red[50],
            radius: 26,
            child: Icon(icon, color: Colors.red[800], size: 28)),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'Cairo')),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(subtitle,
              style: TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: Colors.grey.shade700,
                  fontFamily: 'Cairo')),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Text(footer,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[900],
                  fontFamily: 'Cairo')),
        ),
      ),
    );
  }

  // 📋 تحديد القائمة النشطة (تم حل مشكلة String Interpolation هنا) 🟢
  Widget _buildActiveList() {
    if (_activeCategory == 'عيادات خاصة') {
      return Column(
          children: _doctors
              .map((d) => _buildMedicalCard(
                  title: d['name']!,
                  subtitle: '${d['spec']}\n${d['loc']}',
                  footer: d['time']!,
                  icon: Icons.medical_services_rounded))
              .toList());
    } else if (_activeCategory == 'صيدليات') {
      return Column(
          children: _pharmacies
              .map((p) => _buildMedicalCard(
                  title: p['name']!,
                  subtitle: p['loc']!,
                  footer: p['status']!,
                  icon: Icons.local_pharmacy_rounded))
              .toList());
    } else {
      return Column(
          children: _nurses
              .map((n) => _buildMedicalCard(
                  title: n['name']!,
                  subtitle: '${n['desc']}\n${n['loc']}',
                  footer: 'طلب زيارة 📞',
                  icon: Icons.medical_information_rounded))
              .toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    bool hasMedicalAccount = widget.medicalRole == 'provider' ||
        'طبيب صيدلي ممرض/ة'.contains(widget.medicalRole);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('بوابة الرعاية الطبية والصحية',
            style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
        backgroundColor: Colors.red[800],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('الخدمات والمنشآت',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                            fontFamily: 'Cairo')),
                    const SizedBox(height: 16),
                    _buildSideMenuButton('عيادات خاصة', Icons.healing_rounded),
                    _buildSideMenuButton(
                        'صيدليات', Icons.local_pharmacy_rounded),
                    _buildSideMenuButton(
                        'تمريض', Icons.medical_services_rounded),
                    const Spacer(),
                    if (hasMedicalAccount)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!)),
                        child: Column(
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.green[700], size: 28),
                            const SizedBox(height: 8),
                            Text(
                              'حساب طبي نشط\nبمنشأة: ${widget.medicalName ?? 'لَمَّة للرعاية'}',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green[900],
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Cairo'),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ),
              VerticalDivider(
                  width: 32, color: Colors.grey[300], thickness: 1.5),
              Expanded(
                flex: 5,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.red.shade100)),
                        child: Row(
                          children: [
                            Icon(Icons.category_rounded,
                                color: Colors.red[800]),
                            const SizedBox(width: 12),
                            Text('دليل قسم: $_activeCategory',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontFamily: 'Cairo')),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildActiveList(),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
