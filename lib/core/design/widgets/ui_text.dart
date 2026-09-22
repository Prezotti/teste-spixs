import 'package:flutter/material.dart';

import '../app_typography.dart';

class UIText extends StatelessWidget {
  const UIText._(
    this.text, {
    required TextStyle style,
    this.color,
    this.maxLines,
    this.overflow,
    this.textAlign,
    super.key,
  }) : _style = style;

  final String text;
  final TextStyle _style;
  final Color? color;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  const UIText.display(
    String text, {
    Key? key,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) : this._(
         text,
         key: key,
         style: AppTypography.display,
         color: color,
         maxLines: maxLines,
         overflow: overflow,
         textAlign: textAlign,
       );

  const UIText.title(String text, {Key? key, Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign})
    : this._(
        text,
        key: key,
        style: AppTypography.title,
        color: color,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );

  const UIText.heading(
    String text, {
    Key? key,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) : this._(
         text,
         key: key,
         style: AppTypography.heading,
         color: color,
         maxLines: maxLines,
         overflow: overflow,
         textAlign: textAlign,
       );

  const UIText.bodyStrong(
    String text, {
    Key? key,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) : this._(
         text,
         key: key,
         style: AppTypography.bodyStrong,
         color: color,
         maxLines: maxLines,
         overflow: overflow,
         textAlign: textAlign,
       );

  const UIText.body(String text, {Key? key, Color? color, int? maxLines, TextOverflow? overflow, TextAlign? textAlign})
    : this._(
        text,
        key: key,
        style: AppTypography.body,
        color: color,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      );

  const UIText.caption(
    String text, {
    Key? key,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
    TextAlign? textAlign,
  }) : this._(
         text,
         key: key,
         style: AppTypography.caption,
         color: color,
         maxLines: maxLines,
         overflow: overflow,
         textAlign: textAlign,
       );

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
      style: color == null ? _style : _style.copyWith(color: color),
    );
  }
}
