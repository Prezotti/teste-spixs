import 'package:flutter/material.dart';

abstract final class AppRadius {
  static const double sm = 6;
  static const double md = 12;
  static const double lg = 24;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
}
