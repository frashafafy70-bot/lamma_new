// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../home/home_page.dart'; 
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
  bool _isLoading = false; 

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  // 🔍 دالة للبحث عن الإيميل لو المستخدم دخل رقم فون أو يوزرنيم
  Future<String?> _resolveEmail(String input) async {
    input = input.trim();
    if (input.contains('@') && input.contains('.')) return input;
    
    if (RegExp(r'^\d+$').hasMatch(input)) {
      final query = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: input).limit(1).get();
      if (query.docs.isNotEmpty) return query.docs.first.data()['email'] as String?;
    } else {
      final query = await FirebaseFirestore.instance.collection('users').where('username', isEqualTo: input.toLowerCase()).limit(1).get();
      if (query.docs.isNotEmpty) return query.docs.first.data()['email'] as String?;
    }
    return null;
  }

  Future<void> _login() async {
    // إخفاء الكيبورد عند الضغط على دخول
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() { _isLoading = true; });

    try {
      String? loginEmail = await _resolveEmail(_identifierController.text);
      
      if (loginEmail == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('لم يتم العثور على حساب بهذا المُدخل، تأكد من البيانات.', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: Colors.red.shade800));
        setState(() { _isLoading = false; });
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: loginEmail,
        password: _passwordController.text.trim(),
      );

      // 🟢 تحديث الـ FCM Token مباشرة بعد الدخول
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).update({
          'fcmToken': fcmToken,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل الدخول بنجاح! ✅', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: Colors.green),
      );
      
      // التوجيه للصفحة الرئيسية مع تصفير مسار العودة
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) =>  HomePage()), (route) => false);

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String errorMessage = 'حدث خطأ أثناء تسجيل الدخول';
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        errorMessage = 'هذا الحساب غير مسجل لدينا.';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        errorMessage = 'كلمة المرور غير صحيحة، يرجى المحاولة مجدداً.';
      } else if (e.code == 'too-many-requests') {
         errorMessage = 'محاولات دخول كثيرة خاطئة، برجاء المحاولة لاحقاً.';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: Colors.red.shade800));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ: $e', style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), 
          backgroundColor: Colors.red.shade900,
          duration: const Duration(seconds: 4), 
        )
      );
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primaryNavy, const Color(0xFF1E293B), Colors.black87])),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: goldAccent.withValues(alpha: 0.1), border: Border.all(color: goldAccent, width: 2)),
                      child: Icon(Icons.widgets_rounded, size: 60, color: goldAccent),
                    ),
                    const SizedBox(height: 24),
                    const Text('منصة لَمَّة الشاملة', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Text('كل خدماتك في مكان واحد، يرجى تسجيل الدخول', style: TextStyle(fontSize: 14, color: Colors.grey.shade400, fontFamily: 'Cairo')),
                    const SizedBox(height: 40),

                    Card(
                      elevation: 8,
                      shadowColor: Colors.black54,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text('تسجيل الدخول', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87, fontFamily: 'Cairo')),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _identifierController,
                                textDirection: TextDirection.ltr,
                                // زرار الكيبورد يروح للحقل اللي بعده (التالي)
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(labelText: 'البريد أو الهاتف أو اسم المستخدم', prefixIcon: Icon(Icons.how_to_reg_rounded, color: primaryNavy), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: goldAccent, width: 2))),
                                validator: (value) => (value == null || value.isEmpty) ? 'برجاء إدخال البيانات' : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _isPasswordObscured,
                                textDirection: TextDirection.ltr,
                                // زرار الكيبورد يكون "تم" ولما تدوس عليه ينفذ دالة الدخول
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: 'كلمة المرور',
                                  prefixIcon: Icon(Icons.lock_outline_rounded, color: primaryNavy),
                                  suffixIcon: IconButton(icon: Icon(_isPasswordObscured ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _isPasswordObscured = !_isPasswordObscured)),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: goldAccent, width: 2))
                                ),
                                validator: (value) => (value == null || value.isEmpty) ? 'برجاء إدخال كلمة المرور' : null,
                              ),
                              
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordPage()));
                                  },
                                  child: Text('هل نسيت كلمة المرور؟', style: TextStyle(color: primaryNavy, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                ),
                              ),
                              const SizedBox(height: 16),

                              ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: _isLoading ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3)) : const Text('دخول', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('ليس لديك حساب؟', style: TextStyle(color: Colors.grey.shade300, fontFamily: 'Cairo')),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) =>  SignUpPage()));
                          },
                          child: Text('سجل الآن', style: TextStyle(color: goldAccent, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Cairo')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
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