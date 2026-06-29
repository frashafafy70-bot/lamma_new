# حماية مكتبة Record
-keep class com.llfbandit.record.** { *; }

# حماية عامة لـ Flutter
-keep class io.flutter.plugins.** { *; }

# حماية مكتبات Google ML Kit و Vision لمنع الحذف بواسطة R8
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.internal.mlkit_vision_text.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_text.**