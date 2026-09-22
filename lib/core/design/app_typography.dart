import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static const TextStyle display = TextStyle(
    fontSize: 34,
    height: 40 / 34,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle title = TextStyle(
    fontSize: 22,
    height: 28 / 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
  );

  static const TextStyle body = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w400,
    color: AppColors.ink,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w400,
    color: AppColors.inkMuted,
  );
}
