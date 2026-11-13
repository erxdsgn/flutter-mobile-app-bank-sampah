import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../models/leaderboard_model.dart';

/// Kartu "Posisi kamu" yang menempel di bagian bawah halaman.
class MyRankBar extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const MyRankBar({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    // Mencari posisi pengguna yang sedang login di dalam list leaderboard
    final index = entries.indexWhere((e) => e.isCurrentUser);
    if (index == -1) return const SizedBox.shrink();

    final me = entries[index];
    final rank = index + 1;

    String hint;
    if (rank == 1) {
      hint = 'Kamu di puncak! Pertahankan poinmu.';
    } else {
      final gap = entries[index - 1].totalPoints - me.totalPoints;
      if (gap <= 0) {
        hint = 'Poin sama! Setor lagi untuk menyusul peringkat ${rank - 1}';
      } else {
        final needed =
            gap + 1; // Minimal butuh 1 poin lebih banyak untuk naik rank
        hint = 'Setor lagi untuk tambah $needed poin ke peringkat ${rank - 1}';
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar inisial
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              me.initials,
              style: const TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Peringkat kamu #$rank  •  ${me.totalPoints} P',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hint,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
