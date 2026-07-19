import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart'; // 🟢 استدعاء الحزمة الجديدة

// تأكد من صحة مسار الاستدعاء للـ Cubit والـ State في مشروعك
import 'package:lamma_new/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:lamma_new/features/profile/presentation/cubit/profile_state.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);
  final Color lightGreyBg = const Color(0xFFF8FAFC);

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _nationalIdController;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // 🟢 متغير لحفظ الصورة المختارة محلياً قبل رفعها
  File? _pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final profileState = context.read<ProfileCubit>().state;
    final currentUser = FirebaseAuth.instance.currentUser;

    _nameController = TextEditingController(text: profileState.userName);

    String currentPhone =
        (profileState.userPhone != null && profileState.userPhone!.isNotEmpty)
            ? profileState.userPhone!
            : (currentUser?.phoneNumber ?? '');

    if (currentPhone.startsWith('+20')) {
      currentPhone = currentPhone.replaceFirst('+20', '0');
    } else if (currentPhone.startsWith('20') && currentPhone.length > 10) {
      currentPhone = currentPhone.replaceFirst('20', '0');
    }

    _phoneController = TextEditingController(text: currentPhone);
    _nationalIdController =
        TextEditingController(text: profileState.nationalId ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    super.dispose();
  }

  // 🟢 دالة منبثقة لاختيار مصدر الصورة (كاميرا أو استوديو)
  void _showImageSourcePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'اختر صورة الحساب',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSourceOption(
                        icon: Icons.camera_alt_rounded,
                        label: 'الكاميرا',
                        color: Colors.blue,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.camera);
                        },
                      ),
                      _buildSourceOption(
                        icon: Icons.photo_library_rounded,
                        label: 'المعرض / الاستوديو',
                        color: Colors.green,
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(ImageSource.gallery);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ويدجت مساعدة لبناء خيارات اختيار الصورة
  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        width: 130.w,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        decoration: BoxDecoration(
          color: lightGreyBg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32.sp),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(fontSize: 12.sp, color: primaryNavy),
            ),
          ],
        ),
      ),
    );
  }

  // 🟢 دالة التقاط أو اختيار الصورة وتحديث الواجهة محلياً
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // ضغط جودة الصورة لسرعة الرفع وتقليل استهلاك المساحة
        maxWidth: 500, // تحديد أقصى عرض متناسق مع مساحة الملف الشخصي
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  // 2️⃣ دالة حفظ البيانات واستدعاء الـ Cubit
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 🟢 استدعاء دالة تحديث الحساب الفعالة في الـ ProfileCubit وتمرير الملف الجديد لها
      await context.read<ProfileCubit>().updateProfile(
            name: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            nationalId: _nationalIdController.text.trim().isEmpty
                ? null
                : _nationalIdController.text.trim(),
            newProfileImage:
                _pickedImage, // تمرير ملف الصورة الجديد (لو اختاره، وإلا سيرسل null ويحافظ على الحالية)
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('تم حفظ التعديلات بنجاح ✅',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('حدث خطأ أثناء الحفظ، يرجى المحاولة لاحقاً ❌',
            style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'تعديل البيانات الشخصية',
            style: TextStyle(
              color: primaryNavy,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_rounded,
                color: primaryNavy, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🟢 قسم الصورة الشخصية مع دعم تحديث العرض الفوري
                  Center(
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: EdgeInsets.all(4.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: goldAccent, width: 2),
                          ),
                          child: BlocBuilder<ProfileCubit, ProfileState>(
                            builder: (context, state) {
                              // إذا اختار المستخدم صورة محلياً نعرضها، وإلا نعرض الرابط القديم من السيرفر
                              if (_pickedImage != null) {
                                return CircleAvatar(
                                  radius: 50.r,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: FileImage(_pickedImage!),
                                );
                              } else {
                                final imgUrl = state.profileImageUrl;
                                return CircleAvatar(
                                  radius: 50.r,
                                  backgroundColor: Colors.grey.shade100,
                                  backgroundImage: imgUrl.isNotEmpty
                                      ? NetworkImage(imgUrl)
                                      : null,
                                  child: imgUrl.isEmpty
                                      ? Icon(Icons.person,
                                          size: 50.sp,
                                          color: Colors.grey.shade400)
                                      : null,
                                );
                              }
                            },
                          ),
                        ),
                        // زر الكاميرا للتعديل والاختيار
                        InkWell(
                          onTap: () => _showImageSourcePicker(
                              context), // 🟢 فتح قائمة الخيارات عند الضغط
                          borderRadius: BorderRadius.circular(50.r),
                          child: Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: goldAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 18.sp),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 40.h),

                  _buildCustomTextField(
                    label: 'الاسم بالكامل',
                    icon: Icons.person,
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                  ),

                  _buildCustomTextField(
                    label: 'رقم الهاتف',
                    icon: Icons.phone_android_rounded,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    isPhone: true,
                  ),

                  _buildCustomTextField(
                    label: 'الرقم القومي (اختياري)',
                    icon: Icons.credit_card_rounded,
                    controller: _nationalIdController,
                    keyboardType: TextInputType.number,
                  ),

                  SizedBox(height: 40.h),

                  SizedBox(
                    width: double.infinity,
                    height: 55.h,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.r),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'حفظ التعديلات',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16.sp,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required TextInputType keyboardType,
    bool isPhone = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: lightGreyBg,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryNavy, size: 22.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  textDirection:
                      isPhone ? TextDirection.ltr : TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: primaryNavy,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    errorStyle: TextStyle(height: 0.5),
                  ),
                  validator: (value) {
                    if (label != 'الرقم القومي (اختياري)' &&
                        (value == null || value.trim().isEmpty)) {
                      return 'هذا الحقل مطلوب';
                    }
                    if (isPhone && value != null && value.trim().length < 11) {
                      return 'رقم الهاتف يجب ألا يقل عن 11 رقم';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
