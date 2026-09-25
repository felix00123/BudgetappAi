import 'package:flutter/material.dart';

/// Shared timings used by onboarding, card/sync success, and chart fills.
class AppMotion {
  static const page = Duration(milliseconds: 380);
  static const success = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 80);

  static const pageCurve = Curves.easeOutCubic;
  static const successCurve = Curves.easeOutBack;
}
