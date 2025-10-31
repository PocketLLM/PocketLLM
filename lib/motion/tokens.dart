import 'package:flutter/material.dart';

class MotionDurations {
  static const short = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 280);
  static const long = Duration(milliseconds: 420);
  static const pager = Duration(milliseconds: 520);
  static const ctaSpring = Duration(milliseconds: 380);

  const MotionDurations._();
}

class MotionCurves {
  static const easeOutCubic = Curves.easeOutCubic;
  static const easeInOutCubic = Curves.easeInOutCubic;
  static const emphasized = Curves.easeOutBack;
  static const pager = Curves.easeOutQuart;

  const MotionCurves._();
}

class MotionStaggers {
  static const short = Duration(milliseconds: 60);
  static const medium = Duration(milliseconds: 100);
  static const long = Duration(milliseconds: 140);

  const MotionStaggers._();
}
