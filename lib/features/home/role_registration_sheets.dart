// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';

// 🟢 استدعاء ملف اللغات
import 'package:lamma_new/l10n/app_localizations.dart';

// 🟢 استدعاء الـ DocumentService النظيف من الـ Core
import 'package:lamma_new/core/services/document_service.dart';

// 🟢 استيراد ProfileCubit
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';

class RoleRegistrationSheets {
  static const Color primaryNavy = Color(0xFF131E31); 
  static const Color goldAccent = Color(0xFFF3C444);

  // 🟢 الدالة اللي بتدير الـ UI وتستدعي الـ Logic النظيف من الـ DocumentService
  static Future<void> _pickValidateAndCropImage({
    required BuildContext context,
    required StateSetter setModalState,
    required Function(File?) onValidImage,
    required List<String> keywords,
    required String cropTitle,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    
    try { 
      // 1. التقاط الصورة
      File? pickedFile = await DocumentService.pickImage(); 
      if (pickedFile == null) return; 

      if (!context.mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.analyzingDocumentMsg, style: const TextStyle(fontFamily: 'Cairo')), duration: const Duration(seconds: 2))); 
      
      // 2. تحليل الصورة بالذكاء الاصطناعي
      bool isValid = await DocumentService.analyzeImageWithCloudVision(pickedFile, keywords); 
      if (!isValid) { 
        if (!context.mounted) return; 
        bool? proceedAnyway = await showDialog<bool>(
          context: context, 
          builder: (ctx) => AlertDialog(
            title: Text(l10n.docValidationAlertTitle, style: const TextStyle(fontFamily: 'Cairo')), 
            content: Text(l10n.docValidationAlertBody, style: const TextStyle(fontFamily: 'Cairo')), 
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel, style: const TextStyle(fontFamily: 'Cairo'))), 
              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: primaryNavy), child: Text(l10n.yesContinue, style: const TextStyle(color: Colors.white, fontFamily: 'Cairo'))),
            ],
          )
        ); 
        if (proceedAnyway != true) return; 
      } 
      
      // 3. قص الصورة
      File? cropped = await DocumentService.cropDocumentImage(pickedFile, cropTitle); 
      if (cropped != null) { 
        setModalState(() { onValidImage(cropped); }); 
        if (!context.mounted) return; 
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.docAttachedSuccessfully, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green)); 
      } 
    } catch (e) { 
      if (!context.mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorFetchingDoc, style: const TextStyle(fontFamily: 'Cairo')))); 
    } 
  }

  static void showDriver(BuildContext pageContext, ProfileCubit cubit, String fullName) {
    Navigator.push(pageContext, MaterialPageRoute(builder: (context) => DriverRegistrationPage(cubit: cubit, fullName: fullName)));
  }

  static void showLawyer(BuildContext pageContext, ProfileCubit cubit, String fullName) {
    Navigator.push(pageContext, MaterialPageRoute(builder: (context) => LawyerRegistrationPage(cubit: cubit, fullName: fullName)));
  }

  static void showDoctor(BuildContext pageContext, ProfileCubit cubit, String fullName) {
    Navigator.push(pageContext, MaterialPageRoute(builder: (context) => DoctorRegistrationPage(cubit: cubit, fullName: fullName)));
  }

  static void showNurse(BuildContext pageContext, ProfileCubit cubit, String fullName) {
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

  static Widget buildDarkImageButton(String title, File? file, VoidCallback onTap, String attachedText) {
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
              Text(attachedText, style: const TextStyle(color: Colors.green, fontFamily: 'Cairo', fontSize: 12, fontWeight: FontWeight.bold))
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 1. صفحة السائق
class DriverRegistrationPage extends StatefulWidget {
  final ProfileCubit cubit; final String fullName; 
  const DriverRegistrationPage({super.key, required this.cubit, required this.fullName});
  @override State<DriverRegistrationPage> createState() => _DriverRegistrationPageState();
}
class _DriverRegistrationPageState extends State<DriverRegistrationPage> {
  final vehicleController = TextEditingController(); final plateController = TextEditingController();
  File? carLicenseFront, carLicenseBack, personalIdFront, personalIdBack; bool _isLoading = false;

  Future<void> _submitData() async {
    final l10n = AppLocalizations.of(context)!;
    if (vehicleController.text.isEmpty || plateController.text.isEmpty || carLicenseFront == null || carLicenseBack == null || personalIdFront == null || personalIdBack == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFieldsWarning, style: const TextStyle(fontFamily: 'Cairo')))); return;
    }
    setState(() => _isLoading = true);
    try {
      var uploads = await Future.wait<dynamic>([
        widget.cubit.uploadDocument(role: 'driver', docName: 'car_license_front', file: carLicenseFront!),
        widget.cubit.uploadDocument(role: 'driver', docName: 'car_license_back', file: carLicenseBack!),
        widget.cubit.uploadDocument(role: 'driver', docName: 'personal_id_front', file: personalIdFront!),
        widget.cubit.uploadDocument(role: 'driver', docName: 'personal_id_back', file: personalIdBack!),
      ]);
      Map<String, dynamic> data = {'displayName': l10n.captainPrefix(widget.fullName.trim().split(' ').first), 'vehicle': vehicleController.text, 'plate': plateController.text, 'isVerified': true, 'rating': 5.0, 'carLicenseFrontUrl': uploads[0], 'carLicenseBackUrl': uploads[1], 'personalIdFrontUrl': uploads[2], 'personalIdBackUrl': uploads[3]};
      await widget.cubit.submitRoleRegistration(role: 'driver', profileData: data);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurredWithDetails(e.toString())))); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: RoleRegistrationSheets.primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: RoleRegistrationSheets.goldAccent), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.activateCaptainAccount, style: const TextStyle(color: RoleRegistrationSheets.goldAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        centerTitle: true
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: RoleRegistrationSheets.goldAccent)) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(children: [
        RoleRegistrationSheets.buildDarkTextField(controller: vehicleController, label: l10n.carType, icon: Icons.directions_car_rounded), const SizedBox(height: 16),
        RoleRegistrationSheets.buildDarkTextField(controller: plateController, label: l10n.plateNumber, icon: Icons.pin_rounded), const SizedBox(height: 24),
        RoleRegistrationSheets.buildDarkImageButton(l10n.carLicenseFront, carLicenseFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => carLicenseFront = f, keywords: ['رخصة'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.carLicenseBack, carLicenseBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => carLicenseBack = f, keywords: ['فحص'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.personalIdFront, personalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdFront = f, keywords: ['بطاقة'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.personalIdBack, personalIdBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdBack = f, keywords: ['شخصية'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: RoleRegistrationSheets.goldAccent, foregroundColor: RoleRegistrationSheets.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _submitData, child: Text(l10n.activateAccountAndStart, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))),
      ])),
    );
  }
}

