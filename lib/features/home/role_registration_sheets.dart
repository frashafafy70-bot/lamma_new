// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🟢 التعديل هنا: نادى على الملف جاره مباشرة
import 'document_service.dart';

class RoleRegistrationSheets {
  static final Color primaryNavy = const Color(0xFF0F172A);
  static final Color goldAccent = const Color(0xFFD4AF37);

  static Widget _buildFileImageButton(String title, File? file, VoidCallback onTap) { 
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

  // ==========================================
  // 1. تسجيل الكابتن
  // ==========================================
  static void showCaptainRegistration(BuildContext context, String uid, String fullName, Function(String) onRoleChanged) {
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
                      _buildFileImageButton('الوجه الأمامي', carLicenseFront, () => DocumentService.pickValidateAndCropImage(context, setModalState, (f) => carLicenseFront = f, ['رخصة', 'المرور'], 'تعديل صورة رخصة السيارة')),
                      const SizedBox(width: 12),
                      _buildFileImageButton('الوجه الخلفي', carLicenseBack, () => DocumentService.pickValidateAndCropImage(context, setModalState, (f) => carLicenseBack = f, ['وزارة', 'فحص', 'تأمين'], 'تعديل صورة رخصة السيارة')),
                    ]),
                    const SizedBox(height: 20),
                    const Text('الرخصة الشخصية (وش وضهر)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Row(children: [
                      _buildFileImageButton('الوجه الأمامي', personalIdFront, () => DocumentService.pickValidateAndCropImage(context, setModalState, (f) => personalIdFront = f, ['بطاقة', 'رقم', 'قومي', 'قيادة'], 'تعديل صورة الرخصة الشخصية')),
                      const SizedBox(width: 12),
                      _buildFileImageButton('الوجه الخلفي', personalIdBack, () => DocumentService.pickValidateAndCropImage(context, setModalState, (f) => personalIdBack = f, ['الرقم', 'مهنة', 'مرور'], 'تعديل صورة الرخصة الشخصية')),
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
                        
                        String? carFrontUrl = await DocumentService.uploadDocumentToStorage(uid: uid, role: 'captain', docName: 'car_license_front', file: carLicenseFront!);
                        String? carBackUrl = await DocumentService.uploadDocumentToStorage(uid: uid, role: 'captain', docName: 'car_license_back', file: carLicenseBack!);
                        String? idFrontUrl = await DocumentService.uploadDocumentToStorage(uid: uid, role: 'captain', docName: 'personal_id_front', file: personalIdFront!);
                        String? idBackUrl = await DocumentService.uploadDocumentToStorage(uid: uid, role: 'captain', docName: 'personal_id_back', file: personalIdBack!);
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
                        onRoleChanged('captain');
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
  // 2. تسجيل المحامي
  // ==========================================
  static void showLawyerRegistration(BuildContext context, String uid, String fullName, Function(String) onRoleChanged) {
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
                      _buildFileImageButton('إرفاق صورة الكارنيه', barIdFront, () => DocumentService.pickValidateAndCropImage(context, setModalState, (f) => barIdFront = f, ['نقابة', 'المحامين', 'محام'], 'تعديل وقص صورة الكارنيه')),
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
                        
                        String? lawyerFrontUrl = await DocumentService.uploadDocumentToStorage(uid: uid, role: 'lawyer', docName: 'bar_id_front', file: barIdFront!);
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
                        onRoleChanged('lawyer');
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
  // 3. تسجيل الطبيب
  // ==========================================
  static void showDoctorRegistration(BuildContext context, String uid, String fullName, Function(String) onRoleChanged) {
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
                      _buildFileImageButton('إرفاق صورة الكارنيه', medicalIdFront, () => DocumentService.pickValidateAndCropImage(context, setModalState, (f) => medicalIdFront = f, ['نقابة', 'الأطباء', 'طبيب'], 'تعديل وقص صورة الكارنيه')),
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
                        
                        String? doctorFrontUrl = await DocumentService.uploadDocumentToStorage(uid: uid, role: 'doctor', docName: 'medical_id_front', file: medicalIdFront!);
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
                        onRoleChanged('doctor');
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
  // 4. تسجيل التمريض
  // ==========================================
  static void showNurseRegistration(BuildContext context, String uid, String fullName, Function(String) onRoleChanged) {
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
                      _buildFileImageButton('إرفاق صورة الكارنيه', nurseIdFront, () => DocumentService.pickValidateAndCropImage(context, setModalState, (f) => nurseIdFront = f, ['نقابة', 'التمريض', 'ممرض', 'أخصائي'], 'تعديل وقص صورة الكارنيه')),
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
                        
                        String? nurseFrontUrl = await DocumentService.uploadDocumentToStorage(uid: uid, role: 'nurse', docName: 'nurse_id_front', file: nurseIdFront!);
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
                        onRoleChanged('nurse');
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
}