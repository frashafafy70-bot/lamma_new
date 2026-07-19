// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🟢 استدعاء ملف اللغات
import 'package:lamma_new/l10n/app_localizations.dart';

// 🟢 استدعاء الـ AutoRoute
import 'package:auto_route/auto_route.dart';
import 'package:lamma_new/core/extensions/context_extension.dart';

import '../../cubit/auth_cubit.dart';
import '../../cubit/auth_state.dart';
import 'reset_password_otp_page.dart';

@RoutePage() // 🟢 الديكوريتور السحري
class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String _selectedMethod = 'email';

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  void _showFloatingSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 20.h, left: 20.w, right: 20.w),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _sendPasswordReset() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    if (_selectedMethod == 'email') {
      String email = _emailController.text.trim();
      context.read<AuthCubit>().sendPasswordResetEmail(email: email);
    } else {
      String inputPhone = _phoneController.text.trim();
      String fullPhone = inputPhone.startsWith('+20')
          ? inputPhone
          : '+20${inputPhone.replaceFirst(RegExp(r'^0+'), '')}';
      context.read<AuthCubit>().sendPasswordResetOtp(phone: fullPhone);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryNavy,
        title: Text(l10n.forgotPasswordAppBar,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            _showFloatingSnackBar(l10n.activationCodeSentMsg, Colors.green);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResetPasswordOtpPage(
                  verificationId: state.verificationId,
                  phone: _phoneController.text.trim(),
                ),
              ),
            );
          } else if (state is AuthSuccess) {
            _showFloatingSnackBar(
                state.message ?? l10n.sendSuccess, Colors.green);
            // 🟢 استخدام auto_route للرجوع بأمان
            context.router.maybePop();
          } else if (state is AuthError) {
            _showFloatingSnackBar(state.message, Colors.red.shade800);
          }
        },
        builder: (context, state) {
          bool isLoading = state is AuthLoading;

          return Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phonelink_lock_rounded,
                        size: 80.sp, color: goldAccent),
                    SizedBox(height: 24.h),
                    Text(
                      l10n.forgotPasswordHeader,
                      style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: primaryNavy),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      l10n.forgotPasswordDescription,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                          height: 1.5),
                    ),
                    SizedBox(height: 32.h),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () =>
                                    setState(() => _selectedMethod = 'email'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: _selectedMethod == 'email'
                                    ? primaryNavy
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: _selectedMethod == 'email'
                                        ? primaryNavy
                                        : Colors.grey.shade300,
                                    width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.email_outlined,
                                      color: _selectedMethod == 'email'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Text(l10n.emailMethod,
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedMethod == 'email'
                                              ? Colors.white
                                              : Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () =>
                                    setState(() => _selectedMethod = 'phone'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              decoration: BoxDecoration(
                                color: _selectedMethod == 'phone'
                                    ? primaryNavy
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: _selectedMethod == 'phone'
                                        ? primaryNavy
                                        : Colors.grey.shade300,
                                    width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.phone_android_rounded,
                                      color: _selectedMethod == 'phone'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      size: 20.sp),
                                  SizedBox(width: 8.w),
                                  Text(l10n.phoneMethod,
                                      style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedMethod == 'phone'
                                              ? Colors.white
                                              : Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),
                    if (_selectedMethod == 'email')
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: TextStyle(fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText: l10n.emailExampleHint,
                            hintStyle: TextStyle(
                                fontSize: 14.sp, color: Colors.grey.shade400),
                            prefixIcon: Icon(Icons.email_outlined,
                                color: Colors.grey.shade600),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w, vertical: 16.h),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                !value.contains('@')) {
                              return l10n.invalidEmailError;
                            }
                            return null;
                          },
                        ),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15.r),
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
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ),
                            Container(
                                width: 1.w,
                                height: 24.h,
                                color: Colors.grey.shade300),
                            Expanded(
                              child: TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textDirection: TextDirection.ltr,
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                    fontSize: 16.sp, letterSpacing: 1),
                                decoration: InputDecoration(
                                  hintText: l10n.phoneExampleHint,
                                  hintStyle: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade400,
                                      letterSpacing: 0),
                                  border: InputBorder.none,
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 16.w),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      value.length < 10) {
                                    return l10n.invalidPhoneError;
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24.h),
                    SizedBox(
                      width: double.infinity,
                      height: 55.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.r)),
                        ),
                        onPressed: isLoading ? null : _sendPasswordReset,
                        child: isLoading
                            ? SizedBox(
                                height: 24.h,
                                width: 24.h,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Text(
                                _selectedMethod == 'email'
                                    ? l10n.sendResetLink
                                    : l10n.sendVerificationCode,
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
