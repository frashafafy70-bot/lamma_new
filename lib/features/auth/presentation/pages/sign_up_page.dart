// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:auto_route/auto_route.dart';

// 🟢 استدعاء ملف اللغات
import 'package:lamma_new/l10n/app_localizations.dart';

// 🟢 استدعاء الثيم الموحد
import 'package:lamma_new/core/theme/app_theme.dart';
import 'package:lamma_new/core/routes/app_router.dart';

import '../../cubit/auth_cubit.dart';
import '../../cubit/auth_state.dart';

@RoutePage()
class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedRole = 'passenger';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // 🟢 دالة عرض الـ SnackBar مرتبطة بألوان الثيم
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
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🟢 دالة تنسيق الرقم
  String _formatPhone(String phone) {
    String formatted = phone.startsWith('0') ? phone.substring(1) : phone;
    return formatted.startsWith('+20') ? formatted : '+20$formatted';
  }

  void _validateAndSubmit(BuildContext context) {
    FocusScope.of(context).unfocus();
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String phone = _phoneController.text.trim();

    if (name.isEmpty) {
      _showFloatingSnackBar(l10n.fullNameRequiredError, colorScheme.error);
      return;
    }

    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showFloatingSnackBar(l10n.invalidEmailError, colorScheme.error);
      return;
    }

    if (phone.isEmpty || phone.length < 10) {
      _showFloatingSnackBar(l10n.invalidPhoneError, colorScheme.error);
      return;
    }

    context.read<AuthCubit>().sendSignUpOtp(phone: phone);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final extColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Scaffold(
      backgroundColor:
          Theme.of(context).scaffoldBackgroundColor, // 🟢 ربط الخلفية بالثيم
      body: SafeArea(
        child: BlocConsumer<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              _showFloatingSnackBar(state.message, colorScheme.error);
            } else if (state is AuthOtpSent) {
              _showFloatingSnackBar(l10n.otpSentSuccess, colorScheme.primary);

              // 🟢 استخدام AutoRoute وتمرير البيانات المنسقة
              context.router.push(
                OtpRoute(
                  verificationId: state.verificationId,
                  name: _nameController.text.trim(),
                  email: _emailController.text.trim(),
                  phone: _formatPhone(_phoneController.text.trim()),
                  role: _selectedRole,
                ),
              );
            } else if (state is AuthSuccess) {
              _showFloatingSnackBar(state.message ?? '', Colors.green);
              context.router.replaceAll([const HomeRoute()]); // 🟢 AutoRoute
            }
          },
          builder: (context, state) {
            bool isLoading = state is AuthLoading;

            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
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
                          context.router.maybePop();
                        },
                        icon: Icon(Icons.arrow_back_ios_new_rounded,
                            color: colorScheme.primary),
                      ),
                    ),
                    Icon(Icons.person_add_alt_1_rounded,
                        size: 70.sp, color: colorScheme.primary),
                    SizedBox(height: 20.h),
                    Text(
                      l10n.createNewAccount,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      l10n.joinLammaFamily,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14.sp, color: Colors.grey.shade600),
                    ),
                    SizedBox(height: 30.h),

                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () =>
                                    setState(() => _selectedRole = 'passenger'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'passenger'
                                    ? colorScheme.primary
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: _selectedRole == 'passenger'
                                        ? colorScheme.primary
                                        : Colors.grey.shade300,
                                    width: 1.5),
                                boxShadow: _selectedRole == 'passenger'
                                    ? [
                                        BoxShadow(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.2),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4))
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_rounded,
                                      color: _selectedRole == 'passenger'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      size: 22.sp),
                                  SizedBox(width: 8.w),
                                  Text(l10n.passengerRole,
                                      style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedRole == 'passenger'
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
                                    setState(() => _selectedRole = 'captain'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'captain'
                                    ? extColors.accentGold
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12.r),
                                border: Border.all(
                                    color: _selectedRole == 'captain'
                                        ? extColors.accentGold
                                        : Colors.grey.shade300,
                                    width: 1.5),
                                boxShadow: _selectedRole == 'captain'
                                    ? [
                                        BoxShadow(
                                            color: extColors.accentGold
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4))
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.directions_car_rounded,
                                      color: _selectedRole == 'captain'
                                          ? Colors.white
                                          : Colors.grey.shade600,
                                      size: 22.sp),
                                  SizedBox(width: 8.w),
                                  Text(l10n.captainRole,
                                      style: TextStyle(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                          color: _selectedRole == 'captain'
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

                    // حقل الاسم
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _nameController,
                        keyboardType: TextInputType.name,
                        enabled: !isLoading,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: l10n.fullNameHint,
                          hintStyle: TextStyle(
                              fontSize: 14.sp, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.person_outline_rounded,
                              color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 16.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // حقل البريد الإلكتروني
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 15.sp),
                        decoration: InputDecoration(
                          hintText: l10n.emailHint,
                          hintStyle: TextStyle(
                              fontSize: 14.sp, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.email_outlined,
                              color: Colors.grey.shade600),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w, vertical: 16.h),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),

                    // حقل الهاتف
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
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
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color),
                            ),
                          ),
                          Container(
                              width: 1.w,
                              height: 24.h,
                              color: Colors.grey.shade300),
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              enabled: !isLoading,
                              textDirection: TextDirection.ltr,
                              textAlign: TextAlign.left,
                              style:
                                  TextStyle(fontSize: 16.sp, letterSpacing: 1),
                              decoration: InputDecoration(
                                hintText: '10xxxxxxxxx',
                                hintStyle: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey.shade400,
                                    letterSpacing: 0),
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16.w),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 32.h),

                    // زر التسجيل
                    SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary, // 🟢 ربط بالثيم
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r)),
                          elevation: 0,
                        ),
                        onPressed: isLoading
                            ? null
                            : () => _validateAndSubmit(context),
                        child: isLoading
                            ? SizedBox(
                                height: 24.h,
                                width: 24.h,
                                child: const CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5))
                            : Text(l10n.registerNewAccount,
                                style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    Row(
                      children: [
                        Expanded(
                            child: Divider(
                                color: Colors.grey.shade300, thickness: 1)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Text(l10n.or,
                              style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 16.sp)),
                        ),
                        Expanded(
                            child: Divider(
                                color: Colors.grey.shade300, thickness: 1)),
                      ],
                    ),

                    SizedBox(height: 24.h),

                    // زر التسجيل بجوجل
                    SizedBox(
                      height: 56.h,
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : () {
                                context.read<AuthCubit>().loginWithGoogle();
                              },
                        borderRadius: BorderRadius.circular(12.r),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
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
                                  child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                      strokeWidth: 2.5),
                                )
                              else ...[
                                Image.asset(
                                  'assets/images/google.png',
                                  height: 24.h,
                                  width: 24.w,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                    height: 24.h,
                                    width: 24.w,
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Text(l10n.signUpWithGoogle,
                                    style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.color)),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 32.h),

                    Center(
                      child: GestureDetector(
                        onTap: isLoading
                            ? null
                            : () {
                                context.router.push(EmailSignUpRoute());
                              },
                        child: Text(
                          l10n.signUpWithEmailOnly,
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                              decoration: TextDecoration.underline),
                        ),
                      ),
                    ),

                    SizedBox(height: 40.h),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.alreadyHaveAccount,
                            style: TextStyle(
                                fontSize: 14.sp, color: Colors.grey.shade600)),
                        TextButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            context.router.maybePop();
                          },
                          child: Text(l10n.loginNow,
                              style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary)),
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
