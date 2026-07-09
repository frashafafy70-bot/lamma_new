// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubit/auth_cubit.dart'; 
import '../../cubit/auth_state.dart'; 
import '../../../home/home_page.dart'; 
import 'email_sign_up_page.dart'; 
import 'otp_page.dart'; 

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(); // 🟢 حقل الإيميل الجديد
  final TextEditingController _phoneController = TextEditingController();
  
  String _selectedRole = 'passenger';
  
  final Color primaryNavy = const Color(0xFF0F172A); 
  final Color accentGold = const Color(0xFFD4AF37); 

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showFloatingSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar(); 
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)), 
        backgroundColor: color,
        behavior: SnackBarBehavior.floating, 
        margin: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w), 
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)), 
        duration: const Duration(seconds: 2), 
      ),
    );
  }

  void _validateAndSubmit(BuildContext context) {
    FocusScope.of(context).unfocus(); 
    
    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showFloatingSnackBar('برجاء كتابة الاسم بالكامل', Colors.red);
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showFloatingSnackBar('برجاء إدخال بريد إلكتروني صحيح', Colors.red);
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      _showFloatingSnackBar('برجاء إدخال رقم هاتف صحيح', Colors.red);
      return;
    }

    context.read<AuthCubit>().sendSignUpOtp(phone: phone);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              _showFloatingSnackBar(state.message, Colors.red);
            } else if (state is AuthOtpSent) {
              _showFloatingSnackBar('تم إرسال كود التحقق بنجاح! 💬', primaryNavy);
              
              String formattedPhoneToPass = _phoneController.text.trim();
              if (formattedPhoneToPass.startsWith('0')) {
                formattedPhoneToPass = formattedPhoneToPass.substring(1);
              }
              if (!formattedPhoneToPass.startsWith('+20')) {
                formattedPhoneToPass = '+20$formattedPhoneToPass';
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OtpPage(
                    verificationId: state.verificationId,
                    name: _nameController.text.trim(),
                    email: _emailController.text.trim(), // 🟢 إرسال الإيميل للـ OTP
                    phone: formattedPhoneToPass, 
                    role: _selectedRole, 
                  ),
                ),
              );
            } else if (state is AuthSuccess) {
              _showFloatingSnackBar(state.message ?? '', Colors.green);
              if (state.role == 'captain' || state.role == 'كابتن') {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
              } else {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
              }
            }
          },
          builder: (context, state) {
            bool isLoading = state is AuthLoading;

            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 30.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 10.h),
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryNavy),
                      ),
                    ),
                    Icon(Icons.person_add_alt_1_rounded, size: 70.sp, color: primaryNavy), 
                    SizedBox(height: 20.h),
                    Text(
                      'إنشاء حساب جديد',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 28.sp, fontWeight: FontWeight.bold, color: primaryNavy),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'انضم إلى عائلة لَمَّة واستمتع بكافة الخدمات',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 30.h),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading ? null : () => setState(() => _selectedRole = 'passenger'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'passenger' ? primaryNavy : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: _selectedRole == 'passenger' ? primaryNavy : Colors.grey.shade300, width: 1.5),
                                boxShadow: _selectedRole == 'passenger' ? [BoxShadow(color: primaryNavy.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))] : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_rounded, color: _selectedRole == 'passenger' ? Colors.white : Colors.grey.shade600, size: 22.sp),
                                  SizedBox(width: 8.w),
                                  Text('راكب', style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.bold, color: _selectedRole == 'passenger' ? Colors.white : Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading ? null : () => setState(() => _selectedRole = 'captain'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'captain' ? accentGold : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(color: _selectedRole == 'captain' ? accentGold : Colors.grey.shade300, width: 1.5),
                                boxShadow: _selectedRole == 'captain' ? [BoxShadow(color: accentGold.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_car_rounded, color: _selectedRole == 'captain' ? Colors.white : Colors.grey.shade600, size: 22.sp),
                                  SizedBox(width: 8.w),
                                  Text('كابتن', style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.bold, color: _selectedRole == 'captain' ? Colors.white : Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        enabled: !isLoading,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: 'الاسم بالكامل',
                          hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.person_outline_rounded, color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // 🟢 حقل البريد الإلكتروني
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: 'البريد الإلكتروني',
                          hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        textDirection: TextDirection.rtl,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              '+20', 
                              textDirection: TextDirection.ltr, 
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                          Container(width: 1.w, height: 24.h, color: Colors.grey.shade300),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !isLoading,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, letterSpacing: 1),
                              decoration: InputDecoration(
                                hintText: '10xxxxxxxxx',
                                hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade400, letterSpacing: 0),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : () => _validateAndSubmit(context),
                        child: isLoading 
                            ? SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('تسجيل حساب جديد', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text('أو', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade500, fontSize: 16.sp)),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    SizedBox(
                      height: 56.h,
                      child: InkWell(
                        onTap: isLoading ? null : () {
                          context.read<AuthCubit>().loginWithGoogle();
                        },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (isLoading)
                                SizedBox(
                                  height: 24.h,
                                  width: 24.h,
                                  child: CircularProgressIndicator(color: primaryNavy, strokeWidth: 2.5),
                                )
                              else ...[
                                Image.asset(
                                  'assets/images/google.png', 
                                  height: 24.h, 
                                  width: 24.w,
                                  errorBuilder: (context, error, stackTrace) => Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                    height: 24.h,
                                    width: 24.w,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text('التسجيل باستخدام Google', style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.black87)),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    Center(
                      child: GestureDetector(
                        onTap: isLoading ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EmailSignUpPage()), 
                          );
                        },
                        child: Text(
                          'التسجيل باستخدام البريد الإلكتروني فقط',
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.w500, color: primaryNavy, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),

                    SizedBox(height: 40.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('لديك حساب بالفعل؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            Navigator.pop(context); 
                          },
                          child: Text('تسجيل الدخول', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: primaryNavy)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}