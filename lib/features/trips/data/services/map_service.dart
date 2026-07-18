import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapService {
  // 🟢 تطبيق نمط Singleton لضمان وجود نسخة واحدة فقط في الذاكرة
  static final MapService _instance = MapService._internal();
  factory MapService() => _instance;
  MapService._internal();

  // 🟢 المتغير الذي سيحتفظ بأيقونة السيارة جاهزة للاستخدام
  BitmapDescriptor? carMarker;

  // 🟢 دالة التحميل المسبق (Pre-cache)
  Future<void> loadCustomMarkers() async {
    // إذا تم تحميلها مسبقاً، لا تقم بتحميلها مرة أخرى لتوفير الموارد
    if (carMarker != null) return; 

    try {
      // قم بتعديل مسار الصورة ليتطابق مع مجلد الصور في مشروعك
      // الرقم 120 هو عرض الأيقونة بالبكسل، يمكنك تصغيره أو تكبيره حسب حجم صورتك
      final Uint8List markerIcon = await _getBytesFromAsset('assets/images/car_marker.png', 120);
      
      carMarker = BitmapDescriptor.fromBytes(markerIcon);
      debugPrint('✅ تم تحميل أيقونة السيارة بنجاح');
    } catch (e) {
      debugPrint('❌ حدث خطأ أثناء تحميل أيقونة السيارة: $e');
    }
  }

  // 🟢 دالة مساعدة سحرية: تقوم بقراءة الصورة من الملفات، وتغيير حجمها برمجياً 
  // حتى لا تظهر عملاقة جداً على الخريطة وتغطي الشوارع
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(), targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }
}