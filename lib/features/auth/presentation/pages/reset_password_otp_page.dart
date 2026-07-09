// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🟢 استدعاء الـ Cubit والـ States
import '../../cubit/auth_cubit.dart';
import '../../cubit/auth_state.dart';

class ResetPasswordOtpPage extends StatefulWidget {
  final String verificationId;
  final String phone;

  const ResetPasswordOtpPage({
    super.key,
    required this.verificationId,
    required this.phone,
  });

  @override
  State<ResetPasswordOtpPage> createState() => _ResetPasswordOtpPageState();
}

class _ResetPasswordOtpPageState extends State<ResetPasswordOtpPage> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _isPasswordObscured = true;
  bool _isConfirmObscured = true;

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color accentGold = const Color(0xFFD4AF37);

  @override
  void dispose() {
    for (var controller in _otpControllers) { controller.dispose(); }
    for (var node in _focusNodes) { node.dispose(); }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _submitNewPassword() {
    FocusScope.of(context).unfocus();
    
    String smsCode = _otpControllers.map((c) => c.text).join();
    String newPassword = _newPasswordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (smsCode.length < 6) {
      _showFloatingSnackBar('برجاء إدخال كود التحقق كاملاً المكون من 6 أرقام', Colors.red.shade800);
      return;
    }
    
    if (newPassword.length < 6) {
      _showFloatingSnackBar('كلمة المرور يجب ألا تقل عن 6 أحرف', Colors.red.shade800);
      return;
    }

    if (newPassword != confirmPassword) {
      _showFloatingSnackBar('كلمات المرور غير متطابقة', Colors.red.shade800);
      return;
    }

    // 🟢 إرسال البيانات للـ Cubit ليتولى هو المهمة
    context.read<AuthCubit>().verifyOtpAndResetPassword(
      verificationId: widget.verificationId,
      smsCode: smsCode,
      newPassword: newPassword,
    );
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      else FocusScope.of(context).requestFocus(_focusNodes[5]); 
    } else {
      if (index > 0) FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: primaryNavy,
      ),
      // 🟢 ربط الشاشة بـ BlocConsumer للاستماع للنتيجة
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _showFloatingSnackBar(state.message ?? 'تم تغيير كلمة المرور بنجاح! 🎉 يرجى تسجيل الدخول.', Colors.green);
            
            // 🟢 التعديل الأهم: قفلنا التوجيه العنيف اللي كان بيعمل تضارب
            // وبداله بنقفل كل الشاشات الفرعية ونرجع للأساس، وبما إننا عملنا SignOut في الـ Cubit
            // ملف main.dart هيعرض الـ LoginPage تلقائياً بنظافة!
            Navigator.of(context).popUntil((route) => route.isFirst);
            
          } else if (state is AuthError) {
            _showFloatingSnackBar(state.message, Colors.red.shade800);
          }
        },
        builder: (context, state) {
          bool isLoading = state is AuthLoading;

          return SafeArea(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.password_rounded, size: 70.sp, color: primaryNavy),
                    SizedBox(height: 16.h),
                    Text(
                      'تعيين كلمة مرور جديدة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 26.sp, fontWeight: FontWeight.bold, color: primaryNavy),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'أدخل كود التحقق المرسل إلى ${widget.phone}\nثم قم بتعيين كلمة المرور الجديدة',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade600, height: 1.5),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 32.h),

                    // حقول الـ OTP
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 45.w,
                            height: 55.h,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12.r),
                              border: Border.all(
                                color: _focusNodes[index].hasFocus ? accentGold : Colors.grey.shade300,
                                width: _focusNodes[index].hasFocus ? 2 : 1,
                              ),
                              boxShadow: _focusNodes[index].hasFocus
                                  ? [BoxShadow(color: accentGold.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 1)]
                                  : [],
                            ),
                            child: TextField(
                              controller: _otpControllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              enabled: !isLoading,
                              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: primaryNavy),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(counterText: "", border: InputBorder.none),
                              onChanged: (value) => _onOtpChanged(value, index),
                            ),
                          );
                        }),
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // حقل كلمة المرور الجديدة
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _newPasswordController,
                          obscureText: _isPasswordObscured,
                          enabled: !isLoading,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText: 'كلمة المرور الجديدة',
                            hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade400),
                            prefixIcon: IconButton(
                              icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade600),
                              onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // حقل تأكيد كلمة المرور الجديدة
                    Directionality(
                      textDirection: TextDirection.rtl,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _confirmPasswordController,
                          obscureText: _isConfirmObscured,
                          enabled: !isLoading,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText: 'تأكيد كلمة المرور',
                            hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade400),
                            prefixIcon: IconButton(
                              icon: Icon(_isConfirmObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey.shade600),
                              onPressed: () => setState(() => _isConfirmObscured = !_isConfirmObscured),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                          ),
                        ),
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
                        onPressed: isLoading ? null : _submitNewPassword,
                        child: isLoading
                            ? SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('حفظ وتسجيل الدخول', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
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