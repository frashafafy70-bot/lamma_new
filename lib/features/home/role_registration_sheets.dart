import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'package:lamma_new/features/home/cubit/home_cubit.dart';

class RoleRegistrationSheets {
  // 🟢 تم توحيد الألوان لدرجات الشاشة الرئيسية الفخمة
  static const Color primaryNavy = Color(0xFF131E31); 
  static const Color goldAccent = Color(0xFFF3C444);
  static final ImagePicker _picker = ImagePicker();

  static const String _cloudVisionApiKey = String.fromEnvironment(
    'CLOUD_VISION_API_KEY',
    defaultValue: 'AIzaSyC7LVnuJ5QfXCAKjse-EbDxvKZITRa75AM',
  );

  static Future<bool> _analyzeImageWithCloudVision(String imagePath, List<String> requiredKeywords) async {
    if (_cloudVisionApiKey.isEmpty) return false;
    try {
      List<int> imageBytes = await File(imagePath).readAsBytes();
      String base64Image = base64Encode(imageBytes);
      var requestBody = {
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [{"type": "TEXT_DETECTION"}],
            "imageContext": {"languageHints": ["ar"]}
          }
        ]
      };
      var response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_cloudVisionApiKey'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        var responses = jsonResponse['responses'] ?? [];
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

  static Future<CroppedFile?> _cropDocumentImage(String path, String title) async {
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

  static Future<void> _pickValidateAndCropImage({
    required BuildContext context,
    required StateSetter setModalState,
    required Function(File?) onValidImage,
    required List<String> keywords,
    required String cropTitle,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (pickedFile == null) return;

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🤖 جاري فحص المستند سحابياً...', style: TextStyle(fontFamily: 'Cairo'))));

      bool isValid = await _analyzeImageWithCloudVision(pickedFile.path, keywords);
      
      if (!context.mounted) return;
      if (!isValid) {
        bool? proceedAnyway = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text('تنبيه فحص المستند ⚠️', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')),
                  content: const Text('الذكاء الاصطناعي لم يتعرف على المستند. هل تريد إكمال الرفع للمراجعة اليدوية؟', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(fontFamily: 'Cairo'))),
                    ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: primaryNavy), child: const Text('نعم، المتابعة', style: TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
                  ],
                ));
        if (proceedAnyway != true) return;
      }

      CroppedFile? cropped = await _cropDocumentImage(pickedFile.path, cropTitle);
      if (cropped != null && context.mounted) {
        setModalState(() {
          onValidImage(File(cropped.path));
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم إرفاق المستند بنجاح.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في جلب المستند', style: TextStyle(fontFamily: 'Cairo'))));
      }
    }
  }

  static void showDriver(BuildContext pageContext, HomeCubit cubit, String fullName) {
    Navigator.push(pageContext, MaterialPageRoute(builder: (context) => DriverRegistrationPage(cubit: cubit, fullName: fullName)));
  }

  static void showLawyer(BuildContext pageContext, HomeCubit cubit, String fullName) {
    Navigator.push(pageContext, MaterialPageRoute(builder: (context) => LawyerRegistrationPage(cubit: cubit, fullName: fullName)));
  }

  static void showDoctor(BuildContext pageContext, HomeCubit cubit, String fullName) {
    Navigator.push(pageContext, MaterialPageRoute(builder: (context) => DoctorRegistrationPage(cubit: cubit, fullName: fullName)));
  }

  static void showNurse(BuildContext pageContext, HomeCubit cubit, String fullName) {
    Navigator.push(pageContext, MaterialPageRoute(builder: (context) => NurseRegistrationPage(cubit: cubit, fullName: fullName)));
  }

