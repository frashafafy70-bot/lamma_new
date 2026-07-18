// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

// 🟢 استدعاء ملف اللغات
import 'package:lamma_new/l10n/app_localizations.dart';

import '../../cubit/auth_cubit.dart'; 
import '../../cubit/auth_state.dart'; 
import '../../../home/home_page.dart'; 

class EmailSignUpPage extends StatefulWidget {
  // 🟢 استقبال البيانات من شاشة الـ OTP بما فيها الإيميل
  final String? name;
  final String? phone;
  final String? email; // 🟢 تم إضافة الإيميل هنا
  final String? role;

  const EmailSignUpPage({
    super.key, 
    this.name, 
    this.phone, 
    this.email, // 🟢 تم الاستقبال
    this.role
  });

  @override
  State<EmailSignUpPage> createState() => _EmailSignUpPageState();
}

class _EmailSignUpPageState extends State<EmailSignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordObscured = true;
  String _selectedRole = 'passenger'; 

  final Color primaryNavy = const Color(0xFF0F172A); 
  final Color accentGold = const Color(0xFFD4AF37); 

  @override
  void initState() {
    super.initState();
    // 🟢 تعبئة البيانات تلقائياً لو جاية من شاشة الـ OTP
    if (widget.name != null) _nameController.text = widget.name!;
    if (widget.email != null) _emailController.text = widget.email!; // 🟢 تعبئة الإيميل تلقائياً
    if (widget.role != null) _selectedRole = widget.role!;
    if (widget.phone != null) {
      String formattedPhone = widget.phone!;
      if (formattedPhone.startsWith('+20')) {
        formattedPhone = formattedPhone.substring(3);
      }
      _phoneController.text = formattedPhone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  void _validateAndSubmit() {
    FocusScope.of(context).unfocus(); 
    
    final l10n = AppLocalizations.of(context)!;
    
    String name = _nameController.text.trim();
    String phone = _phoneController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || password.isEmpty) {
      _showFloatingSnackBar(l10n.fillAllFieldsError, Colors.red);
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showFloatingSnackBar(l10n.invalidEmailError, Colors.red);
      return;
    }
    
    if (password.length < 6) {
      _showFloatingSnackBar(l10n.passwordLengthError, Colors.red);
      return;
    }

    // 🟢 التفريق بين التسجيل المباشر واستكمال البيانات بعد الـ OTP
    if (FirebaseAuth.instance.currentUser != null) {
      // المستخدم أكد رقمه بالفعل، هنستكمل بياناته بس
      context.read<AuthCubit>().completeRegistration(
        email: email, 
        password: password, 
        name: name, 
        phone: phone,
        role: _selectedRole,
      );
    } else {
      // المستخدم داخل يسجل بالإيميل مباشرة من غير OTP
      context.read<AuthCubit>().signUp(
        email: email, 
        password: password, 
        name: name, 
        phone: phone,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              _showFloatingSnackBar(state.message, Colors.red);
            } else if (state is AuthSuccess) {
              _showFloatingSnackBar(state.message ?? l10n.registrationSuccess, Colors.green);
              
              if (state.role == 'captain' || state.role == 'كابتن' || _selectedRole == 'captain') {
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
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
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
                    Icon(Icons.alternate_email_rounded, size: 60.sp, color: primaryNavy), 
                    SizedBox(height: 16.h),
                    Text(
                      l10n.completeDataTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 26.sp, fontWeight: FontWeight.bold, color: primaryNavy),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.completeDataSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 24.h),

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
                                  Text(l10n.passengerRole, style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.bold, color: _selectedRole == 'passenger' ? Colors.white : Colors.grey.shade700)),
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
                                  Text(l10n.captainRole, style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp, fontWeight: FontWeight.bold, color: _selectedRole == 'captain' ? Colors.white : Colors.grey.shade700)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24.h),

                    _buildTextField(
                      controller: _nameController, 
                      hintText: l10n.fullNameHint, 
                      icon: Icons.person_outline_rounded,
                      isLoading: isLoading,
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
                            child: Text('+20', textDirection: TextDirection.ltr, style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                    SizedBox(height: 16.h),

                    _buildTextField(
                      controller: _emailController, 
                      hintText: l10n.emailHint, 
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      isLoading: isLoading,
                    ),
                    SizedBox(height: 16.h),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _isPasswordObscured,
                        enabled: !isLoading,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: l10n.passwordLabel,
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
                    SizedBox(height: 32.h),

                    SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryNavy,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        onPressed: isLoading ? null : _validateAndSubmit,
                        child: isLoading 
                            ? SizedBox(height: 24.h, width: 24.h, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text(l10n.saveAndActivate, style: TextStyle(fontFamily: 'Cairo', fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller, 
    required String hintText, 
    required IconData icon, 
    TextInputType keyboardType = TextInputType.text,
    TextDirection? textDirection,
    TextAlign textAlign = TextAlign.right,
    required bool isLoading,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        enabled: !isLoading,
        textAlign: textAlign,
        textDirection: textDirection,
        style: TextStyle(fontFamily: 'Cairo', fontSize: 15.sp),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: Colors.grey.shade400),
          prefixIcon: Icon(icon, color: Colors.grey.shade600),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
      ),
    );
  }
}