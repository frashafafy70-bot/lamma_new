// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:image_cropper/image_cropper.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'dart:convert'; 
import 'dart:io'; 
import 'package:http/http.dart' as http; 

// استيراد شاشات المنصة الشاملة
import '../legal/presentation/pages/legal_services_page.dart';
import '../trips/presentation/pages/trips_services_page.dart';
import '../medical/medical_services_page.dart';
import '../auth/presentation/pages/login_page.dart'; 
import '../profile/edit_profile_page.dart'; 

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final Color primaryNavy = const Color(0xFF0F172A); 
  final Color goldAccent = const Color(0xFFD4AF37); 

  int _bottomNavIndex = 0;
  final ImagePicker picker = ImagePicker();
  final String cloudVisionApiKey = 'AIzaSyC7LVnuJ5QfXCAKjse-EbDxvKZITRa75AM';

  String _searchQuery = '';
  final List<Map<String, dynamic>> _allServices = [
    {'title': 'الاستشارات القانونية', 'subtitle': 'محامون، قضايا، استشارات', 'icon': Icons.gavel_rounded, 'color': Colors.amber, 'type': 'legal'},
    {'title': 'حاسبة المواريث', 'subtitle': 'الفرز الشرعي للتركات', 'icon': Icons.calculate_rounded, 'color': Colors.amber, 'type': 'legal'},
    {'title': 'صياغة العقود', 'subtitle': 'بيع، إيجار، شركات', 'icon': Icons.edit_document, 'color': Colors.amber, 'type': 'legal'},
    {'title': 'الخدمات الطبية', 'subtitle': 'أطباء، تمريض، رعاية', 'icon': Icons.medical_services_rounded, 'color': Colors.green, 'type': 'medical'},
    {'title': 'حجز مشوار (تاكسي)', 'subtitle': 'توصيل رحلات آمنة', 'icon': Icons.local_taxi_rounded, 'color': Colors.blue, 'type': 'trips'},
    {'title': 'الخدمات العامة', 'subtitle': 'صيانة، تنظيف، أخرى', 'icon': Icons.dashboard_customize_rounded, 'color': Colors.purple, 'type': 'general'},
  ];

  String _userName = 'جاري التحميل...';
  String _userEmail = '';
  String _profileImageUrl = '';
  String _activeRole = 'customer'; // 🟢 الوضع الافتراضي
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userEmail = user.email ?? '';
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          var data = doc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              _userName = data['name'] ?? 'مستخدم لَمَّة';
              _profileImageUrl = data.containsKey('profileImage') ? data['profileImage'] : '';
              _activeRole = data.containsKey('activeRole') ? data['activeRole'] : 'customer';
              _isLoadingProfile = false;
            });
          }
        } else {
           if (mounted) setState(() => _isLoadingProfile = false);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingProfile = false;
          });
        }
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context, 
      MaterialPageRoute(builder: (context) => const LoginPage()), 
      (route) => false
    );
  }

  Future<CroppedFile?> _cropDocumentImage(String path, String title) async {
    return await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title,
          toolbarColor: primaryNavy,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          activeControlsWidgetColor: goldAccent,
        ),
        IOSUiSettings(
          title: title,
        ),
      ],
    );
  }

  Future<void> _sendPasswordResetEmail() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: goldAccent)));
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (!mounted) return;
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رابط تغيير كلمة المرور 📧', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    }
  }

  void _confirmPasswordReset() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(textDirection: TextDirection.rtl, children: [Icon(Icons.lock_reset_rounded, color: primaryNavy), const SizedBox(width: 8), const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))]),
        content: const Text('هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14), textDirection: TextDirection.rtl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white), onPressed: () async { Navigator.pop(ctx); _sendPasswordResetEmail(); }, child: const Text('إرسال الرابط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)))
        ],
      )
    );
  }

  void _showSupportDialog() {
    final TextEditingController complaintCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(textDirection: TextDirection.rtl, children: [const Icon(Icons.support_agent_rounded, color: Colors.orange), const SizedBox(width: 8), const Text('الدعم الفني والشكاوى', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16))]),
        content: TextField(
          controller: complaintCtrl, maxLines: 4, textDirection: TextDirection.rtl,
          decoration: InputDecoration(hintText: 'اكتب شكوتك، مشكلتك، أو مقترحك هنا...', hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white),
            onPressed: () async {
              if (complaintCtrl.text.trim().isEmpty) return;
              Navigator.pop(ctx);
              showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: goldAccent)));
              try {
                User? user = FirebaseAuth.instance.currentUser;
                await FirebaseFirestore.instance.collection('support_tickets').add({'uid': user?.uid, 'name': _userName, 'email': _userEmail, 'message': complaintCtrl.text.trim(), 'status': 'open', 'timestamp': FieldValue.serverTimestamp()});
                if (!mounted) return;
                Navigator.pop(context); 
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رسالتك للدعم الفني بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
              } catch(e) {
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال ❌', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
              }
            }, 
            child: const Text('إرسال الدعم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold))
          )
        ],
      )
    );
  }

  Future<bool> _analyzeImageWithCloudVision(String imagePath, List<String> requiredKeywords) async {
    try {
      List<int> imageBytes = await File(imagePath).readAsBytes();
      String base64Image = base64Encode(imageBytes);
      var requestBody = { "requests": [{"image": {"content": base64Image}, "features": [{"type": "TEXT_DETECTION"}], "imageContext": {"languageHints": ["ar"]}}] };
      var response = await http.post(Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$cloudVisionApiKey'), headers: {"Content-Type": "application/json"}, body: jsonEncode(requestBody));
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        var responses = jsonResponse['requests'] ?? [];
        if (responses.isNotEmpty && responses[0].containsKey('fullTextAnnotation')) {
          String extractedText = responses[0]['fullTextAnnotation']['text'].toLowerCase();
          return requiredKeywords.any((keyword) => extractedText.contains(keyword));
        }
      }
      return false; 
    } catch (e) {
      return false; 
    }
  }

  Future<String?> _uploadDocumentToStorage({required String uid, required String role, required String docName, required File file}) async {
    try {
      Reference ref = FirebaseStorage.instance.ref().child('users').child(uid).child('documents').child(role).child('$docName.jpg');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  Future<void> _pickValidateAndCropImage(BuildContext context, StateSetter setModalState, Function(File?) onValidImage, List<String> keywords, String cropTitle) async {
    try {
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🤖 جاري فحص المستند سحابياً...'), duration: Duration(seconds: 2)));
        
        bool isValid = await _analyzeImageWithCloudVision(pickedFile.path, keywords);
        
        if (!isValid) {
          if (!context.mounted) return;
          bool? proceedAnyway = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('تنبيه فحص المستند ⚠️', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')),
              content: const Text('الذكاء الاصطناعي لم يتعرف على الكارنيه. هل تريد إكمال الرفع للمراجعة اليدوية؟', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: primaryNavy), child: const Text('نعم، المتابعة', style: TextStyle(color: Colors.white))),
              ],
            )
          );
          if (proceedAnyway != true) return;
        }

        CroppedFile? cropped = await _cropDocumentImage(pickedFile.path, cropTitle);
        if (cropped != null) {
          setModalState(() {
            onValidImage(File(cropped.path));
          });
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم إرفاق المستند بنجاح.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في جلب المستند')));
    }
  }

  Widget _buildFileImageButton(String title, File? file, VoidCallback onTap) {
    bool isUploaded = file != null;
    return Expanded(
      child: InkWell(
        onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isUploaded ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade100,
            border: Border.all(color: isUploaded ? Colors.green : Colors.grey.shade300, width: 1.5),
            borderRadius: BorderRadius.circular(12)
          ),
          child: Column(
            children: [
              Icon(isUploaded ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: isUploaded ? Colors.green : Colors.grey.shade600, size: 24),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isUploaded ? Colors.green : Colors.black87, fontFamily: 'Cairo')),
            ],
          ),
        ),
      ),
    );
  }

  // 🟢 التحويل الديناميكي بين المهن اللحظي
  Future<void> _switchUserRole(String newRole) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: goldAccent)));

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      String fullName = userData['name'] ?? 'مستخدم';
      bool hasProfile = userData.containsKey('profiles') && (userData['profiles'] as Map).containsKey(newRole);

      // إذا كان المستخدم لا يملك هذا الملف الشخصي، نفتح نموذج التسجيل الخاص بالمهنة
      if (!hasProfile && newRole != 'customer') {
        if (mounted) {
          Navigator.pop(context); // إغلاق مؤشر التحميل
          Navigator.pop(context); // إغلاق القائمة الجانبية (Drawer)
          if (newRole == 'captain') {
            _showCaptainRegistration(user.uid, fullName);
          } else if (newRole == 'lawyer') {
            _showLawyerRegistration(user.uid, fullName);
          } else if (newRole == 'doctor') {
            _showDoctorRegistration(user.uid, fullName);
          } else if (newRole == 'nurse') {
            _showNurseRegistration(user.uid, fullName);
          }
        }
        return; 
      }

      // إذا كان يملك الملف الشخصي، نقوم بتحديث الدور النشط في فايرستور
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'activeRole': newRole}, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context); // إغلاق مؤشر التحميل
      Navigator.pop(context); // إغلاق الـ Drawer

      // 🟢 التحديث اللحظي للواجهة داخل نفس الصفحة
      setState(() {
        _activeRole = newRole;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم التحويل لوضع: $newRole بنجاح ✅', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green)
      );
      
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo'))));
      }
    }
  }

  // ==========================================
  // 🚖 1. تسجيل الكابتن (رخص وش وضهر)
  // ==========================================
  void _showCaptainRegistration(String uid, String fullName) {
    final vehicleController = TextEditingController();
    final plateController = TextEditingController();
    File? carLicenseFront, carLicenseBack, personalIdFront, personalIdBack;

    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl, 
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.local_taxi_rounded, size: 50, color: Colors.green),
                    const SizedBox(height: 12),
                    const Text('تفعيل حساب الكابتن', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    const SizedBox(height: 24),
                    TextField(controller: vehicleController, decoration: InputDecoration(labelText: 'نوع السيارة', prefixIcon: const Icon(Icons.directions_car_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    TextField(controller: plateController, decoration: InputDecoration(labelText: 'رقم اللوحة', prefixIcon: const Icon(Icons.pin_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),
                    const Text('رخصة المركبة (وش وضهر)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Row(children: [
                      _buildFileImageButton('الوجه الأمامي', carLicenseFront, () => _pickValidateAndCropImage(context, setModalState, (f) => carLicenseFront = f, ['رخصة', 'المرور'], 'تعديل صورة رخصة السيارة')),
                      const SizedBox(width: 12),
                      _buildFileImageButton('الوجه الخلفي', carLicenseBack, () => _pickValidateAndCropImage(context, setModalState, (f) => carLicenseBack = f, ['وزارة', 'فحص', 'تأمين'], 'تعديل صورة رخصة السيارة')),
                    ]),
                    const SizedBox(height: 20),
                    const Text('الرخصة الشخصية (وش وضهر)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Row(children: [
                      _buildFileImageButton('الوجه الأمامي', personalIdFront, () => _pickValidateAndCropImage(context, setModalState, (f) => personalIdFront = f, ['بطاقة', 'رقم', 'قومي', 'قيادة'], 'تعديل صورة الرخصة الشخصية')),
                      const SizedBox(width: 12),
                      _buildFileImageButton('الوجه الخلفي', personalIdBack, () => _pickValidateAndCropImage(context, setModalState, (f) => personalIdBack = f, ['الرقم', 'مهنة', 'مرور'], 'تعديل صورة الرخصة الشخصية')),
                    ]),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (vehicleController.text.isEmpty || plateController.text.isEmpty || carLicenseFront == null || carLicenseBack == null || personalIdFront == null || personalIdBack == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('برجاء استكمال البيانات والمرفقات!'))); 
                          return;
                        }
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.green)));
                        String? carFrontUrl = await _uploadDocumentToStorage(uid: uid, role: 'captain', docName: 'car_license_front', file: carLicenseFront!);
                        String? carBackUrl = await _uploadDocumentToStorage(uid: uid, role: 'captain', docName: 'car_license_back', file: carLicenseBack!);
                        String? idFrontUrl = await _uploadDocumentToStorage(uid: uid, role: 'captain', docName: 'personal_id_front', file: personalIdFront!);
                        String? idBackUrl = await _uploadDocumentToStorage(uid: uid, role: 'captain', docName: 'personal_id_back', file: personalIdBack!);
                        String secretName = 'كابتن ${fullName.trim().split(' ').first}';

                        await FirebaseFirestore.instance.collection('users').doc(uid).set({
                          'activeRole': 'captain', 'roles': FieldValue.arrayUnion(['captain']),
                          'profiles': {
                            'captain': {
                              'displayName': secretName, 'vehicle': vehicleController.text, 'plate': plateController.text, 'isVerified': true, 'rating': 5.0,
                              'carLicenseFrontUrl': carFrontUrl, 'carLicenseBackUrl': carBackUrl, 'personalIdFrontUrl': idFrontUrl, 'personalIdBackUrl': idBackUrl,
                            }
                          }
                        }, SetOptions(merge: true));

                        if (!context.mounted) return;
                        Navigator.pop(context); 
                        Navigator.pop(sheetContext); 
                        setState(() => _activeRole = 'captain'); // التحديث اللحظي للواجهة
                      },
                      child: const Text('بدء العمل', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // ==========================================
  // ⚖️ 2. تسجيل المحامي (وجه واحد)
  // ==========================================
  void _showLawyerRegistration(String uid, String fullName) {
    final degreeController = TextEditingController();
    final registrationNumController = TextEditingController();
    File? barIdFront;

    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl, 
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.gavel_rounded, size: 50, color: goldAccent),
                    const SizedBox(height: 12),
                    const Text('اعتماد حساب المحامي ⚖️', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    const SizedBox(height: 24),
                    TextField(controller: degreeController, decoration: InputDecoration(labelText: 'درجة القيد', prefixIcon: const Icon(Icons.school_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    TextField(controller: registrationNumController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'رقم القيد بالنقابة', prefixIcon: const Icon(Icons.numbers_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),
                    const Text('كارنيه نقابة المحامين (الوجه الأمامي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Row(children: [
                      _buildFileImageButton('إرفاق صورة الكارنيه', barIdFront, () => _pickValidateAndCropImage(context, setModalState, (f) => barIdFront = f, ['نقابة', 'المحامين', 'محام'], 'تعديل وقص صورة الكارنيه')),
                    ]),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (degreeController.text.isEmpty || registrationNumController.text.isEmpty || barIdFront == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('برجاء استكمال البيانات وكارنيه النقابة!'))); 
                          return;
                        }
                        showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: goldAccent)));
                        String? lawyerFrontUrl = await _uploadDocumentToStorage(uid: uid, role: 'lawyer', docName: 'bar_id_front', file: barIdFront!);
                        String formalName = 'الأستاذ / $fullName'; 

                        await FirebaseFirestore.instance.collection('users').doc(uid).set({
                          'activeRole': 'lawyer', 'roles': FieldValue.arrayUnion(['lawyer']), 
                          'profiles': {
                            'lawyer': {
                              'displayName': formalName, 'degree': degreeController.text, 'registrationNumber': registrationNumController.text, 'isVerified': true, 'barIdFrontUrl': lawyerFrontUrl,
                            }
                          }
                        }, SetOptions(merge: true));

                        if (!context.mounted) return;
                        Navigator.pop(context); 
                        Navigator.pop(sheetContext); 
                        setState(() => _activeRole = 'lawyer'); // التحديث اللحظي للواجهة
                      },
                      child: const Text('تفعيل الحساب القانوني', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // ==========================================
  // 👨‍⚕️ 3. تسجيل الطبيب (وجه واحد)
  // ==========================================
  void _showDoctorRegistration(String uid, String fullName) {
    final specialtyController = TextEditingController();
    final licenseController = TextEditingController();
    File? medicalIdFront;

    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl, 
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.medical_services_rounded, size: 50, color: Colors.teal),
                    const SizedBox(height: 12),
                    const Text('اعتماد حساب الطبيب 👨‍⚕️', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    const SizedBox(height: 24),
                    TextField(controller: specialtyController, decoration: InputDecoration(labelText: 'التخصص', prefixIcon: const Icon(Icons.healing_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    TextField(controller: licenseController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'رقم ترخيص مزاولة المهنة', prefixIcon: const Icon(Icons.assignment_ind_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),
                    const Text('كارنيه نقابة الأطباء (الوجه الأمامي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Row(children: [
                      _buildFileImageButton('إرفاق صورة الكارنيه', medicalIdFront, () => _pickValidateAndCropImage(context, setModalState, (f) => medicalIdFront = f, ['نقابة', 'الأطباء', 'طبيب'], 'تعديل وقص صورة الكارنيه')),
                    ]),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (specialtyController.text.isEmpty || licenseController.text.isEmpty || medicalIdFront == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('برجاء استكمال البيانات والكارنيه!'))); 
                          return;
                        }
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.teal)));
                        String? doctorFrontUrl = await _uploadDocumentToStorage(uid: uid, role: 'doctor', docName: 'medical_id_front', file: medicalIdFront!);
                        String formalName = 'دكتور / $fullName'; 

                        await FirebaseFirestore.instance.collection('users').doc(uid).set({
                          'activeRole': 'doctor', 'roles': FieldValue.arrayUnion(['doctor']), 
                          'profiles': {
                            'doctor': {
                              'displayName': formalName, 'specialty': specialtyController.text, 'licenseNumber': licenseController.text, 'isVerified': true, 'medicalIdFrontUrl': doctorFrontUrl,
                            }
                          }
                        }, SetOptions(merge: true));

                        if (!context.mounted) return;
                        Navigator.pop(context); 
                        Navigator.pop(sheetContext); 
                        setState(() => _activeRole = 'doctor'); // التحديث اللحظي للواجهة
                      },
                      child: const Text('تفعيل الحساب الطبي', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // ==========================================
  // 🩺 4. تسجيل التمريض (وجه واحد)
  // ==========================================
  void _showNurseRegistration(String uid, String fullName) {
    final qualificationController = TextEditingController(); 
    final nurseLicenseController = TextEditingController(); 
    File? nurseIdFront;

    showModalBottomSheet(
      context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl, 
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.health_and_safety_rounded, size: 50, color: Colors.blue),
                    const SizedBox(height: 12),
                    const Text('اعتماد حساب التمريض 🩺', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Text('يرجى إرفاق كارنيه نقابة التمريض لتوثيق حسابك في لَمَّة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontFamily: 'Cairo')),
                    const SizedBox(height: 24),
                    TextField(controller: qualificationController, decoration: InputDecoration(labelText: 'المؤهل (أخصائي / فني تمريض)', prefixIcon: const Icon(Icons.assignment_rounded), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 16),
                    TextField(controller: nurseLicenseController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'رقم ترخيص / قيد النقابة', prefixIcon: const Icon(Icons.pin_outlined), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),
                    const Text('كارنيه نقابة التمريض (الوجه الأمامي)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Row(children: [
                      _buildFileImageButton('إرفاق صورة الكارنيه', nurseIdFront, () => _pickValidateAndCropImage(context, setModalState, (f) => nurseIdFront = f, ['نقابة', 'التمريض', 'ممرض', 'أخصائي'], 'تعديل وقص صورة الكارنيه')),
                    ]),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      onPressed: () async {
                        if (qualificationController.text.isEmpty || nurseLicenseController.text.isEmpty || nurseIdFront == null) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('برجاء استكمال البيانات وكارنيه نقابة التمريض!'))); 
                          return;
                        }
                        showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator(color: Colors.blue)));
                        String? nurseFrontUrl = await _uploadDocumentToStorage(uid: uid, role: 'nurse', docName: 'nurse_id_front', file: nurseIdFront!);
                        String formalName = 'ممرض(ة) / $fullName'; 

                        await FirebaseFirestore.instance.collection('users').doc(uid).set({
                          'activeRole': 'nurse', 'roles': FieldValue.arrayUnion(['nurse']), 
                          'profiles': {
                            'nurse': {
                              'displayName': formalName, 'qualification': qualificationController.text, 'licenseNumber': nurseLicenseController.text, 'isVerified': true, 'nurseIdFrontUrl': nurseFrontUrl,
                            }
                          }
                        }, SetOptions(merge: true));

                        if (!context.mounted) return;
                        Navigator.pop(context); 
                        Navigator.pop(sheetContext); 
                        setState(() => _activeRole = 'nurse'); // التحديث اللحظي للواجهة
                      },
                      child: const Text('تفعيل حساب التمريض', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  // ==========================================
  // الشاشات الرئيسية الأربعة بالواجهة الديناميكية
  // ==========================================
  
  Widget _buildHomeView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [primaryNavy, const Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            border: Border(bottom: BorderSide(color: goldAccent, width: 4.5)),
            boxShadow: [BoxShadow(color: goldAccent.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 5))],
          ),
          child: Stack(
            children: [
              Positioned(right: -30, top: -20, child: Icon(Icons.mosque_rounded, size: 180, color: Colors.white.withValues(alpha: 0.03))),
              Positioned(left: -40, bottom: -30, child: Icon(Icons.brightness_high_rounded, size: 150, color: Colors.white.withValues(alpha: 0.03))),
              Positioned(right: 100, bottom: -10, child: Icon(Icons.star_outline_rounded, size: 80, color: Colors.white.withValues(alpha: 0.03))),
              Padding(
                padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 16, bottom: 35, left: 20, right: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Builder(
                          builder: (ctx) => IconButton(
                            icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
                            onPressed: () => Scaffold.of(ctx).openDrawer(),
                          ),
                        ),
                        Row(
                          children: [
                            const Text('منصة لَمَّة الشاملة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            const SizedBox(width: 8),
                            Icon(Icons.grid_view_rounded, color: goldAccent, size: 24),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 26),
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا توجد إشعارات جديدة 🔔', style: TextStyle(fontFamily: 'Cairo'))));
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 25),
                    Text('مرحباً بك يا $_userName،', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    // 🟢 تتغير الرسالة الترحيبية حسب الوضع الحالي للمستخدم
                    Text(
                      _activeRole == 'customer' ? 'كل خدماتك في مكان واحد 🚀' : 'لوحة تحكم المحترفين جاهزة 💼', 
                      textAlign: TextAlign.center, 
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.count(
            padding: const EdgeInsets.only(top: 24, left: 20, right: 20, bottom: 20),
            crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9, 
            children: [
              _buildServiceSquare(
                title: 'الاستشارات القانونية', subtitle: 'محامون معتمدون، حاسبات', icon: Icons.gavel_rounded, iconColor: goldAccent, 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LegalServicesPage(isLawyer: _activeRole == 'lawyer')))
              ),
              _buildServiceSquare(
                title: 'الخدمات الطبية', subtitle: 'استشارات طبية، ورعاية صحية', icon: Icons.medical_services_rounded, iconColor: Colors.green.shade600, 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalServicesPage(medicalRole: (_activeRole == 'doctor' || _activeRole == 'nurse') ? 'provider' : 'patient')))
              ),
              _buildServiceSquare(
                title: 'التوصيل الذكي (لَمَّة)', subtitle: 'رحلات، وتوصيل طلبات', icon: Icons.local_taxi_rounded, iconColor: Colors.blue.shade600, 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TripsServicesPage(isDriver: _activeRole == 'captain')))
              ),
              _buildServiceSquare(
                title: 'الخدمات العامة', subtitle: 'خدمات منوعة تناسبك', icon: Icons.dashboard_customize_rounded, iconColor: Colors.purple.shade500, 
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريباً 🛠️', style: TextStyle(fontFamily: 'Cairo'))))
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchView() {
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
                            Navigator.push(context, MaterialPageRoute(builder: (_) => LegalServicesPage(isLawyer: _activeRole == 'lawyer')));
                          } else if (item['type'] == 'medical') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => MedicalServicesPage(medicalRole: (_activeRole == 'doctor' || _activeRole == 'nurse') ? 'provider' : 'patient')));
                          } else if (item['type'] == 'trips') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => TripsServicesPage(isDriver: _activeRole == 'captain')));
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

  // 🟢 الاستماع الديناميكي (Dynamic Listener) المدمج بالكامل هنا 
  Widget _buildOrdersView() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    
    // بناء الاستعلام بناءً على وضع المستخدم النشط حالياً
    Stream<QuerySnapshot> ordersStream;
    if (_activeRole == 'lawyer') {
      ordersStream = FirebaseFirestore.instance.collection('legal_requests').orderBy('timestamp', descending: true).snapshots();
    } else {
      ordersStream = FirebaseFirestore.instance.collection('legal_requests').where('clientId', isEqualTo: userId).snapshots();
    }

    return Column(
      children: [
        Container(
          width: double.infinity, padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20, bottom: 20),
          decoration: BoxDecoration(color: primaryNavy, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(25))),
          // العنوان يتغير ديناميكياً
          child: Text(
            _activeRole == 'lawyer' ? 'طلبات العملاء الواردة ⚖️' : 'متابعة طلباتي 📜', 
            textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text('ليس لديك أي طلبات حالية.', style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ],
                  ),
                );
              }
              
              var docs = snapshot.data!.docs;
              
              // ترتيب إضافي في حال كان الـ query لا يدعم orderBy بسبب عدم وجود Indexes
              if (_activeRole != 'lawyer') {
                docs.sort((a, b) => (b['timestamp'] as Timestamp?)?.compareTo(a['timestamp'] as Timestamp? ?? Timestamp.now()) ?? 0);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  var data = docs[index].data() as Map<String, dynamic>;
                  String type = data['serviceType'] ?? 'طلب خدمة';
                  String status = data['status'] ?? 'pending';
                  String details = data['details'] ?? '';
                  String clientName = data['clientName'] ?? 'عميل غير معروف';
                  
                  return Card(
                    elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(type, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryNavy, fontFamily: 'Cairo')),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: status == 'completed' ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text(status == 'completed' ? 'تم الرد' : 'قيد المراجعة', style: TextStyle(color: status == 'completed' ? Colors.green : Colors.orange, fontWeight: FontWeight.bold, fontSize: 12, fontFamily: 'Cairo')),
                              )
                            ],
                          ),
                          // إظهار اسم العميل للمحامي فقط
                          if (_activeRole == 'lawyer') ...[
                            const SizedBox(height: 4),
                            Text('مُقدم الطلب: $clientName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Cairo')),
                          ],
                          const Divider(),
                          Text(details, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontFamily: 'Cairo')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProfileView() {
    if (_isLoadingProfile) {
      return Center(child: CircularProgressIndicator(color: primaryNavy));
    }

    return Column(
      children: [
        Container(
          width: double.infinity, 
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 30, bottom: 40, left: 20, right: 20),
          decoration: BoxDecoration(
            color: primaryNavy, 
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
            boxShadow: [BoxShadow(color: primaryNavy.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 5))]
          ),
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldAccent, width: 2)), 
                    child: CircleAvatar(
                      radius: 50, backgroundColor: Colors.white, 
                      backgroundImage: _profileImageUrl.isNotEmpty ? NetworkImage(_profileImageUrl) : null,
                      child: _profileImageUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.grey) : null,
                    )
                  ),
                  InkWell(
                    onTap: () async {
                      await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()));
                      _loadUserProfile(); 
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: goldAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Text(_userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              const SizedBox(height: 4),
              Text(_userEmail, style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontFamily: 'Cairo')),
            ],
          ),
        ),
        
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('إعدادات الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              
              _buildListTile(
                icon: Icons.person_outline_rounded, color: primaryNavy, title: 'تعديل البيانات الشخصية', 
                onTap: () async {
                  await Navigator.push(context, MaterialPageRoute(builder: (_) =>  EditProfilePage()));
                  _loadUserProfile(); 
                }
              ),
              _buildListTile(icon: Icons.lock_outline_rounded, color: Colors.blueAccent, title: 'تغيير كلمة المرور', onTap: _confirmPasswordReset),
              _buildListTile(icon: Icons.location_on_outlined, color: Colors.green, title: 'العناوين المحفوظة', onTap: () {}),
              
              const SizedBox(height: 24),
              const Text('المساعدة والدعم', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
              const SizedBox(height: 16),
              
              _buildListTile(icon: Icons.support_agent_rounded, color: Colors.orange, title: 'الدعم الفني والشكاوى', onTap: _showSupportDialog),
              
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade50, foregroundColor: Colors.red, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                icon: const Icon(Icons.logout_rounded), label: const Text('تسجيل الخروج من المنصة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildListTile({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade100)),
      child: ListTile(
        leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildServiceSquare({required String title, required String subtitle, required IconData icon, required Color iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 5))], border: Border.all(color: Colors.grey.shade100, width: 1)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, size: 36, color: iconColor)),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 8.0), child: Text(subtitle, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontFamily: 'Cairo'))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_bottomNavIndex) {
      case 0: 
        bodyContent = _buildHomeView(); 
        break;
      case 1: 
        bodyContent = _buildSearchView(); 
        break;
      case 2: 
        bodyContent = _buildOrdersView(); 
        break;
      case 3: 
        bodyContent = _buildProfileView(); 
        break;
      default: 
        bodyContent = _buildHomeView();
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      
      drawer: Directionality(
        textDirection: TextDirection.rtl,
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: primaryNavy), 
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, 
                  mainAxisAlignment: MainAxisAlignment.center, 
                  children: [
                    Icon(Icons.account_circle, size: 60, color: goldAccent), 
                    const SizedBox(height: 10), 
                    const Text('تبديل وضع الحساب', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')), 
                    Text('الوضع الحالي: ${_activeRole == 'customer' ? 'عميل' : _activeRole == 'lawyer' ? 'محامي' : _activeRole == 'captain' ? 'كابتن' : 'مقدم خدمة'}', style: TextStyle(color: Colors.grey.shade400, fontSize: 14, fontFamily: 'Cairo'))
                  ]
                )
              ),
              ListTile(leading: const Icon(Icons.person_rounded, color: Colors.grey), title: const Text('التحويل لوضع العميل 👤', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('customer')),
              ListTile(leading: const Icon(Icons.local_taxi_rounded, color: Colors.blueAccent), title: const Text('التحويل لوضع الكابتن 🚖', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('captain')),
              ListTile(leading: Icon(Icons.gavel_rounded, color: goldAccent), title: const Text('التحويل لوضع المحامي ⚖️', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('lawyer')),
              ListTile(leading: const Icon(Icons.medical_services_rounded, color: Colors.green), title: const Text('التحويل لوضع الطبيب 👨‍⚕️', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('doctor')),
              ListTile(leading: const Icon(Icons.health_and_safety_rounded, color: Colors.blue), title: const Text('التحويل لوضع التمريض 🩺', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), onTap: () => _switchUserRole('nurse')),
            ],
          ),
        ),
      ),

      body: Directionality(
        textDirection: TextDirection.rtl,
        child: bodyContent,
      ),

      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))]),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: BottomNavigationBar(
              currentIndex: _bottomNavIndex,
              onTap: (index) {
                setState(() {
                  _bottomNavIndex = index; 
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: goldAccent,
              unselectedItemColor: Colors.grey.shade400,
              selectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 11),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'الرئيسية'),
                BottomNavigationBarItem(icon: Icon(Icons.search_rounded), label: 'البحث'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'الطلبات'),
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'الحساب'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}