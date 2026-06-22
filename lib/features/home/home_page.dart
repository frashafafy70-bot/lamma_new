// ignore_for_file: use_build_context_synchronously, curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:image_cropper/image_cropper.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'dart:convert'; 
import 'dart:io'; 
import 'package:http/http.dart' as http; 

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../auth/presentation/pages/login_page.dart'; 
import '../profile/edit_profile_page.dart'; 

import 'views/home_main_view.dart';
import 'views/search_view.dart';
import 'views/orders_view.dart';
import 'views/profile_view.dart';

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
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  String _userName = 'جاري التحميل...';
  String _userEmail = '';
  String _profileImageUrl = '';
  String _activeRole = 'customer'; 
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _setupNotificationsWithSound();
  }

  Future<void> _setupNotificationsWithSound() async {
    // 1. طلب صلاحيات الإشعارات والصوت للـ iOS والـ Android
    await FirebaseMessaging.instance.requestPermission(
      alert: true, 
      badge: true, 
      sound: true, 
      provisional: false,
    );
    
    // 2. تعريف قنوات الإشعارات للأندرويد
    const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
      'lamma_high_importance_channel', 
      'إشعارات لَمَّة الهامة', 
      description: 'هذه القناة مخصصة للإشعارات التي تتطلب تنبيهاً صوتياً.', 
      importance: Importance.max, 
      playSound: true,
    );

    const AndroidNotificationChannel finalSoundChannel = AndroidNotificationChannel(
      'lamma_final_sound',
      'تنبيهات لمة الفورية',
      description: 'قناة الرحلات العاجلة',
      importance: Importance.max,
      playSound: true,
    );

    // تسجيل القنوات داخل النظام
    final androidPlugin = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(highImportanceChannel);
      await androidPlugin.createNotificationChannel(finalSoundChannel);
    }

    // تعيين خيارات العرض الأمامي للإشعارات
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, 
      badge: true, 
      sound: true,
    );

    // 3. تهيئة المكون الإضافي للإشعارات المحلية
    const InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'), 
      iOS: DarwinInitializationSettings(
        requestSoundPermission: true, 
        requestBadgePermission: true, 
        requestAlertPermission: true,
      ),
    );
    
    // تم التصحيح النهائي: استخدام المعامل 'settings' كما يطلبه إصدار الحزمة لديك
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("✅ تم الضغط على الإشعار: ${response.payload}");
      },
    );

    // 4. الاستماع للإشعارات القادمة أثناء فتح التطبيق (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      
      if (notification != null && android != null) {
        String targetChannelId = message.data['channel_id'] ?? 'lamma_final_sound';
        String targetChannelName = targetChannelId == 'lamma_high_importance_channel' 
            ? 'إشعارات لَمَّة الهامة' 
            : 'تنبيهات لمة الفورية';

        flutterLocalNotificationsPlugin.show(
          id: notification.hashCode, 
          title: notification.title, 
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              targetChannelId, 
              targetChannelName, 
              channelDescription: 'قناة التنبيهات الفورية والرحلات العاجلة', 
              icon: '@mipmap/ic_launcher', 
              importance: Importance.max, 
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(presentSound: true),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });
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
          if (mounted) {
            setState(() => _isLoadingProfile = false);
          }
        }
      } catch (e) { 
        if (mounted) {
          setState(() => _isLoadingProfile = false);
        }
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
  }

  void _openNotifications() {
    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    showModalBottomSheet(
      context: context, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              Text('الإشعارات', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryNavy, fontFamily: 'Cairo')),
              const Divider(),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(userId).collection('notifications').orderBy('timestamp', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('لا توجد إشعارات حالياً 🔕', style: TextStyle(fontFamily: 'Cairo')));
                    }
                    return ListView.builder(
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var notif = snapshot.data!.docs[index];
                        if (notif['isRead'] == false) {
                          notif.reference.update({'isRead': true});
                        }
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: goldAccent.withValues(alpha: 0.2), 
                            child: Icon(Icons.notifications_active, color: goldAccent),
                          ), 
                          title: Text(notif['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), 
                          subtitle: Text(notif['body'] ?? '', style: const TextStyle(fontFamily: 'Cairo')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
      title: Row(
        textDirection: TextDirection.rtl, 
        children: [
          Icon(Icons.lock_reset_rounded, color: primaryNavy), 
          const SizedBox(width: 8), 
          const Text('تغيير كلمة المرور', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ],
      ), 
      content: const Text('هل تريد إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14), textDirection: TextDirection.rtl), 
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey))), 
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white), 
          onPressed: () async { 
            Navigator.pop(ctx); 
            _sendPasswordResetEmail(); 
          }, 
          child: const Text('إرسال الرابط', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  void _showSupportDialog() {
    final TextEditingController complaintCtrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), 
      title: Row(
        textDirection: TextDirection.rtl, 
        children: [
          const Icon(Icons.support_agent_rounded, color: Colors.orange), 
          const SizedBox(width: 8), 
          const Text('الدعم الفني والشكاوى', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ), 
      content: TextField(
        controller: complaintCtrl, 
        maxLines: 4, 
        textDirection: TextDirection.rtl, 
        decoration: InputDecoration(
          hintText: 'اكتب شكوتك، مشكلتك، أو مقترحك هنا...', 
          hintStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13), 
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), 
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryNavy, width: 2)),
        ),
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
              await FirebaseFirestore.instance.collection('support_tickets').add({
                'uid': user?.uid, 
                'name': _userName, 
                'email': _userEmail, 
                'message': complaintCtrl.text.trim(), 
                'status': 'open', 
                'timestamp': FieldValue.serverTimestamp(),
              }); 
              if (!mounted) return; 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال رسالتك للدعم الفني بنجاح ✅', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green)); 
            } catch(e) { 
              if (!mounted) return; 
              Navigator.pop(context); 
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء الإرسال ❌', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red)); 
            } 
          }, 
          child: const Text('إرسال الدعم', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      ],
    ));
  }

  Future<bool> _analyzeImageWithCloudVision(String imagePath, List<String> requiredKeywords) async { 
    try { 
      List<int> imageBytes = await File(imagePath).readAsBytes(); 
      String base64Image = base64Encode(imageBytes); 
      var requestBody = { 
        "requests": [{
          "image": {"content": base64Image}, 
          "features": [{"type": "TEXT_DETECTION"}], 
          "imageContext": {"languageHints": ["ar"]}
        }] 
      }; 
      var response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$cloudVisionApiKey'), 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode(requestBody),
      ); 
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
        IOSUiSettings(title: title),
      ],
    ); 
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
          setModalState(() { onValidImage(File(cropped.path)); }); 
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
        onTap: onTap, 
        borderRadius: BorderRadius.circular(12), 
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12), 
          decoration: BoxDecoration(
            color: isUploaded ? Colors.green.withValues(alpha: 0.1) : Colors.grey.shade100, 
            border: Border.all(color: isUploaded ? Colors.green : Colors.grey.shade300, width: 1.5), 
            borderRadius: BorderRadius.circular(12),
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

  Future<void> _switchUserRole(String newRole) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => Center(child: CircularProgressIndicator(color: goldAccent)));
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      String fullName = userData['name'] ?? 'مستخدم';
      bool hasProfile = userData.containsKey('profiles') && (userData['profiles'] as Map).containsKey(newRole);

      if (!hasProfile && newRole != 'customer') {
        if (mounted) { 
          Navigator.pop(context); 
          Navigator.pop(context); 
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
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({'activeRole': newRole}, SetOptions(merge: true));
      if (!mounted) return; 
      Navigator.pop(context); 
      Navigator.pop(context); 
      setState(() { _activeRole = newRole; });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم التحويل لوضع: $newRole بنجاح ✅', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
    } catch (e) { 
      if (mounted) { 
        Navigator.pop(context); 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e', style: const TextStyle(fontFamily: 'Cairo')))); 
      } 
    }
  }

  void _showCaptainRegistration(String uid, String fullName) {
    final vehicleController = TextEditingController();
    final plateController = TextEditingController();
    File? carLicenseFront, carLicenseBack, personalIdFront, personalIdBack;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl, 
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        setState(() => _activeRole = 'captain'); 
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

  void _showLawyerRegistration(String uid, String fullName) {
    final degreeController = TextEditingController();
    final registrationNumController = TextEditingController();
    File? barIdFront;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl, 
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        setState(() => _activeRole = 'lawyer'); 
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

  void _showDoctorRegistration(String uid, String fullName) {
    final specialtyController = TextEditingController();
    final licenseController = TextEditingController();
    File? medicalIdFront;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl, 
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        setState(() => _activeRole = 'doctor'); 
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

  void _showNurseRegistration(String uid, String fullName) {
    final qualificationController = TextEditingController(); 
    final nurseLicenseController = TextEditingController(); 
    File? nurseIdFront;

    showModalBottomSheet(
      context: context, 
      isScrollControlled: true, 
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder( 
        builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl, 
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom, left: 24, right: 24, top: 24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        setState(() => _activeRole = 'nurse'); 
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

  @override
  Widget build(BuildContext context) {
    Widget bodyContent;
    switch (_bottomNavIndex) {
      case 0: 
        bodyContent = HomeMainView(userName: _userName, activeRole: _activeRole, onOpenDrawer: () => Scaffold.of(context).openDrawer(), onOpenNotifications: _openNotifications); 
        break;
      case 1: 
        bodyContent = SearchView(activeRole: _activeRole); 
        break;
      case 2: 
        bodyContent = OrdersView(activeRole: _activeRole); 
        break;
      case 3: 
        bodyContent = ProfileView(
          isLoadingProfile: _isLoadingProfile, profileImageUrl: _profileImageUrl, userName: _userName, userEmail: _userEmail,
          onEditProfile: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())); _loadUserProfile(); },
          onPasswordReset: _confirmPasswordReset, onSupport: _showSupportDialog, onLogout: _logout,
        ); 
        break;
      default: 
        bodyContent = HomeMainView(userName: _userName, activeRole: _activeRole, onOpenDrawer: () => Scaffold.of(context).openDrawer(), onOpenNotifications: _openNotifications);
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
                  ],
                ),
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
      body: Directionality(textDirection: TextDirection.rtl, child: bodyContent),
      bottomNavigationBar: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: BoxDecoration(boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 15, offset: const Offset(0, -5))]),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: BottomNavigationBar(
              currentIndex: _bottomNavIndex, 
              onTap: (index) { setState(() { _bottomNavIndex = index; }); }, 
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
                BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'الحساب')
              ],
            ),
          ),
        ),
      ),
    );
  }
}