// -----------------------------------------------------------------------------
// 2. صفحة المحامي
class LawyerRegistrationPage extends StatefulWidget {
  final ProfileCubit cubit; final String fullName; 
  const LawyerRegistrationPage({super.key, required this.cubit, required this.fullName});
  @override State<LawyerRegistrationPage> createState() => _LawyerRegistrationPageState();
}
class _LawyerRegistrationPageState extends State<LawyerRegistrationPage> {
  final degreeController = TextEditingController(); final registrationNumController = TextEditingController();
  File? personalIdFront, personalIdBack, barIdFront; bool _isLoading = false;

  Future<void> _submitData() async {
    final l10n = AppLocalizations.of(context)!;
    if (degreeController.text.isEmpty || registrationNumController.text.isEmpty || personalIdFront == null || personalIdBack == null || barIdFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFieldsAndImagesWarning, style: const TextStyle(fontFamily: 'Cairo')))); return;
    }
    setState(() => _isLoading = true);
    try {
      var uploads = await Future.wait<dynamic>([
        widget.cubit.uploadDocument(role: 'lawyer', docName: 'bar_id_front', file: barIdFront!),
        widget.cubit.uploadDocument(role: 'lawyer', docName: 'personal_id_front', file: personalIdFront!),
        widget.cubit.uploadDocument(role: 'lawyer', docName: 'personal_id_back', file: personalIdBack!),
      ]);
      Map<String, dynamic> data = {'displayName': l10n.lawyerPrefix(widget.fullName), 'degree': degreeController.text, 'registrationNumber': registrationNumController.text, 'isVerified': true, 'barIdFrontUrl': uploads[0], 'personalIdFrontUrl': uploads[1], 'personalIdBackUrl': uploads[2]};
      await widget.cubit.submitRoleRegistration(role: 'lawyer', profileData: data);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurredWithDetails(e.toString())))); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: RoleRegistrationSheets.primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: RoleRegistrationSheets.goldAccent), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.activateLawyerAccount, style: const TextStyle(color: RoleRegistrationSheets.goldAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        centerTitle: true
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: RoleRegistrationSheets.goldAccent)) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(children: [
        RoleRegistrationSheets.buildDarkTextField(controller: degreeController, label: l10n.barDegree, icon: Icons.school_rounded), const SizedBox(height: 16),
        RoleRegistrationSheets.buildDarkTextField(controller: registrationNumController, label: l10n.barRegistrationNumber, icon: Icons.numbers_rounded, keyboardType: TextInputType.number), const SizedBox(height: 24),
        RoleRegistrationSheets.buildDarkImageButton(l10n.personalIdFront, personalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdFront = f, keywords: ['بطاقة'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.personalIdBack, personalIdBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdBack = f, keywords: ['شخصية'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.attachSyndicateId, barIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => barIdFront = f, keywords: ['نقابة'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: RoleRegistrationSheets.goldAccent, foregroundColor: RoleRegistrationSheets.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _submitData, child: Text(l10n.activateAccountAndStart, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))),
      ])),
    );
  }
}

