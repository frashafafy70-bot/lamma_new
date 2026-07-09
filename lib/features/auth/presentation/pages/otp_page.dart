// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../cubit/auth_cubit.dart';
import '../../cubit/auth_state.dart';
import '../../../home/home_page.dart';

// 🟢 استدعي هنا الصفحة اللي المستخدم بيكتب فيها الباسورد والايميل (غالباً اسمها EmailSignUpPage)
import 'email_sign_up_page.dart'; 

class OtpPage extends StatefulWidget {
  final String verificationId;
  final String name;
  final String email; // 🟢 تم إضافة الإيميل هنا
  final String phone;
  final String role; 

  const OtpPage({
    super.key,
    required this.verificationId,
    required this.name,
    required this.email, // 🟢 تم استقبال الإيميل
    required this.phone,
    required this.role, 
  });

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color accentGold = const Color(0xFFD4AF37);

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
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

  void _verifyOtp() {
    FocusScope.of(context).unfocus();
    String smsCode = _controllers.map((c) => c.text).join();

    if (smsCode.length < 6) {
      _showFloatingSnackBar('برجاء إدخال كود التحقق كاملاً المكون من 6 أرقام', Colors.red);
      return;
    }

    // 🟢 هنا التعديل: بننادي على دالة التحقق من الـ OTP فقط، مش دالة استكمال التسجيل
    context.read<AuthCubit>().verifyOtp(
      verificationId: widget.verificationId,
      smsCode: smsCode,
    );
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < 5) {
        FocusScope.of(context).requestFocus(_focusNodes[index + 1]);
      } else {
        FocusScope.of(context).unfocus();
      }
    } else {
      if (index > 0) {
        FocusScope.of(context).requestFocus(_focusNodes[index - 1]);
      }
    }
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
            } 
            // 🟢 لو الحساب قديم وموجود، هيدخل الرئيسية علطول
            else if (state is AuthSuccess) {
              _showFloatingSnackBar(state.message ?? 'تم تسجيل الدخول بنجاح', Colors.green);
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
            } 
            // 🟢 لو ده حساب جديد (الـ OTP صح بس لسه مفيش باسورد)، هيوجهه لصفحة استكمال البيانات
            else if (state is AuthNeedsPasswordAndProfile) {
              _showFloatingSnackBar('تم تأكيد الرقم بنجاح، يرجى كتابة كلمة المرور', Colors.green);
              
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => EmailSignUpPage( 
                    name: widget.name,
                    email: widget.email, // 🟢 تم تمرير الإيميل للصفحة اللي بعدها
                    phone: widget.phone,
                    role: widget.role,
                  ),
                ),
              );
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
                    SizedBox(height: 20.h),
                    
                    Container(
                      padding: EdgeInsets.all(20.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryNavy.withValues(alpha: 0.05),
                      ),
                      child: Icon(Icons.mark_email_read_rounded, size: 70.sp, color: primaryNavy),
                    ),
                    SizedBox(height: 24.h),
                    
                    Text(
                      'تأكيد رقم الهاتف',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 28.sp, fontWeight: FontWeight.bold, color: primaryNavy),
                    ),
                    SizedBox(height: 12.h),
                    
                    Text(
                      'أدخل كود التحقق المكون من 6 أرقام\nالذي تم إرساله إلى الرقم ${widget.phone}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, color: Colors.grey.shade600, height: 1.5),
                      textDirection: TextDirection.rtl,
                    ),
                    SizedBox(height: 40.h),

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
                              controller: _controllers[index],
                              focusNode: _focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              enabled: !isLoading,
                              style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: primaryNavy),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: const InputDecoration(
                                counterText: "",
                                border: InputBorder.none,
                              ),
                              onChanged: (value) => _onChanged(value, index),
                            ),
                          );
                        }),
                      ),
                    ),
                    
                    SizedBox(height: 40.h),

                    SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _verifyOtp,
                        child: isLoading
                            ? SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('تحقق وتفعيل الحساب', style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('لم يصلك الكود؟', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: isLoading ? null : () {
                            _showFloatingSnackBar('جاري إعادة الإرسال...', primaryNavy);
                            context.read<AuthCubit>().sendSignUpOtp(phone: widget.phone);
                            for (var controller in _controllers) {
                              controller.clear();
                            }
                            FocusScope.of(context).requestFocus(_focusNodes[0]);
                          },
                          child: Text('إعادة إرسال', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, fontWeight: FontWeight.bold, color: primaryNavy, decoration: TextDecoration.underline)),
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