  static Widget buildDarkTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: goldAccent.withValues(alpha: 0.7), fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: goldAccent),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: goldAccent.withValues(alpha: 0.3))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: goldAccent, width: 2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
      ),
    );
  }

  // 🟢 تصميم الزرار الجديد (شاشة كاملة العرض ويترص بالطول)
  static Widget buildDarkImageButton(String title, File? file, VoidCallback onTap) {
    bool isUploaded = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: isUploaded ? Colors.green.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: isUploaded ? Colors.green : goldAccent.withValues(alpha: 0.3), width: 1.5),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Icon(isUploaded ? Icons.check_circle_rounded : Icons.add_a_photo_rounded, color: isUploaded ? Colors.green : goldAccent, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isUploaded ? Colors.green : Colors.white, fontFamily: 'Cairo')),
            ),
            if (isUploaded)
              const Text('تم الإرفاق', style: TextStyle(color: Colors.green, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. صفحة السائق
class DriverRegistrationPage extends StatefulWidget {
  final HomeCubit cubit; final String fullName;
  const DriverRegistrationPage({super.key, required this.cubit, required this.fullName});
  @override State<DriverRegistrationPage> createState() => _DriverRegistrationPageState();
}
class _DriverRegistrationPageState extends State<DriverRegistrationPage> {
  final vehicleController = TextEditingController(); final plateController = TextEditingController();
  File? carLicenseFront, carLicenseBack, personalIdFront, personalIdBack; bool _isLoading = false;

  Future<void> _submitData() async {
    if (vehicleController.text.isEmpty || plateController.text.isEmpty || carLicenseFront == null || carLicenseBack == null || personalIdFront == null || personalIdBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء استكمال جميع البيانات', style: TextStyle(fontFamily: 'Cairo')))); return;
    }
    setState(() => _isLoading = true);
    try {
      // 🟢 تم التعديل هنا لـ Future.wait<dynamic>
      var uploads = await Future.wait<dynamic>([
        widget.cubit.uploadDocument(role: 'driver', docName: 'car_license_front', file: carLicenseFront!),
        widget.cubit.uploadDocument(role: 'driver', docName: 'car_license_back', file: carLicenseBack!),
        widget.cubit.uploadDocument(role: 'driver', docName: 'personal_id_front', file: personalIdFront!),
        widget.cubit.uploadDocument(role: 'driver', docName: 'personal_id_back', file: personalIdBack!),
      ]);
      Map<String, dynamic> data = {'displayName': 'كابتن ${widget.fullName.trim().split(' ').first}', 'vehicle': vehicleController.text, 'plate': plateController.text, 'isVerified': true, 'rating': 5.0, 'carLicenseFrontUrl': uploads[0], 'carLicenseBackUrl': uploads[1], 'personalIdFrontUrl': uploads[2], 'personalIdBackUrl': uploads[3]};
      await widget.cubit.submitRoleRegistration(role: 'driver', profileData: data);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'))); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RoleRegistrationSheets.primaryNavy,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: RoleRegistrationSheets.goldAccent), onPressed: () => Navigator.pop(context)),
          title: const Text('تفعيل حساب كابتن 🚖', style: TextStyle(color: RoleRegistrationSheets.goldAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
          centerTitle: true
        ),
        body: _isLoading ? const Center(child: CircularProgressIndicator(color: RoleRegistrationSheets.goldAccent)) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(children: [
          RoleRegistrationSheets.buildDarkTextField(controller: vehicleController, label: 'نوع السيارة', icon: Icons.directions_car_rounded), const SizedBox(height: 16),
          RoleRegistrationSheets.buildDarkTextField(controller: plateController, label: 'رقم اللوحة', icon: Icons.pin_rounded), const SizedBox(height: 24),
          // 🟢 تم إزالة الـ Row ورص الكروت بالطول
          RoleRegistrationSheets.buildDarkImageButton('رخصة المركبة (أمامي)', carLicenseFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => carLicenseFront = f, keywords: ['رخصة'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('رخصة المركبة (خلفي)', carLicenseBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => carLicenseBack = f, keywords: ['فحص'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('البطاقة الشخصية (أمامي)', personalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdFront = f, keywords: ['بطاقة'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('البطاقة الشخصية (خلفي)', personalIdBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdBack = f, keywords: ['شخصية'], cropTitle: 'تعديل')),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: RoleRegistrationSheets.goldAccent, foregroundColor: RoleRegistrationSheets.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _submitData, child: const Text('تفعيل الحساب والبدء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))),
        ])),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. صفحة المحامي
class LawyerRegistrationPage extends StatefulWidget {
  final HomeCubit cubit; final String fullName;
  const LawyerRegistrationPage({super.key, required this.cubit, required this.fullName});
  @override State<LawyerRegistrationPage> createState() => _LawyerRegistrationPageState();
}
class _LawyerRegistrationPageState extends State<LawyerRegistrationPage> {
  final degreeController = TextEditingController(); final registrationNumController = TextEditingController();
  File? personalIdFront, personalIdBack, barIdFront; bool _isLoading = false;

  Future<void> _submitData() async {
    if (degreeController.text.isEmpty || registrationNumController.text.isEmpty || personalIdFront == null || personalIdBack == null || barIdFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء استكمال جميع البيانات والصور', style: TextStyle(fontFamily: 'Cairo')))); return;
    }
    setState(() => _isLoading = true);
    try {
      // 🟢 تم التعديل هنا لـ Future.wait<dynamic>
      var uploads = await Future.wait<dynamic>([
        widget.cubit.uploadDocument(role: 'lawyer', docName: 'bar_id_front', file: barIdFront!),
        widget.cubit.uploadDocument(role: 'lawyer', docName: 'personal_id_front', file: personalIdFront!),
        widget.cubit.uploadDocument(role: 'lawyer', docName: 'personal_id_back', file: personalIdBack!),
      ]);
      Map<String, dynamic> data = {'displayName': 'الأستاذ / ${widget.fullName}', 'degree': degreeController.text, 'registrationNumber': registrationNumController.text, 'isVerified': true, 'barIdFrontUrl': uploads[0], 'personalIdFrontUrl': uploads[1], 'personalIdBackUrl': uploads[2]};
      await widget.cubit.submitRoleRegistration(role: 'lawyer', profileData: data);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'))); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RoleRegistrationSheets.primaryNavy,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: RoleRegistrationSheets.goldAccent), onPressed: () => Navigator.pop(context)),
          title: const Text('اعتماد حساب المحامي ⚖️', style: TextStyle(color: RoleRegistrationSheets.goldAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
          centerTitle: true
        ),
        body: _isLoading ? const Center(child: CircularProgressIndicator(color: RoleRegistrationSheets.goldAccent)) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(children: [
          RoleRegistrationSheets.buildDarkTextField(controller: degreeController, label: 'درجة القيد', icon: Icons.school_rounded), const SizedBox(height: 16),
          RoleRegistrationSheets.buildDarkTextField(controller: registrationNumController, label: 'رقم القيد بالنقابة', icon: Icons.numbers_rounded, keyboardType: TextInputType.number), const SizedBox(height: 24),
          // 🟢 تم الرص بالطول
          RoleRegistrationSheets.buildDarkImageButton('البطاقة الشخصية (أمامي)', personalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdFront = f, keywords: ['بطاقة'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('البطاقة الشخصية (خلفي)', personalIdBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdBack = f, keywords: ['شخصية'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('إرفاق صورة الكارنيه', barIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => barIdFront = f, keywords: ['نقابة'], cropTitle: 'تعديل')),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: RoleRegistrationSheets.goldAccent, foregroundColor: RoleRegistrationSheets.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _submitData, child: const Text('تفعيل الحساب والبدء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))),
        ])),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. صفحة الطبيب
class DoctorRegistrationPage extends StatefulWidget {
  final HomeCubit cubit; final String fullName;
  const DoctorRegistrationPage({super.key, required this.cubit, required this.fullName});
  @override State<DoctorRegistrationPage> createState() => _DoctorRegistrationPageState();
}
class _DoctorRegistrationPageState extends State<DoctorRegistrationPage> {
  final specialtyController = TextEditingController(); final licenseController = TextEditingController();
  File? personalIdFront, personalIdBack, medicalIdFront; bool _isLoading = false;

  Future<void> _submitData() async {
    if (specialtyController.text.isEmpty || licenseController.text.isEmpty || personalIdFront == null || personalIdBack == null || medicalIdFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء استكمال جميع البيانات والصور', style: TextStyle(fontFamily: 'Cairo')))); return;
    }
    setState(() => _isLoading = true);
    try {
      // 🟢 تم التعديل هنا لـ Future.wait<dynamic>
      var uploads = await Future.wait<dynamic>([
        widget.cubit.uploadDocument(role: 'doctor', docName: 'medical_id_front', file: medicalIdFront!),
        widget.cubit.uploadDocument(role: 'doctor', docName: 'personal_id_front', file: personalIdFront!),
        widget.cubit.uploadDocument(role: 'doctor', docName: 'personal_id_back', file: personalIdBack!),
      ]);
      Map<String, dynamic> data = {'displayName': 'دكتور / ${widget.fullName}', 'specialty': specialtyController.text, 'licenseNumber': licenseController.text, 'isVerified': true, 'medicalIdFrontUrl': uploads[0], 'personalIdFrontUrl': uploads[1], 'personalIdBackUrl': uploads[2]};
      await widget.cubit.submitRoleRegistration(role: 'doctor', profileData: data);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'))); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RoleRegistrationSheets.primaryNavy,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: RoleRegistrationSheets.goldAccent), onPressed: () => Navigator.pop(context)),
          title: const Text('اعتماد حساب الطبيب 👨‍⚕️', style: TextStyle(color: RoleRegistrationSheets.goldAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
          centerTitle: true
        ),
        body: _isLoading ? const Center(child: CircularProgressIndicator(color: RoleRegistrationSheets.goldAccent)) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(children: [
          RoleRegistrationSheets.buildDarkTextField(controller: specialtyController, label: 'التخصص', icon: Icons.healing_rounded), const SizedBox(height: 16),
          RoleRegistrationSheets.buildDarkTextField(controller: licenseController, label: 'رقم ترخيص مزاولة المهنة', icon: Icons.assignment_ind_rounded, keyboardType: TextInputType.number), const SizedBox(height: 24),
          // 🟢 تم الرص بالطول
          RoleRegistrationSheets.buildDarkImageButton('البطاقة الشخصية (أمامي)', personalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdFront = f, keywords: ['بطاقة'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('البطاقة الشخصية (خلفي)', personalIdBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdBack = f, keywords: ['شخصية'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('إرفاق صورة الكارنيه', medicalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => medicalIdFront = f, keywords: ['أطباء'], cropTitle: 'تعديل')),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: RoleRegistrationSheets.goldAccent, foregroundColor: RoleRegistrationSheets.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _submitData, child: const Text('تفعيل الحساب والبدء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))),
        ])),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. صفحة التمريض
class NurseRegistrationPage extends StatefulWidget {
  final HomeCubit cubit; final String fullName;
  const NurseRegistrationPage({super.key, required this.cubit, required this.fullName});
  @override State<NurseRegistrationPage> createState() => _NurseRegistrationPageState();
}
class _NurseRegistrationPageState extends State<NurseRegistrationPage> {
  final qualificationController = TextEditingController(); final nurseLicenseController = TextEditingController();
  File? personalIdFront, personalIdBack, nurseIdFront; bool _isLoading = false;

  Future<void> _submitData() async {
    if (qualificationController.text.isEmpty || nurseLicenseController.text.isEmpty || personalIdFront == null || personalIdBack == null || nurseIdFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء استكمال جميع البيانات والصور', style: TextStyle(fontFamily: 'Cairo')))); return;
    }
    setState(() => _isLoading = true);
    try {
      // 🟢 تم التعديل هنا لـ Future.wait<dynamic>
      var uploads = await Future.wait<dynamic>([
        widget.cubit.uploadDocument(role: 'nurse', docName: 'nurse_id_front', file: nurseIdFront!),
        widget.cubit.uploadDocument(role: 'nurse', docName: 'personal_id_front', file: personalIdFront!),
        widget.cubit.uploadDocument(role: 'nurse', docName: 'personal_id_back', file: personalIdBack!),
      ]);
      Map<String, dynamic> data = {'displayName': 'ممرض(ة) / ${widget.fullName}', 'qualification': qualificationController.text, 'licenseNumber': nurseLicenseController.text, 'isVerified': true, 'nurseIdFrontUrl': uploads[0], 'personalIdFrontUrl': uploads[1], 'personalIdBackUrl': uploads[2]};
      await widget.cubit.submitRoleRegistration(role: 'nurse', profileData: data);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'))); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: RoleRegistrationSheets.primaryNavy,
        appBar: AppBar(
          backgroundColor: Colors.transparent, 
          elevation: 0, 
          leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: RoleRegistrationSheets.goldAccent), onPressed: () => Navigator.pop(context)),
          title: const Text('اعتماد حساب التمريض 🩺', style: TextStyle(color: RoleRegistrationSheets.goldAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
          centerTitle: true
        ),
        body: _isLoading ? const Center(child: CircularProgressIndicator(color: RoleRegistrationSheets.goldAccent)) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(children: [
          RoleRegistrationSheets.buildDarkTextField(controller: qualificationController, label: 'المؤهل (أخصائي / فني)', icon: Icons.assignment_rounded), const SizedBox(height: 16),
          RoleRegistrationSheets.buildDarkTextField(controller: nurseLicenseController, label: 'رقم ترخيص النقابة', icon: Icons.pin_outlined, keyboardType: TextInputType.number), const SizedBox(height: 24),
          // 🟢 تم الرص بالطول
          RoleRegistrationSheets.buildDarkImageButton('البطاقة الشخصية (أمامي)', personalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdFront = f, keywords: ['بطاقة'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('البطاقة الشخصية (خلفي)', personalIdBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdBack = f, keywords: ['شخصية'], cropTitle: 'تعديل')),
          RoleRegistrationSheets.buildDarkImageButton('إرفاق صورة الكارنيه', nurseIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => nurseIdFront = f, keywords: ['تمريض'], cropTitle: 'تعديل')),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: RoleRegistrationSheets.goldAccent, foregroundColor: RoleRegistrationSheets.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _submitData, child: const Text('تفعيل الحساب والبدء', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))),
        ])),
      ),
    );
  }
}