import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../app_colors.dart';
import '../app_radius.dart';
import '../app_spacing.dart';
import '../app_typography.dart';
import 'ui_text.dart';

class UIPrimaryInput extends StatefulWidget {
  const UIPrimaryInput({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.errorText,
    this.focusNode,
    this.onChanged,
    this.onClear,
  });

  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final String? errorText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  @override
  State<UIPrimaryInput> createState() => _UIPrimaryInputState();
}

class _UIPrimaryInputState extends State<UIPrimaryInput> {
  late final TextEditingController _controller;
  late final bool _ownsController;

  bool get _hasError => widget.errorText != null;
  bool get _hasText => _controller.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleTextChange() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
    widget.onClear?.call();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _hasError ? AppColors.danger : AppColors.ink;
    final borderColor = _hasError ? AppColors.danger : AppColors.border;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          style: AppTypography.body,
          cursorColor: AppColors.brand,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface200,
            hintText: widget.hintText,
            hintStyle: AppTypography.body.copyWith(color: AppColors.inkMuted),
            contentPadding: AppSpacing.card,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.space3,
                right: AppSpacing.space2,
              ),
              child: SvgPicture.asset(
                'assets/icons/location-pin.svg',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 20,
            ),
            suffixIcon: _hasText
                ? IconButton(
                    onPressed: _clear,
                    icon: const Icon(Icons.close, size: 18),
                    color: AppColors.inkMuted,
                  )
                : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mdAll,
              borderSide: BorderSide(
                color: _hasError ? AppColors.danger : AppColors.brand,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.space1),
          UIText.caption(widget.errorText!, color: AppColors.danger),
        ],
      ],
    );
  }
}
