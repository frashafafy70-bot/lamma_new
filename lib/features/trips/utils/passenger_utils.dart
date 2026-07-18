import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lamma_new/l10n/app_localizations.dart'; // تأكد إن مسار الترجمة صحيح

// 1. Extension للتوطين (عشان نستخدم context.l10n مباشرة بدون تمرير متغيرات)
extension ContextExtensions on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

// 2. كلاس مخصص لإدارة الذاكرة والـ Controllers (Memory Management)
class PassengerFormControllers {
  final pickup = TextEditingController();
  final destination = TextEditingController();
  final price = TextEditingController();
  final errandDetails = TextEditingController();
  final errandEstimatedCost = TextEditingController();
  final priceFocusNode = FocusNode();

  void dispose() {
    pickup.dispose();
    destination.dispose();
    price.dispose();
    errandDetails.dispose();
    errandEstimatedCost.dispose();
    priceFocusNode.dispose();
  }
}

// 3. أداة للتفاعل اللمسي (UX Haptic Feedback)
class UXFeedback {
  static void lightImpact() => HapticFeedback.lightImpact();
  static void selectionClick() => HapticFeedback.selectionClick();
  static void success() => HapticFeedback.mediumImpact();
}