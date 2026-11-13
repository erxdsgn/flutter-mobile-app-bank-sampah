import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Judul bagian + tautan "semua" di kanan.
class SectionHeader extends StatelessWidget {
  final String title;
  final String actionText;
  final VoidCallback? onAction;
  final TextStyle? titleStyle;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionText = 'semua',
    this.onAction,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: titleStyle ??
              const TextStyle(
                fontSize: 12,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
        ),
        GestureDetector(
          onTap: onAction,
          behavior: HitTestBehavior.opaque,
          child: Text(
            actionText,
            style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}