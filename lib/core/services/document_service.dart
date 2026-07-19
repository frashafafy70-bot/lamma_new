import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🟢 إضافة مكتبة dotenv للحماية

class DocumentService {
  // 🟢 استدعاء المفتاح بشكل آمن من ملف .env
  static String get cloudVisionApiKey => dotenv.env['VISION_API_KEY'] ?? '';

  static final ImagePicker picker = ImagePicker();
  static const Color primaryNavy = Color(0xFF0F172A);
  static const Color goldAccent = Color(0xFFD4AF37);

  // 1. التقاط الصورة
  static Future<File?> pickImage() async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    return pickedFile != null ? File(pickedFile.path) : null;
  }

  // 2. تحليل الصورة بالذكاء الاصطناعي
  static Future<bool> analyzeImageWithCloudVision(
      File imageFile, List<String> requiredKeywords) async {
    if (cloudVisionApiKey.isEmpty) {
      debugPrint("⚠️ مفتاح Cloud Vision غير موجود في ملف .env");
      return false;
    }

    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      var requestBody = {
        "requests": [
          {
            "image": {"content": base64Image},
            "features": [
              {"type": "TEXT_DETECTION"}
            ],
            "imageContext": {
              "languageHints": ["ar"]
            }
          }
        ]
      };
      var response = await http.post(
        Uri.parse(
            'https://vision.googleapis.com/v1/images:annotate?key=$cloudVisionApiKey'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      );
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        var responses = jsonResponse['requests'] ?? [];
        if (responses.isNotEmpty &&
            responses[0].containsKey('fullTextAnnotation')) {
          String extractedText =
              responses[0]['fullTextAnnotation']['text'].toLowerCase();
          return requiredKeywords
              .any((keyword) => extractedText.contains(keyword));
        }
      }
      return false;
    } catch (e) {
      debugPrint("❌ خطأ في تحليل الصورة: $e");
      return false;
    }
  }

  // 3. رفع المستند للـ Storage
  static Future<String?> uploadDocumentToStorage(
      {required String uid,
      required String role,
      required String docName,
      required File file}) async {
    try {
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('users/$uid/documents/$role/$docName.jpg');
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint("❌ خطأ في رفع المستند: $e");
      return null;
    }
  }

  // 4. قص الصورة
  static Future<File?> cropDocumentImage(File imageFile, String title) async {
    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
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
    return cropped != null ? File(cropped.path) : null;
  }
}
