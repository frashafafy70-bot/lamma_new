// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);
  
  bool _isLoading = true;
  bool _isSaving = false;
  File? _newProfileImage;
  String _currentImageUrl = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentData();
  }

  // 📥 سحب بيانات المستخدم الحالية من قاعدة البيانات
  Future<void> _loadCurrentData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          var data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['name'] ?? '';
            _phoneController.text = data['phone'] ?? '';
            _nationalIdController.text = data['nationalId'] ?? '';
            _currentImageUrl = data.containsKey('profileImage') ? data['profileImage'] : '';
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في تحميل البيانات: $e', style: const TextStyle(fontFamily: 'Cairo'))));
        }
      }
    }
    if (mounted) {
      setState(() { _isLoading = false; });
    }
  }

  // 📸 اختيار صورة جديدة من المعرض
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // تقليل الجودة لـ 70% لسرعة الرفع وتوفير المساحة
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() { _newProfileImage = File(pickedFile.path); });
    }
  }

  // 💾 حفظ التعديلات (رفع الصورة إن وجدت + تحديث البيانات)
  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('برجاء إكمال البيانات الأساسية (الاسم ورقم الهاتف)', style: TextStyle(fontFamily: 'Cairo'))));
      return;
    }

    setState(() { _isSaving = true; });
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        String finalImageUrl = _currentImageUrl;

        // 🚀 رفع الصورة الجديدة لو اختار واحدة
        if (_newProfileImage != null) {
          Reference ref = FirebaseStorage.instance.ref().child('users/${currentUser.uid}/profile.jpg');
          UploadTask uploadTask = ref.putFile(_newProfileImage!);
          TaskSnapshot snapshot = await uploadTask;
          finalImageUrl = await snapshot.ref.getDownloadURL();
        }

        // 📝 تحديث الداتابيز
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'nationalId': _nationalIdController.text.trim(),
          'profileImage': finalImageUrl,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بياناتك بنجاح! ✅', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), backgroundColor: Colors.green)
        );
        Navigator.pop(context); // الرجوع لشاشة الحساب بعد الحفظ
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ أثناء الحفظ: $e', style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() { _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('تعديل البيانات الشخصية', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp)),
        backgroundColor: Colors.white,
        foregroundColor: primaryNavy,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: primaryNavy))
        : Directionality(
            textDirection: TextDirection.rtl,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.all(24.w),
                child: Column(
                  children: [
                    // 🎨 دائرة تغيير الصورة
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w), 
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: goldAccent, width: 2.w)),
                            child: CircleAvatar(
                              radius: 60.r,
                              backgroundColor: Colors.grey.shade100,
                              backgroundImage: _newProfileImage != null 
                                  ? FileImage(_newProfileImage!) as ImageProvider
                                  : (_currentImageUrl.isNotEmpty ? NetworkImage(_currentImageUrl) : null),
                              child: (_newProfileImage == null && _currentImageUrl.isEmpty) 
                                  ? Icon(Icons.person, size: 60.sp, color: Colors.grey.shade400) : null,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(color: goldAccent, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 3.w)),
                            child: Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22.sp),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40.h),

                    // 📝 الحقول (TextFields)
                    _buildTextField('الاسم بالكامل', _nameController, Icons.person_rounded),
                    SizedBox(height: 20.h),
                    _buildTextField('رقم الهاتف', _phoneController, Icons.phone_android_rounded, isNumber: true, isLtr: true),
                    SizedBox(height: 20.h),
                    _buildTextField('الرقم القومي (اختياري)', _nationalIdController, Icons.featured_play_list_rounded, isNumber: true, isLtr: true),
                    
                    SizedBox(height: 50.h),

                    // ✅ زر الحفظ
                    SizedBox(
                      width: double.infinity,
                      height: 56.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving 
                            ? SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text('حفظ التعديلات', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo', color: Colors.white)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
    );
  }

  // 🛠️ دالة مساعدة لبناء الحقول بشكل احترافي
  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false, bool isLtr = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      textDirection: isLtr ? TextDirection.ltr : TextDirection.rtl,
      textAlign: isLtr ? TextAlign.left : TextAlign.right,
      style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 15.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14.sp, fontFamily: 'Cairo'),
        prefixIcon: Icon(icon, color: primaryNavy),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: goldAccent, width: 1.5.w)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }
}