// -----------------------------------------------------------------------------
// 3. صفحة الطبيب
class DoctorRegistrationPage extends StatefulWidget {
  final ProfileCubit cubit; final String fullName; 
  const DoctorRegistrationPage({super.key, required this.cubit, required this.fullName});
  @override State<DoctorRegistrationPage> createState() => _DoctorRegistrationPageState();
}
class _DoctorRegistrationPageState extends State<DoctorRegistrationPage> {
  final specialtyController = TextEditingController(); final licenseController = TextEditingController();
  File? personalIdFront, personalIdBack, medicalIdFront; bool _isLoading = false;

  Future<void> _submitData() async {
    final l10n = AppLocalizations.of(context)!;
    if (specialtyController.text.isEmpty || licenseController.text.isEmpty || personalIdFront == null || personalIdBack == null || medicalIdFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFieldsAndImagesWarning, style: const TextStyle(fontFamily: 'Cairo')))); return;
    }
    setState(() => _isLoading = true);
    try {
      var uploads = await Future.wait<dynamic>([
        widget.cubit.uploadDocument(role: 'doctor', docName: 'medical_id_front', file: medicalIdFront!),
        widget.cubit.uploadDocument(role: 'doctor', docName: 'personal_id_front', file: personalIdFront!),
        widget.cubit.uploadDocument(role: 'doctor', docName: 'personal_id_back', file: personalIdBack!),
      ]);
      Map<String, dynamic> data = {'displayName': l10n.doctorPrefix(widget.fullName), 'specialty': specialtyController.text, 'licenseNumber': licenseController.text, 'isVerified': true, 'medicalIdFrontUrl': uploads[0], 'personalIdFrontUrl': uploads[1], 'personalIdBackUrl': uploads[2]};
      await widget.cubit.submitRoleRegistration(role: 'doctor', profileData: data);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurredWithDetails(e.toString())))); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: RoleRegistrationSheets.primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: RoleRegistrationSheets.goldAccent), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.activateDoctorAccount, style: const TextStyle(color: RoleRegistrationSheets.goldAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        centerTitle: true
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: RoleRegistrationSheets.goldAccent)) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(children: [
        RoleRegistrationSheets.buildDarkTextField(controller: specialtyController, label: l10n.specialty, icon: Icons.healing_rounded), const SizedBox(height: 16),
        RoleRegistrationSheets.buildDarkTextField(controller: licenseController, label: l10n.medicalLicenseNumber, icon: Icons.assignment_ind_rounded, keyboardType: TextInputType.number), const SizedBox(height: 24),
        RoleRegistrationSheets.buildDarkImageButton(l10n.personalIdFront, personalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdFront = f, keywords: ['بطاقة'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.personalIdBack, personalIdBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdBack = f, keywords: ['شخصية'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.attachSyndicateId, medicalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => medicalIdFront = f, keywords: ['أطباء'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: RoleRegistrationSheets.goldAccent, foregroundColor: RoleRegistrationSheets.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _submitData, child: Text(l10n.activateAccountAndStart, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))),
      ])),
    );
  }
}

