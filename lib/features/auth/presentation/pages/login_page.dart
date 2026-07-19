// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// 🟢 استدعاء ملف اللغات
import 'package:lamma_new/l10n/app_localizations.dart';

// 🟢 استدعاءات الـ AutoRoute والثيم
import 'package:auto_route/auto_route.dart';
import 'package:lamma_new/core/routes/app_router.dart';
import 'package:lamma_new/core/theme/app_theme.dart'; // تم إضافة الثيم الموحد
import 'package:lamma_new/core/extensions/context_extension.dart';

import '../../cubit/auth_cubit.dart';
import '../../cubit/auth_state.dart';

@RoutePage()
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  TextEditingController? _autoCompleteController;

  bool _isPasswordObscured = true;
  bool _rememberMe = false;

  List<String> _savedIdentifiersList = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? savedList = prefs.getStringList('saved_identifiers_list');

    if (savedList != null && savedList.isNotEmpty) {
      setState(() {
        _savedIdentifiersList = savedList;
        _identifierController.text = savedList.first;
        _rememberMe = true;
      });

      if (_autoCompleteController != null) {
        _autoCompleteController!.text = savedList.first;
      }
    }
  }

  Future<void> _savePreferencesLocally(String currentInput) async {
    if (_rememberMe) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_savedIdentifiersList.contains(currentInput)) {
        _savedIdentifiersList.remove(currentInput);
      }
      _savedIdentifiersList.insert(0, currentInput);
      await prefs.setStringList(
          'saved_identifiers_list', _savedIdentifiersList);
    }
  }

  void _login() {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    context.read<AuthCubit>().login(
          email: _identifierController.text.trim(),
          password: _passwordController.text.trim(),
        );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // 🟢 استخراج الألوان من الثيم الموحد
    final extColors = Theme.of(context).extension<AppColorsExtension>()!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _savePreferencesLocally(_identifierController.text.trim());
            _showSnackBar(state.message, Colors.green);

            // 🟢 التوجيه باستخدام AutoRoute
            context.router.replaceAll([const HomeRoute()]);
          } else if (state is AuthError) {
            _showSnackBar(state.message, colorScheme.error);
          }
        },
        builder: (context, state) {
          bool isLoading = state is AuthLoading;

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                  // 🟢 استخدام ألوان الثيم للخلفية المتدرجة
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [colorScheme.primary, extColors.royalGreen])),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo Section
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  extColors.accentGold.withValues(alpha: 0.1),
                              border: Border.all(
                                  color: extColors.accentGold, width: 2)),
                          child: Icon(Icons.widgets_rounded,
                              size: 60.sp, color: extColors.accentGold),
                        ),
                        SizedBox(height: 24.h),
                        Text(l10n.lammaPlatform,
                            style: TextStyle(
                                fontSize: 28.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontFamily: 'Cairo')),
                        SizedBox(height: 8.h),
                        Text(l10n.loginSubtitle,
                            style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white70,
                                fontFamily: 'Cairo')),
                        SizedBox(height: 40.h),

                        // Form Section
                        Card(
                          elevation: 8,
                          shadowColor:
                              colorScheme.shadow.withValues(alpha: 0.3),
                          color: Theme.of(context)
                              .cardColor, // 🟢 ربط الكارت بالثيم
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.r)),
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(l10n.loginTitle,
                                      style: TextStyle(
                                          fontSize: 20.sp,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.color,
                                          fontFamily: 'Cairo')),
                                  SizedBox(height: 20.h),
                                  Autocomplete<String>(
                                    optionsBuilder:
                                        (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text == '')
                                        return _savedIdentifiersList;
                                      return _savedIdentifiersList.where(
                                          (String option) => option
                                              .toLowerCase()
                                              .contains(textEditingValue.text
                                                  .toLowerCase()));
                                    },
                                    onSelected: (String selection) =>
                                        _identifierController.text = selection,
                                    fieldViewBuilder: (BuildContext context,
                                        TextEditingController
                                            fieldTextEditingController,
                                        FocusNode fieldFocusNode,
                                        VoidCallback onFieldSubmitted) {
                                      if (_autoCompleteController !=
                                          fieldTextEditingController) {
                                        _autoCompleteController =
                                            fieldTextEditingController;
                                        if (_identifierController
                                                .text.isNotEmpty &&
                                            _autoCompleteController!
                                                .text.isEmpty) {
                                          WidgetsBinding.instance
                                              .addPostFrameCallback((_) =>
                                                  _autoCompleteController!
                                                          .text =
                                                      _identifierController
                                                          .text);
                                        }
                                        _autoCompleteController!.addListener(
                                            () => _identifierController.text =
                                                _autoCompleteController!.text);
                                      }

                                      return TextFormField(
                                        controller: fieldTextEditingController,
                                        focusNode: fieldFocusNode,
                                        textDirection: TextDirection.ltr,
                                        textInputAction: TextInputAction.next,
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            fontFamily: 'Cairo'),
                                        decoration: InputDecoration(
                                          labelText: l10n.identifierLabel,
                                          labelStyle:
                                              TextStyle(fontSize: 14.sp),
                                          prefixIcon: Icon(
                                              Icons.how_to_reg_rounded,
                                              color: colorScheme.primary,
                                              size: 24.sp),
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r)),
                                          focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.r),
                                              borderSide: BorderSide(
                                                  color: extColors.accentGold,
                                                  width: 2)),
                                          suffixIcon: fieldTextEditingController
                                                  .text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.clear,
                                                      size: 20.sp),
                                                  onPressed: () {
                                                    fieldTextEditingController
                                                        .clear();
                                                    _identifierController
                                                        .clear();
                                                    setState(() {});
                                                  },
                                                )
                                              : null,
                                        ),
                                        validator: (value) =>
                                            (value == null || value.isEmpty)
                                                ? l10n.emptyIdentifierError
                                                : null,
                                      );
                                    },
                                    optionsViewBuilder: (BuildContext context,
                                        AutocompleteOnSelected<String>
                                            onSelected,
                                        Iterable<String> options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4.0,
                                          borderRadius:
                                              BorderRadius.circular(12.r),
                                          color: Theme.of(context).cardColor,
                                          child: SizedBox(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width -
                                                96.w,
                                            child: ListView.builder(
                                              padding: EdgeInsets.all(8.w),
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder:
                                                  (BuildContext context,
                                                      int index) {
                                                final String option =
                                                    options.elementAt(index);
                                                return InkWell(
                                                  onTap: () =>
                                                      onSelected(option),
                                                  child: Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 12.h,
                                                            horizontal: 16.w),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.history,
                                                            size: 18.sp,
                                                            color: Colors
                                                                .grey.shade600),
                                                        SizedBox(width: 12.w),
                                                        Expanded(
                                                            child: Text(option,
                                                                textDirection:
                                                                    TextDirection
                                                                        .ltr,
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    fontSize: 14
                                                                        .sp))),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: 16.h),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _isPasswordObscured,
                                    textDirection: TextDirection.ltr,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    style: TextStyle(
                                        fontSize: 14.sp, fontFamily: 'Cairo'),
                                    decoration: InputDecoration(
                                        labelText: l10n.passwordLabel,
                                        labelStyle: TextStyle(fontSize: 14.sp),
                                        prefixIcon: Icon(
                                            Icons.lock_outline_rounded,
                                            color: colorScheme.primary,
                                            size: 24.sp),
                                        suffixIcon: IconButton(
                                            icon: Icon(
                                                _isPasswordObscured
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                color: Colors.grey,
                                                size: 24.sp),
                                            onPressed: () => setState(() =>
                                                _isPasswordObscured =
                                                    !_isPasswordObscured)),
                                        border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r)),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.r),
                                            borderSide: BorderSide(color: extColors.accentGold, width: 2))),
                                    validator: (value) =>
                                        (value == null || value.isEmpty)
                                            ? l10n.emptyPasswordError
                                            : null,
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        activeColor: colorScheme.primary,
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4.r)),
                                        onChanged: (value) => setState(
                                            () => _rememberMe = value ?? false),
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(
                                            () => _rememberMe = !_rememberMe),
                                        child: Text(l10n.rememberMe,
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.sp,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color)),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () => context.router
                                            .push(const ForgotPasswordRoute()),
                                        child: Text(l10n.forgotPassword,
                                            style: TextStyle(
                                                color: colorScheme.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.sp)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  ElevatedButton(
                                    onPressed: isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16.h),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12.r)),
                                      elevation: 0,
                                    ),
                                    child: isLoading &&
                                            _passwordController.text.isNotEmpty
                                        ? SizedBox(
                                            height: 24.h,
                                            width: 24.w,
                                            child:
                                                const CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2.5))
                                        : Text(l10n.loginButton,
                                            style: TextStyle(
                                                fontSize: 18.sp,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'Cairo')),
                                  ),
                                  SizedBox(height: 16.h),
                                  Row(
                                    children: [
                                      Expanded(
                                          child: Divider(
                                              color: Colors.grey.shade300,
                                              thickness: 1)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16.w),
                                        child: Text(l10n.or,
                                            style: TextStyle(
                                                color: Colors.grey.shade500,
                                                fontSize: 14.sp)),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: Colors.grey.shade300,
                                              thickness: 1)),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                  ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => context
                                            .read<AuthCubit>()
                                            .loginWithGoogle(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Theme.of(context).cardColor,
                                      surfaceTintColor:
                                          Theme.of(context).cardColor,
                                      padding:
                                          EdgeInsets.symmetric(vertical: 14.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.r),
                                        side: BorderSide(
                                            color: Colors.grey.shade300),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isLoading &&
                                            _passwordController.text.isEmpty
                                        ? SizedBox(
                                            height: 24.h,
                                            width: 24.w,
                                            child: CircularProgressIndicator(
                                                color: colorScheme.primary,
                                                strokeWidth: 2.5))
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/images/google.png',
                                                height: 24.h,
                                                width: 24.w,
                                                errorBuilder: (context, error,
                                                        stackTrace) =>
                                                    Image.network(
                                                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                                                  height: 24.h,
                                                  width: 24.w,
                                                ),
                                              ),
                                              SizedBox(width: 12.w),
                                              Text(l10n.loginWithGoogle,
                                                  style: TextStyle(
                                                      fontSize: 16.sp,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyLarge
                                                          ?.color,
                                                      fontFamily: 'Cairo')),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 24.h),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(l10n.noAccount,
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14.sp)),
                            TextButton(
                              onPressed: () =>
                                  context.router.push(const SignUpRoute()),
                              child: Text(l10n.registerNow,
                                  style: TextStyle(
                                      color: extColors.accentGold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.sp,
                                      fontFamily: 'Cairo')),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
