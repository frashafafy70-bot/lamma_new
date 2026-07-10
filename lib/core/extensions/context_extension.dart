import 'package:flutter/material.dart';

extension ContextExtension on BuildContext {
  // 1. اختصارات التنقل (Navigation)
  void pushNamed(String routeName, {Object? arguments}) {
    Navigator.of(this).pushNamed(routeName, arguments: arguments);
  }

  void pushReplacementNamed(String routeName, {Object? arguments}) {
    Navigator.of(this).pushReplacementNamed(routeName, arguments: arguments);
  }

  void pop() {
    if (Navigator.of(this).canPop()) {
      Navigator.of(this).pop();
    }
  }

  // 2. اختصارات الألوان والـ Theme
  ThemeData get theme => Theme.of(this);
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // 3. اختصارات أبعاد الشاشة (Responsive)
  double get height => MediaQuery.of(this).size.height;
  double get width => MediaQuery.of(this).size.width;
}