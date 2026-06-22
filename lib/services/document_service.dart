// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DocumentService {
  static const String cloudVisionApiKey = 'AIzaSyC7LVnuJ5QfXCAKjse-EbDxvKZITRa75AM';
  static final ImagePicker picker = ImagePicker();
  static const Color primaryNavy = Color(0xFF0F172A); 
  static const Color goldAccent = Color(0xFFD4AF37); 

  // 1. تحليل الصورة بالذكاء الاصطناعي
  static Future<bool> analyzeImageWithCloudVision(String imagePath, List<String> requiredKeywords) async { 
    try { 
      List<int> imageBytes = await File(imagePath).readAsBytes(); 
      String base64Image = base64Encode(imageBytes); 
      var requestBody = { 
        "requests": [{
          "image": {"content": base64Image}, 
          "features": [{"type": "TEXT_DETECTION"}], 
          "imageContext": {"languageHints": ["ar"]}
        }] 
      }; 
      var response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$cloudVisionApiKey'), 
        headers: {"Content-Type": "application/json"}, 
        body: jsonEncode(requestBody),
      ); 
      if (response.statusCode == 200) { 
        var jsonResponse = jsonDecode(response.body); 
        var responses = jsonResponse['requests'] ?? []; 
        if (responses.isNotEmpty && responses[0].containsKey('fullTextAnnotation')) { 
          String extractedText = responses[0]['fullTextAnnotation']['text'].toLowerCase(); 
          return requiredKeywords.any((keyword) => extractedText.contains(keyword)); 
        } 
      } 
      return false; 
    } catch (e) { 
      return false; 
    } 
  }
  
  // 2. رفع المستند للـ Storage
  static Future<String?> uploadDocumentToStorage({required String uid, required String role, required String docName, required File file}) async { 
    try { 
      Reference ref = FirebaseStorage.instance.ref().child('users').child(uid).child('documents').child(role).child('$docName.jpg'); 
      UploadTask uploadTask = ref.putFile(file); 
      TaskSnapshot snapshot = await uploadTask; 
      return await snapshot.ref.getDownloadURL(); 
    } catch (e) { 
      return null; 
    } 
  }
  
  // 3. قص الصورة
  static Future<CroppedFile?> cropDocumentImage(String path, String title) async { 
    return await ImageCropper().cropImage(
      sourcePath: path, 
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: title, 
          toolbarColor: primaryNavy, 
          toolbarWidgetColor: Colors.white, 
          initAspectRatio: CropAspectRatioPreset.original, 
          lockAspectRatio: false, 
          activeControlsWidgetColor: goldAccent,
        ), 
        IOSUiSettings(title: title),
      ],
    ); 
  }
  
  // 4. دالة متكاملة للالتقاط والفحص والقص
  static Future<void> pickValidateAndCropImage(BuildContext context, StateSetter setModalState, Function(File?) onValidImage, List<String> keywords, String cropTitle) async { 
    try { 
      final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70); 
      if (pickedFile != null) { 
        if (!context.mounted) return; 
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🤖 جاري فحص المستند سحابياً...'), duration: Duration(seconds: 2))); 
        
        bool isValid = await analyzeImageWithCloudVision(pickedFile.path, keywords); 
        if (!isValid) { 
          if (!context.mounted) return; 
          bool? proceedAnyway = await showDialog<bool>(
            context: context, 
            builder: (ctx) => AlertDialog(
              title: const Text('تنبيه فحص المستند ⚠️', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')), 
              content: const Text('الذكاء الاصطناعي لم يتعرف على الكارنيه. هل تريد إكمال الرفع للمراجعة اليدوية؟', textDirection: TextDirection.rtl, style: TextStyle(fontFamily: 'Cairo')), 
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')), 
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: primaryNavy), child: const Text('نعم، المتابعة', style: TextStyle(color: Colors.white))),
              ],
            )
          ); 
          if (proceedAnyway != true) return; 
        } 
        
        CroppedFile? cropped = await cropDocumentImage(pickedFile.path, cropTitle); 
        if (cropped != null) { 
          setModalState(() { onValidImage(File(cropped.path)); }); 
          if (!context.mounted) return; 
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ تم إرفاق المستند بنجاح.', style: TextStyle(fontFamily: 'Cairo')), backgroundColor: Colors.green)); 
        } 
      } 
    } catch (e) { 
      if (!context.mounted) return; 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ في جلب المستند'))); 
    } 
  }
}