// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🟢 1. استدعاء مكتبة الإشعارات عشان نسحب التوكن

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // الكنترولرات
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String _selectedRole = 'عميل'; 
  final List<String> _roles = ['عميل', 'كابتن (سائق)', 'محامي', 'طبيب', 'صيدلي', 'ممرض / ممرضة'];

  // متغيرات الصور 
  File? _idFrontImage; 
  File? _idBackImage;  
  File? _professionImage; 
  File? _carLicenseFrontImage;
  File? _carLicenseBackImage;
  
  final Color primaryColor = const Color(0xFF0F172A); 
  final Color accentColor = const Color(0xFFD4AF37);  

  String _getProfessionImageLabel() {
    if (_selectedRole == 'كابتن (سائق)') {
      return 'صورة رخصة القيادة الشخصية (سارية)';
    }
    if (_selectedRole == 'عميل') {
      return ''; 
    }
    return 'صورة كارنيه النقابة / مزاولة المهنة';
  }

  void _showPickerOptions(String imageType) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('اختر مصدر الصورة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Cairo'), textAlign: TextAlign.center),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: Color(0xFF0F172A)),
                title: const Text('التقاط بالكاميرا', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _pickImage(ImageSource.camera, imageType); 
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF0F172A)),
                title: const Text('اختيار من المعرض', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _pickImage(ImageSource.gallery, imageType); 
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, String imageType) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        if (imageType == 'front') {
          _idFrontImage = File(pickedFile.path);
        } else if (imageType == 'back') {
          _idBackImage = File(pickedFile.path);
        } else if (imageType == 'profession') {
          _professionImage = File(pickedFile.path);
        } else if (imageType == 'car_front') {
          _carLicenseFrontImage = File(pickedFile.path);
        } else if (imageType == 'car_back') {
          _carLicenseBackImage = File(pickedFile.path);
        }
      });

      if (imageType == 'front' && _selectedRole != 'عميل') {
        _processImageWithAI(File(pickedFile.path));
      }
    }
  }

  Future<void> _processImageWithAI(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = TextRecognizer(); 
    
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String extractedText = recognizedText.text.replaceAll(' ', '');

      final RegExp numRegExp = RegExp(r'[0-9]{14}');
      final Iterable<Match> matches = numRegExp.allMatches(extractedText);

      if (matches.isNotEmpty && _nationalIdController.text.isNotEmpty) {
        String scannedId = matches.first.group(0)!;
        if (scannedId != _nationalIdController.text.trim()) {
          _showErrorSnackBar('الرقم القومي المدخل لا يطابق الرقم الموجود بالبطاقة المرفوعة! ❌');
        }
      }
    } catch (e) {
      debugPrint("خطأ أثناء تحليل الصورة: $e");
    } finally {
      textRecognizer.close();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: const TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.redAccent)
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedRole != 'عميل' && (_idFrontImage == null || _idBackImage == null)) {
       _showErrorSnackBar('برجاء رفع وجه وظهر البطاقة الشخصية ⚠️');
       return;
    }

    if (_selectedRole == 'كابتن (سائق)' && (_carLicenseFrontImage == null || _carLicenseBackImage == null)) {
       _showErrorSnackBar('برجاء رفع وجه وظهر رخصة السيارة ⚠️');
       return;
    }

    if (_selectedRole != 'عميل' && _professionImage == null) {
       _showErrorSnackBar('برجاء رفع ${_getProfessionImageLabel()} ⚠️');
       return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      Map<String, String> uploadedUrls = {};

      if (_selectedRole != 'عميل') {
        uploadedUrls['id_front'] = await _uploadFileToStorage('users/$uid/id_front.jpg', _idFrontImage!);
        uploadedUrls['id_back'] = await _uploadFileToStorage('users/$uid/id_back.jpg', _idBackImage!);
      }

      if (_carLicenseFrontImage != null) {
        uploadedUrls['car_front'] = await _uploadFileToStorage('users/$uid/car_front.jpg', _carLicenseFrontImage!);
        uploadedUrls['car_back'] = await _uploadFileToStorage('users/$uid/car_back.jpg', _carLicenseBackImage!);
      }

      if (_professionImage != null) {
        uploadedUrls['profession'] = await _uploadFileToStorage('users/$uid/profession.jpg', _professionImage!);
      }

      // 🟢 2. سحب التوكن الخاص بجهاز المستخدم
      String? fcmToken = await FirebaseMessaging.instance.getToken();

      Map<String, dynamic> userData = {
        'uid': uid,
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': _selectedRole,
        'status': 'approved', 
        'documents': uploadedUrls,
        'fcmToken': fcmToken ?? '', // 🟢 3. إضافة التوكن في قاعدة البيانات
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (_selectedRole != 'عميل') {
        userData['nationalId'] = _nationalIdController.text.trim();
      }

      await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إنشاء حسابك وتفعيله بنجاح! 🚀🗺️', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green));
      
      Navigator.pushReplacementNamed(context, '/home');
      
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('فشل التسجيل المباشر: $e ⚠️');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _uploadFileToStorage(String path, File file) async {
    Reference ref = FirebaseStorage.instance.ref().child(path);
    UploadTask uploadTask = ref.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Widget _buildUploadBox(String title, File? imageFile, String imageType, {double height = 160}) {
    return Container(
      height: height, 
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: imageFile != null ? Colors.green : Colors.grey.shade300, width: 2),
      ),
      child: imageFile != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile, fit: BoxFit.cover), 
                  Positioned(
                    top: 4, right: 4,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                        onPressed: () {
                          setState(() {
                            if (imageType == 'front') {
                              _idFrontImage = null;
                            } else if (imageType == 'back') {
                              _idBackImage = null;
                            } else if (imageType == 'profession') {
                              _professionImage = null;
                            } else if (imageType == 'car_front') {
                              _carLicenseFrontImage = null;
                            } else if (imageType == 'car_back') {
                              _carLicenseBackImage = null;
                            }
                          });
                        },
                      ),
                    ),
                  )
                ],
              ),
            )
          : InkWell(
              onTap: () => _showPickerOptions(imageType),
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(imageType == 'profession' ? Icons.badge_rounded : Icons.credit_card_rounded, size: 35, color: primaryColor.withAlpha(128)),
                  const SizedBox(height: 8),
                  Text(title, style: TextStyle(color: primaryColor, fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11), textAlign: TextAlign.center),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, foregroundColor: primaryColor),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.person_add_alt_1_rounded, size: 60, color: accentColor),
                  const SizedBox(height: 10),
                  Text('حساب جديد في لَمَّة', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Cairo')),
                  const SizedBox(height: 30),

                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: InputDecoration(
                      labelText: 'نوع الحساب',
                      prefixIcon: Icon(Icons.work_rounded, color: primaryColor),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                    items: _roles.map((role) => DropdownMenuItem(value: role, child: Text(role, style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedRole = value!;
                        _idFrontImage = null;
                        _idBackImage = null;
                        _professionImage = null; 
                        _carLicenseFrontImage = null; 
                        _carLicenseBackImage = null;
                        _nationalIdController.clear();
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'الاسم بالكامل', prefixIcon: Icon(Icons.person_rounded, color: primaryColor), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                    validator: (value) => value!.isEmpty ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(labelText: 'رقم الموبايل', prefixIcon: Icon(Icons.phone_android_rounded, color: primaryColor), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                    validator: (value) => value!.length < 11 ? 'رقم غير صحيح' : null,
                  ),
                  const SizedBox(height: 16),

                  if (_selectedRole != 'عميل') ...[
                    TextFormField(
                      controller: _nationalIdController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'الرقم القومي (14 رقم)', prefixIcon: Icon(Icons.featured_play_list_rounded, color: primaryColor), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                      validator: (value) => value!.length != 14 ? 'الرقم القومي يجب أن يكون 14 رقم' : null,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(labelText: 'البريد الإلكتروني', prefixIcon: Icon(Icons.email_rounded, color: primaryColor), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                    validator: (value) => value!.isEmpty || !value.contains('@') ? 'بريد غير صحيح' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور', prefixIcon: Icon(Icons.lock_rounded, color: primaryColor),
                      suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
                      filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                    ),
                    validator: (value) => value!.length < 6 ? 'قصيرة جداً' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'تأكيد كلمة المرور', prefixIcon: Icon(Icons.lock_clock_rounded, color: primaryColor),
                      suffixIcon: IconButton(icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor), onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                      filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'مطلوب';
                      }
                      if (value != _passwordController.text) {
                        return 'كلمات المرور غير متطابقة ❌';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),

                  if (_selectedRole != 'عميل') ...[
                    const Text('المستندات المطلوبة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _buildUploadBox('وجه البطاقة الشخصية', _idFrontImage, 'front', height: 120)),
                        const SizedBox(width: 10),
                        Expanded(child: _buildUploadBox('ظهر البطاقة الشخصية', _idBackImage, 'back', height: 120)),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  if (_selectedRole == 'كابتن (سائق)')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: _buildUploadBox('وجه رخصة السيارة', _carLicenseFrontImage, 'car_front', height: 120)),
                            const SizedBox(width: 10),
                            Expanded(child: _buildUploadBox('ظهر رخصة السيارة', _carLicenseBackImage, 'car_back', height: 120)),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  
                  if (_selectedRole != 'عميل')
                    Column(
                      children: [
                        _buildUploadBox(_getProfessionImageLabel(), _professionImage, 'profession', height: 160),
                        const SizedBox(height: 16),
                      ],
                    ),

                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: _isLoading ? null : _handleSignUp,
                      child: _isLoading ? CircularProgressIndicator(color: accentColor) : const Text('إنشاء الحساب 🚀', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}