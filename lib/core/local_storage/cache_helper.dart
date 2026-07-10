import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static late SharedPreferences sharedPreferences;

  // 🟢 دالة التهيئة (بتشتغل مرة واحدة بس لما التطبيق يفتح)
  static Future<void> init() async {
    sharedPreferences = await SharedPreferences.getInstance();
  }

  // 🟢 دالة لحفظ أي نوع من البيانات (String, int, bool, double)
  static Future<bool> saveData({
    required String key,
    required dynamic value,
  }) async {
    if (value is String) return await sharedPreferences.setString(key, value);
    if (value is int) return await sharedPreferences.setInt(key, value);
    if (value is bool) return await sharedPreferences.setBool(key, value);
    if (value is double) return await sharedPreferences.setDouble(key, value);
    
    return false; // لو النوع مش مدعوم
  }

  // 🟢 دالة لجلب البيانات
  static dynamic getData({required String key}) {
    return sharedPreferences.get(key);
  }

  // 🟢 دالة لحذف قيمة معينة (مثلاً لو السواق عمل تسجيل خروج نمسح الداتا بتاعته)
  static Future<bool> removeData({required String key}) async {
    return await sharedPreferences.remove(key);
  }

  // 🟢 دالة لمسح كل البيانات من التخزين المحلي
  static Future<bool> clearAllData() async {
    return await sharedPreferences.clear();
  }
}