// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _showOtpField = false; 
  bool _isLoading = false;

  String _selectedRole = 'عميل'; 
  final List<String> _roles = ['عميل', 'كابتن (سائق)', 'محامي', 'طبيب', 'صيدلي', 'ممرض / ممرضة'];
  String _verificationId = '';

  File? _idFrontImage; 
  File? _idBackImage;  
  File? _professionImage; 
  File? _carLicenseFrontImage;
  File? _carLicenseBackImage;
  
  final Color primaryColor = const Color(0xFF0F172A); 
  final Color accentColor = const Color(0xFFD4AF37);  

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('اختر مصدر الصورة', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Cairo')),
                  ],
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_camera_rounded, color: primaryColor, size: 24.sp),
                title: Text('التقاط بالكاميرا', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _pickImage(ImageSource.camera, imageType); 
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library_rounded, color: primaryColor, size: 24.sp),
                title: Text('اختيار من المعرض', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 14.sp)),
                onTap: () {
                  Navigator.of(context).pop(); 
                  _pickImage(ImageSource.gallery, imageType); 
                },
              ),
              SizedBox(height: 10.h),
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
          if (mounted) {
            _showErrorSnackBar('الرقم القومي المدخل لا يطابق الرقم الموجود بالبطاقة المرفوعة! ❌');
          }
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
      SnackBar(content: Text(message, style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.redAccent)
    );
  }

  Future<void> _startSignUpAndSendOtp() async {
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

    String rawPhone = _phoneController.text.trim();
    String formattedPhone = rawPhone.startsWith('+') ? rawPhone : '+2$rawPhone';

    try {
      var phoneCheck = await FirebaseFirestore.instance.collection('users').where('phone', isEqualTo: rawPhone).limit(1).get();
      if (!mounted) {
        return;
      }
      if (phoneCheck.docs.isNotEmpty) {
        _showErrorSnackBar('رقم الهاتف هذا مسجل بالفعل ومربوط بحساب آخر ⚠️');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {},
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) {
            return;
          }
          _showErrorSnackBar('فشل إرسال كود التحقق للهاتف: ${e.message} ❌');
          setState(() {
            _isLoading = false;
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          if (!mounted) {
            return;
          }
          setState(() {
            _verificationId = verificationId;
            _showOtpField = true;
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال كود الـ OTP لهاتفك لتأكيد الهوية 💬', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.orange));
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('حدث خطأ: $e');
    }
  }

  Future<void> _completeSignUpWithOtp() async {
    if (_otpController.text.trim().length != 6) {
      _showErrorSnackBar('برجاء إدخال كود تحقق صحيح مكون من 6 أرقام! ⚠️');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      UserCredential phoneUserAuth = await FirebaseAuth.instance.signInWithCredential(credential);
      
      if (phoneUserAuth.user != null) {
        UserCredential emailUserAuth = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        String uid = emailUserAuth.user!.uid;
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

        String? fcmToken = await FirebaseMessaging.instance.getToken();

        Map<String, dynamic> userData = {
          'uid': uid,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'status': 'approved', 
          'documents': uploadedUrls,
          'fcmToken': fcmToken ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (_selectedRole != 'عميل') {
          userData['nationalId'] = _nationalIdController.text.trim();
        }

        await FirebaseFirestore.instance.collection('users').doc(uid).set(userData);
        await phoneUserAuth.user!.delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إنشاء وتفعيل حسابك بنجاح مئة بالمئة! 🎉🚀', style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp)), backgroundColor: Colors.green));
          Navigator.pushReplacementNamed(context, '/home'); 
        }
      }
    } catch (_) { 
      if (mounted) {
        _showErrorSnackBar('كود الـ OTP المدخل غير صحيح أو منتهي الصلاحية ❌');
      }
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

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      margin: EdgeInsets.only(bottom: 24.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 24.sp),
              SizedBox(width: 8.w),
              Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Cairo')),
            ],
          ),
          Divider(height: 30.h, color: Colors.grey.shade200, thickness: 1.5),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool isPassword = false,
    bool isObscured = false,
    VoidCallback? toggleObscure,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: isObscured,
        style: TextStyle(fontSize: 14.sp, fontFamily: 'Cairo'),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontSize: 14.sp),
          prefixIcon: Icon(icon, color: primaryColor.withValues(alpha: 0.7), size: 22.sp),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: primaryColor.withValues(alpha: 0.6), size: 22.sp),
                  onPressed: toggleObscure,
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: accentColor, width: 2)),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildUploadBox(String title, File? imageFile, String imageType, {double height = 120}) {
    return Container(
      height: height.h, 
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: imageFile != null ? Colors.green : Colors.grey.shade300, width: 2),
      ),
      child: imageFile != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(13.r),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(imageFile, fit: BoxFit.cover), 
                  Positioned(
                    top: 4.h, right: 4.w,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 16.r,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.delete, color: Colors.red, size: 18.sp),
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
              borderRadius: BorderRadius.circular(15.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(imageType == 'profession' ? Icons.badge_rounded : Icons.credit_card_rounded, size: 35.sp, color: primaryColor.withValues(alpha: 0.3)),
                  SizedBox(height: 8.h),
                  Text(title, style: TextStyle(color: primaryColor.withValues(alpha: 0.7), fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 11.sp), textAlign: TextAlign.center),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), 
      appBar: AppBar(
        backgroundColor: Colors.transparent, 
        elevation: 0, 
        foregroundColor: primaryColor,
        title: Text('حساب جديد', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 18.sp)),
        centerTitle: true,
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!_showOtpField) ...[
                    _buildSectionCard(
                      title: 'نوع الحساب',
                      icon: Icons.work_rounded,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedRole,
                          style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp, color: primaryColor, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.group_rounded, color: primaryColor.withValues(alpha: 0.7), size: 22.sp),
                            filled: true, fillColor: Colors.grey.shade50,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: Colors.grey.shade200)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: Colors.grey.shade200)),
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
                      ],
                    ),

                    _buildSectionCard(
                      title: 'البيانات الشخصية',
                      icon: Icons.person_rounded,
                      children: [
                        _buildInputField(
                          controller: _nameController,
                          label: 'الاسم بالكامل',
                          icon: Icons.badge_rounded,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'الاسم مطلوب';
                            }
                            return null;
                          },
                        ),
                        if (_selectedRole != 'عميل') ...[
                          _buildInputField(
                            controller: _nationalIdController,
                            label: 'الرقم القومي (14 رقم)',
                            icon: Icons.featured_play_list_rounded,
                            type: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.length != 14) {
                                return 'الرقم القومي يجب أن يكون 14 رقم بالكامل';
                              }
                              return null;
                            },
                          ),
                        ]
                      ]
                    ),

                    _buildSectionCard(
                      title: 'بيانات التواصل',
                      icon: Icons.contact_phone_rounded,
                      children: [
                        _buildInputField(
                          controller: _phoneController,
                          label: 'رقم الموبايل',
                          icon: Icons.phone_android_rounded,
                          type: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.length < 11) {
                              return 'رقم موبايل غير صحيح';
                            }
                            return null;
                          },
                        ),
                        _buildInputField(
                          controller: _emailController,
                          label: 'البريد الإلكتروني',
                          icon: Icons.email_rounded,
                          type: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty || !value.contains('@')) {
                              return 'بريد غير صحيح';
                            }
                            return null;
                          },
                        ),
                      ]
                    ),

                    _buildSectionCard(
                      title: 'الحماية وكلمة المرور',
                      icon: Icons.security_rounded,
                      children: [
                        _buildInputField(
                          controller: _passwordController,
                          label: 'كلمة المرور',
                          icon: Icons.lock_rounded,
                          isPassword: true,
                          isObscured: _obscurePassword,
                          toggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'قصيرة جداً (أقل من 6 أحرف)';
                            }
                            return null;
                          },
                        ),
                        _buildInputField(
                          controller: _confirmPasswordController,
                          label: 'تأكيد كلمة المرور',
                          icon: Icons.lock_clock_rounded,
                          isPassword: true,
                          isObscured: _obscureConfirmPassword,
                          toggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'تأكيد الباسورد مطلوب';
                            }
                            if (value != _passwordController.text) {
                              return 'كلمات المرور غير متطابقة ❌';
                            }
                            return null;
                          },
                        ),
                      ]
                    ),

                    if (_selectedRole != 'عميل') ...[
                      _buildSectionCard(
                        title: 'المستندات المطلوبة',
                        icon: Icons.folder_shared_rounded,
                        children: [
                          Text('تُستخدم هذه المستندات لتفعيل الحساب والموثوقية:', style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600, fontFamily: 'Cairo')),
                          SizedBox(height: 12.h),
                          Row(
                            children: [
                              Expanded(child: _buildUploadBox('وجه البطاقة', _idFrontImage, 'front', height: 110)),
                              SizedBox(width: 10.w),
                              Expanded(child: _buildUploadBox('ظهر البطاقة', _idBackImage, 'back', height: 110)),
                            ],
                          ),
                          SizedBox(height: 12.h),
                          
                          if (_selectedRole == 'كابتن (سائق)') ...[
                            Row(
                              children: [
                                Expanded(child: _buildUploadBox('وجه الرخصة', _carLicenseFrontImage, 'car_front', height: 110)),
                                SizedBox(width: 10.w),
                                Expanded(child: _buildUploadBox('ظهر الرخصة', _carLicenseBackImage, 'car_back', height: 110)),
                              ],
                            ),
                            SizedBox(height: 12.h),
                          ],
                          
                          _buildUploadBox(_getProfessionImageLabel(), _professionImage, 'profession', height: 110),
                        ]
                      ),
                    ],

                    SizedBox(height: 10.h),
                    SizedBox(
                      height: 55.h,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor, 
                          foregroundColor: Colors.white, 
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r))
                        ),
                        onPressed: _isLoading ? null : _startSignUpAndSendOtp,
                        child: _isLoading 
                          ? CircularProgressIndicator(color: accentColor) 
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('إنشاء الحساب والتحقق ', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                                Icon(Icons.arrow_forward_rounded, size: 20.sp)
                              ],
                            ),
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: EdgeInsets.all(24.w),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20.r),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.mark_email_read_rounded, size: 60.sp, color: Colors.green),
                          SizedBox(height: 16.h),
                          Text('تأكيد رقم الهاتف', textAlign: TextAlign.center, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: primaryColor, fontFamily: 'Cairo')),
                          SizedBox(height: 8.h),
                          Text('أدخل الكود المكون من 6 أرقام المرسل إلى:\n${_phoneController.text}', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, height: 1.5, color: Colors.grey.shade600, fontFamily: 'Cairo')),
                          SizedBox(height: 30.h),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24.sp, letterSpacing: 8.w, color: primaryColor),
                            decoration: InputDecoration(
                              hintText: '000000',
                              hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 8.w),
                              filled: true, fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15.r), borderSide: BorderSide(color: Colors.green, width: 2)),
                            ),
                          ),
                          SizedBox(height: 24.h),
                          SizedBox(
                            height: 55.h,
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green, 
                                foregroundColor: Colors.white, 
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r))
                              ),
                              onPressed: _isLoading ? null : _completeSignUpWithOtp,
                              child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text('تفعيل الحساب ✅', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          TextButton(
                            onPressed: () => setState(() => _showOtpField = false),
                            child: Text('رجوع لتعديل البيانات', style: TextStyle(fontFamily: 'Cairo', color: Colors.grey.shade600, fontSize: 14.sp, decoration: TextDecoration.underline)),
                          )
                        ],
                      ),
                    )
                  ],
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}