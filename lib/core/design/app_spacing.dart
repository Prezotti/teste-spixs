import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 16;
  static const double space4 = 32;

  static const EdgeInsets chip = EdgeInsets.all(space1);
  static const EdgeInsets related = EdgeInsets.all(space2);
  static const EdgeInsets card = EdgeInsets.all(space3);
  static const EdgeInsets screen = EdgeInsets.all(space4);
}
