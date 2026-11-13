import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Banner pengingat hijau muda. Sebagian atasnya tertutup kartu di atasnya
/// ([topInset]), jadi letakkan di belakang kartu memakai Stack.
class ReminderBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback? onTap;
  final int pageCount;
  final int currentPage;
  final double topInset;

  const ReminderBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.actionText = 'Klik disini',
    this.onTap,
    this.pageCount = 2,
    this.currentPage = 0,
    this.topInset = 28,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 70 + topInset,
        padding: EdgeInsets.fromLTRB(12, topInset, 14, 0),
        decoration: BoxDecoration(
          color: AppColors.primaryLight,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // Indikator halaman (vertikal)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pageCount, (i) {
                final active = i == currentPage;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  width: 5,
                  height: active ? 14 : 5,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.border,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
            const SizedBox(width: 12),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.edit_calendar_rounded,
                size: 22,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              actionText,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary.withOpacity(0.75),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.primary.withOpacity(0.75),
            ),
          ],
        ),
      ),
    );
  }
}