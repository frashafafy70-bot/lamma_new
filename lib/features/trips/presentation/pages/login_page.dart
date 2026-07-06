// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamma_new/core/theme/app_colors.dart';

// استدعاء ملف الـ Cubit
import 'package:lamma_new/features/auth/cubit/login_cubit.dart';

// استدعاء الشاشات الأخرى
import 'package:lamma_new/features/home/views/home_main_view.dart'; // مسار صفحة الرئيسية
import 'package:lamma_new/features/auth/presentation/pages/forgot_password_page.dart'; // مسار صفحة نسيت كلمة المرور

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  final Color _primaryNavy = const Color(0xFF111827);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        backgroundColor: isError ? Colors.red.shade700 : AppColors.royalGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: BlocConsumer<LoginCubit, LoginState>(
            listener: (context, state) {
              if (state is LoginError) {
                _showSnackBar(state.errorMessage, isError: true);
              } else if (state is LoginSuccess) {
                _showSnackBar('تم تسجيل الدخول بنجاح! 🚀', isError: false);
                // التوجيه إلى الشاشة الرئيسية بعد النجاح
                // تأكد من استدعاء اسم كلاس الرئيسية الخاص بك هنا بشكل صحيح (مثلاً HomePage)
                // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
              }
            },
            builder: (context, state) {
              final bool isLoading = state is LoginLoading;

              return SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 40.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // اللوجو أو أيقونة ترحيبية
                        Icon(
                          Icons.account_circle_rounded,
                          size: 100.sp,
                          color: AppColors.accentGold,
                        ),
                        SizedBox(height: 24.h),

                        Text(
                          'مرحباً بك في لَمَّة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: _primaryNavy,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          'سجل دخولك للمتابعة',
                          style: TextStyle(
                            fontFamily: 'Cairo',
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 40.h),

                        // حقل البريد الإلكتروني
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: _primaryNavy),
                            decoration: InputDecoration(
                              hintText: 'البريد الإلكتروني',
                              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade400),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.email_outlined, color: _primaryNavy, size: 22.sp),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),

                        // حقل كلمة المرور
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: _primaryNavy),
                            decoration: InputDecoration(
                              hintText: 'كلمة المرور',
                              hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 13.sp, color: Colors.grey.shade400),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: _primaryNavy, size: 22.sp),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                                  color: Colors.grey.shade500,
                                  size: 20.sp,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                            ),
                          ),
                        ),
                        SizedBox(height: 12.h),

                        // زر نسيت كلمة المرور
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                              );
                            },
                            child: Text(
                              'نسيت كلمة المرور؟',
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                color: _primaryNavy,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        // زر تسجيل الدخول (مزج الأخضر الملكي والكحلي)
                        Container(
                          height: 55.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppColors.royalGreen, _primaryNavy],
                              begin: Alignment.centerRight,
                              end: Alignment.centerLeft,
                            ),
                            borderRadius: BorderRadius.circular(16.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.royalGreen.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                            ),
                            onPressed: isLoading
                                ? null
                                : () {
                                    FocusScope.of(context).unfocus();
                                    context.read<LoginCubit>().loginUser(
                                          email: _emailController.text,
                                          password: _passwordController.text,
                                        );
                                  },
                            child: isLoading
                                ? SizedBox(
                                    width: 25.w,
                                    height: 25.w,
                                    child: const CircularProgressIndicator(color: AppColors.accentGold, strokeWidth: 3),
                                  )
                                : Text(
                                    'تسجيل الدخول',
                                    style: TextStyle(
                                      fontFamily: 'Cairo',
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentGold, // النص باللون الذهبي
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}