// -----------------------------------------------------------------------------
// 4. صفحة التمريض
class NurseRegistrationPage extends StatefulWidget {
  final ProfileCubit cubit; final String fullName; 
  const NurseRegistrationPage({super.key, required this.cubit, required this.fullName});
  @override State<NurseRegistrationPage> createState() => _NurseRegistrationPageState();
}
class _NurseRegistrationPageState extends State<NurseRegistrationPage> {
  final qualificationController = TextEditingController(); final nurseLicenseController = TextEditingController();
  File? personalIdFront, personalIdBack, nurseIdFront; bool _isLoading = false;

  Future<void> _submitData() async {
    final l10n = AppLocalizations.of(context)!;
    if (qualificationController.text.isEmpty || nurseLicenseController.text.isEmpty || personalIdFront == null || personalIdBack == null || nurseIdFront == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillAllFieldsAndImagesWarning, style: const TextStyle(fontFamily: 'Cairo')))); return;
    }
    setState(() => _isLoading = true);
    try {
      var uploads = await Future.wait<dynamic>([
        widget.cubit.uploadDocument(role: 'nurse', docName: 'nurse_id_front', file: nurseIdFront!),
        widget.cubit.uploadDocument(role: 'nurse', docName: 'personal_id_front', file: personalIdFront!),
        widget.cubit.uploadDocument(role: 'nurse', docName: 'personal_id_back', file: personalIdBack!),
      ]);
      Map<String, dynamic> data = {'displayName': l10n.nursePrefix(widget.fullName), 'qualification': qualificationController.text, 'licenseNumber': nurseLicenseController.text, 'isVerified': true, 'nurseIdFrontUrl': uploads[0], 'personalIdFrontUrl': uploads[1], 'personalIdBackUrl': uploads[2]};
      await widget.cubit.submitRoleRegistration(role: 'nurse', profileData: data);
      if (mounted) Navigator.pop(context);
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.errorOccurredWithDetails(e.toString())))); } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: RoleRegistrationSheets.primaryNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: RoleRegistrationSheets.goldAccent), onPressed: () => Navigator.pop(context)),
        title: Text(l10n.activateNurseAccount, style: const TextStyle(color: RoleRegistrationSheets.goldAccent, fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        centerTitle: true
      ),
      body: _isLoading ? const Center(child: CircularProgressIndicator(color: RoleRegistrationSheets.goldAccent)) : SingleChildScrollView(padding: const EdgeInsets.all(24.0), child: Column(children: [
        RoleRegistrationSheets.buildDarkTextField(controller: qualificationController, label: l10n.nurseQualification, icon: Icons.assignment_rounded), const SizedBox(height: 16),
        RoleRegistrationSheets.buildDarkTextField(controller: nurseLicenseController, label: l10n.nurseLicenseNumber, icon: Icons.pin_outlined, keyboardType: TextInputType.number), const SizedBox(height: 24),
        RoleRegistrationSheets.buildDarkImageButton(l10n.personalIdFront, personalIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdFront = f, keywords: ['بطاقة'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.personalIdBack, personalIdBack, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => personalIdBack = f, keywords: ['شخصية'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        RoleRegistrationSheets.buildDarkImageButton(l10n.attachSyndicateId, nurseIdFront, () => RoleRegistrationSheets._pickValidateAndCropImage(context: context, setModalState: setState, onValidImage: (f) => nurseIdFront = f, keywords: ['تمريض'], cropTitle: l10n.edit), l10n.attachedSuccessfully),
        const SizedBox(height: 40),
        SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: RoleRegistrationSheets.goldAccent, foregroundColor: RoleRegistrationSheets.primaryNavy, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), onPressed: _submitData, child: Text(l10n.activateAccountAndStart, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')))),
      ])),
    );
  }
}