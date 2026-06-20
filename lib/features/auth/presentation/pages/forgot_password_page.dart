// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  final Color primaryNavy = const Color(0xFF0F172A);
  final Color goldAccent = const Color(0xFFD4AF37);

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });

      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إرسال رابط تعيين كلمة المرور إلى بريدك الإلكتروني! 📧✅', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: Colors.green, duration: Duration(seconds: 4)),
        );

        Navigator.pop(context);

      } on FirebaseAuthException catch (e) {
        if (!mounted) return;

        String errorMessage = 'حدث خطأ أثناء إرسال الرابط';
        if (e.code == 'user-not-found') {
          errorMessage = 'هذا البريد الإلكتروني غير مسجل لدينا في المنصة.';
        } else if (e.code == 'invalid-email') {
          errorMessage = 'صيغة البريد الإلكتروني غير صحيحة.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')), backgroundColor: Colors.red.shade800),
        );
      } finally {
        if (mounted) setState(() { _isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          width: double.infinity, height: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [primaryNavy, const Color(0xFF1E293B), Colors.black87])),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: goldAccent.withValues(alpha: 0.1), border: Border.all(color: goldAccent, width: 2)),
                      child: Icon(Icons.lock_reset_rounded, size: 55, color: goldAccent),
                    ),
                    const SizedBox(height: 20),
                    const Text('استعادة كلمة المرور', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text('أدخل بريدك الإلكتروني المسجل وسنقوم بإرسال رابط مخصص لتغيير كلمة المرور فوراً', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade400, height: 1.5, fontFamily: 'Cairo')),
                    ),
                    const SizedBox(height: 35),

                    Card(
                      elevation: 8, shadowColor: Colors.black54, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextFormField(
                                controller: _emailController, keyboardType: TextInputType.emailAddress, textDirection: TextDirection.ltr,
                                style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'البريد الإلكتروني المسجل', labelStyle: const TextStyle(fontFamily: 'Cairo'),
                                  prefixIcon: Icon(Icons.email_outlined, color: primaryNavy),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: goldAccent, width: 2)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'برجاء إدخال البريد الإلكتروني أولاً';
                                  if (!value.contains('@')) return 'صيغة البريد الإلكتروني غير صحيحة';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              ElevatedButton(
                                onPressed: _isLoading ? null : _resetPassword,
                                style: ElevatedButton.styleFrom(backgroundColor: primaryNavy, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                child: _isLoading
                                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                                    : const Text('إرسال رابط الاستعادة', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                              ),
                            ],
                          ),
                        ),
                      ),
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
}