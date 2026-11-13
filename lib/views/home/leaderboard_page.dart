import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../models/leaderboard_model.dart';
import '../../services/leaderboard_service.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/leaderboard_tile.dart';
import '../../widgets/my_rank_bar.dart';
import '../../widgets/podium.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardService _leaderboardService = LeaderboardService();
  late Future<List<LeaderboardEntry>> _future;

  @override
  void initState() {
    super.initState();
    _future = _leaderboardService.fetchSeasonIni();
  }

  void _refresh() {
    setState(() {
      _future = _leaderboardService.fetchSeasonIni();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimaryAppBar(title: "Papan Peringkat"),
      body: FutureBuilder<List<LeaderboardEntry>>(
        future: _future,
        builder: (context, snapshot) {
          final entries = snapshot.data;

          return Column(
            children: [
              Expanded(
                child: _buildBody(snapshot, entries),
              ),
              if (entries != null && entries.isNotEmpty)
                MyRankBar(entries: entries),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    AsyncSnapshot<List<LeaderboardEntry>> snapshot,
    List<LeaderboardEntry>? entries,
  ) {
    if (snapshot.connectionState != ConnectionState.done) {
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: const [
          SkeletonBox(width: double.infinity, height: 260, borderRadius: 24),
          SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: 64, borderRadius: 12),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 64, borderRadius: 12),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 64, borderRadius: 12),
        ],
      );
    }

    if (snapshot.hasError || entries == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Gagal memuat papan peringkat'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _refresh,
              child: const Text(
                'Coba lagi',
                style: TextStyle(color: AppColors.green, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
    }

    if (entries.isEmpty) {
      return const Center(
        child: Text(
          'Belum ada data setoran di periode ini',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final showPodium = entries.length >= 3;
    final rest = showPodium ? entries.skip(3).toList() : entries;
    final startRank = showPodium ? 4 : 1;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          // Subteks Periode opsional di bawah App Bar
          const Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              'Setor terbanyak',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Podium 3 Besar (Latar putih polos tanpa lengkungan hijau)
          if (showPodium)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Podium(
                first: entries[0],
                second: entries[1],
                third: entries[2],
              ),
            ),

          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 8),

          // List Peringkat 4 ke bawah dengan ListView.separated
          if (rest.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: rest.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF0F0F0),
                ),
                itemBuilder: (context, index) {
                  return LeaderboardTile(
                    rank: startRank + index,
                    entry: rest[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}