// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../home/home_page.dart'; 
import '../../cubit/auth_cubit.dart'; 
import '../../cubit/auth_state.dart'; 
import 'sign_up_page.dart'; 
import 'forgot_password_page.dart'; 

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordObscured = true;
  bool _rememberMe = false; 

  // المحافظة على ألوان الشاشة وتناسقها مع الثيم الخاص بك
  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

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
    }
  }

  Future<String?> _resolveEmail(String input) async {
    input = input.trim();
    if (input.contains('@') && input.contains('.')) {
      return input;
    }
    
    if (RegExp(r'^\d+$').hasMatch(input)) {
      final query = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: input).limit(1).get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['email'] as String?;
      }
    } else {
      final query = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: input.toLowerCase()).limit(1).get();
      if (query.docs.isNotEmpty) {
        return query.docs.first.data()['email'] as String?;
      }
    }
    return null;
  }

  Future<void> _savePreferencesLocally(String currentInput) async {
    if (_rememberMe) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      if (_savedIdentifiersList.contains(currentInput)) {
        _savedIdentifiersList.remove(currentInput);
      }
      _savedIdentifiersList.insert(0, currentInput); 
      await prefs.setStringList('saved_identifiers_list', _savedIdentifiersList);
      await prefs.remove('saved_identifier');
      await prefs.remove('saved_password');
    }
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    String currentInput = _identifierController.text.trim();
    String? loginEmail = await _resolveEmail(currentInput);
    
    if (loginEmail == null) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('لم يتم العثور على حساب بهذا المُدخل، تأكد من البيانات.', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.red.shade800));
      return;
    }

    if (mounted) {
      context.read<AuthCubit>().login(
        email: loginEmail,
        password: _passwordController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            _savePreferencesLocally(_identifierController.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.green),
            );
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const HomePage()), (route) => false);
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message, style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.red.shade800),
            );
          }
        },
        builder: (context, state) {
          bool isLoading = state is AuthLoading; 

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primaryNavy, const Color(0xFF1E293B), Colors.black87])),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: goldAccent.withValues(alpha: 0.1), border: Border.all(color: goldAccent, width: 2)),
                          child: Icon(Icons.widgets_rounded, size: 60.sp, color: goldAccent),
                        ),
                        SizedBox(height: 24.h),
                        Text('منصة لَمَّة الشاملة', style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                        SizedBox(height: 8.h),
                        Text('كل خدماتك في مكان واحد، يرجى تسجيل الدخول', style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade400, fontFamily: 'Cairo')),
                        SizedBox(height: 40.h),

                        Card(
                          elevation: 8,
                          shadowColor: Colors.black54,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('تسجيل الدخول', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Cairo')),
                                  SizedBox(height: 20.h),
                                  
                                  Autocomplete<String>(
                                    optionsBuilder: (TextEditingValue textEditingValue) {
                                      if (textEditingValue.text == '') {
                                        return _savedIdentifiersList;
                                      }
                                      return _savedIdentifiersList.where((String option) {
                                        return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                      });
                                    },
                                    onSelected: (String selection) {
                                      _identifierController.text = selection;
                                    },
                                    fieldViewBuilder: (BuildContext context, TextEditingController fieldTextEditingController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                                      if (_identifierController.text.isNotEmpty && fieldTextEditingController.text.isEmpty) {
                                        fieldTextEditingController.text = _identifierController.text;
                                      }
                                      _identifierController.text = fieldTextEditingController.text;
                                      fieldTextEditingController.addListener(() {
                                        _identifierController.text = fieldTextEditingController.text;
                                      });

                                      return TextFormField(
                                        controller: fieldTextEditingController,
                                        focusNode: fieldFocusNode,
                                        textDirection: TextDirection.ltr,
                                        textInputAction: TextInputAction.next,
                                        style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo'),
                                        decoration: InputDecoration(
                                          labelText: 'البريد أو الهاتف أو اسم المستخدم', 
                                          labelStyle: TextStyle(fontSize: 14.sp),
                                          prefixIcon: Icon(Icons.how_to_reg_rounded, color: primaryNavy, size: 24.sp), 
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)), 
                                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: goldAccent, width: 2)),
                                          suffixIcon: fieldTextEditingController.text.isNotEmpty
                                              ? IconButton(
                                                  icon: Icon(Icons.clear, size: 20.sp),
                                                  onPressed: () {
                                                    fieldTextEditingController.clear();
                                                    _identifierController.clear();
                                                    setState(() {});
                                                  },
                                                )
                                              : null,
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'برجاء إدخال البيانات';
                                          }
                                          return null;
                                        },
                                      );
                                    },
                                    optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4.0,
                                          borderRadius: BorderRadius.circular(12.r),
                                          child: SizedBox(
                                            width: MediaQuery.of(context).size.width - 96.w, 
                                            child: ListView.builder(
                                              padding: EdgeInsets.all(8.w),
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder: (BuildContext context, int index) {
                                                final String option = options.elementAt(index);
                                                return InkWell(
                                                  onTap: () {
                                                    onSelected(option);
                                                  },
                                                  child: Padding(
                                                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                                                    child: Row(
                                                      children: [
                                                        Icon(Icons.history, size: 18.sp, color: Colors.grey.shade600),
                                                        SizedBox(width: 12.w),
                                                        Expanded(child: Text(option, textDirection: TextDirection.ltr, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp))),
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
                                    style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo'),
                                    decoration: InputDecoration(
                                      labelText: 'كلمة المرور',
                                      labelStyle: TextStyle(fontSize: 14.sp),
                                      prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryNavy, size: 24.sp),
                                      suffixIcon: IconButton(icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey, size: 24.sp), onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r), borderSide: BorderSide(color: goldAccent, width: 2))
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'برجاء إدخال كلمة المرور';
                                      }
                                      return null;
                                    },
                                  ),
                                  
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        activeColor: primaryNavy,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
                                        onChanged: (value) {
                                          setState(() {
                                            _rememberMe = value ?? false;
                                          });
                                        },
                                      ),
                                      GestureDetector(
                                        onTap: () => setState(() => _rememberMe = !_rememberMe),
                                        child: Text('تذكرني', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13.sp)),
                                      ),
                                      const Spacer(),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage()));
                                        },
                                        child: Text('نسيت كلمة المرور؟', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontFamily: 'Cairo', fontSize: 13.sp)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),

                                  ElevatedButton(
                                    onPressed: isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryNavy, 
                                      foregroundColor: Colors.white, 
                                      padding: EdgeInsets.symmetric(vertical: 16.h), 
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                                      elevation: 0,
                                    ),
                                    child: isLoading && _passwordController.text.isNotEmpty 
                                        ? SizedBox(height: 24.h, width: 24.w, child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) 
                                        : Text('دخول', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                  ),

                                  SizedBox(height: 16.h),

                                  // الفاصل لإضافة زر الدخول بجوجل
                                  Row(
                                    children: [
                                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                      Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                                        child: Text('أو', style: TextStyle(color: Colors.grey.shade500, fontFamily: 'Cairo', fontSize: 14.sp)),
                                      ),
                                      Expanded(child: Divider(color: Colors.grey.shade300, thickness: 1)),
                                    ],
                                  ),
                                  
                                  SizedBox(height: 16.h),

                                  // زر تسجيل الدخول باستخدام جوجل
                                  ElevatedButton(
                                    onPressed: isLoading ? null : () {
                                      context.read<AuthCubit>().loginWithGoogle();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      surfaceTintColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 14.h),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12.r),
                                        side: BorderSide(color: Colors.grey.shade300),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: isLoading && _passwordController.text.isEmpty
                                        ? SizedBox(height: 24.h, width: 24.w, child: CircularProgressIndicator(color: primaryNavy, strokeWidth: 2.5))
                                        : Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
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
                                              Text(
                                                'الدخول باستخدام Google', 
                                                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black87, fontFamily: 'Cairo')
                                              ),
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
                            Text('ليس لديك حساب؟', style: TextStyle(color: Colors.grey.shade300, fontFamily: 'Cairo', fontSize: 14.sp)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpPage()));
                              },
                              child: Text('سجل الآن', style: TextStyle(color: goldAccent, fontWeight: FontWeight.bold, fontSize: 16.sp, fontFamily: 'Cairo')),
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