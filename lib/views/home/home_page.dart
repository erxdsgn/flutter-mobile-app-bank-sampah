// lib/views/home/home_page.dart
import 'dart:async';
import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/helpers/transaction_helpers.dart';
import '../../models/transaksi_model.dart';
import '../../models/artikel_model.dart';
import '../../services/setoran_service.dart';
import '../../services/artikel_service.dart';
import '../../widgets/balance_card.dart';
import '../../widgets/info_tip_card.dart';
import '../../widgets/reminder_banner.dart';
import '../../widgets/section_header.dart';
import '../../widgets/transaction_history_card.dart';
import '../../widgets/transaction_tile.dart';
import '../../widgets/skeleton_box.dart'; // Import skeleton widget
import '../history/history_detail_page.dart';
import '../product/product_page.dart';
import '../setoran/setor_sampah_page.dart';
import '../price/price_page.dart';
import '../news/artikel_event_page.dart';
import 'jadwal_setoran_page.dart';
import 'help_center_page.dart';
import 'leaderboard_page.dart';

class HomePage extends StatefulWidget {
  final String userName;
  final VoidCallback? onOpenProduk;
  final VoidCallback? onOpenRiwayat;
  final VoidCallback? onOpenProfile;

  const HomePage({
    super.key,
    this.userName = 'NASABAH',
    this.onOpenProduk,
    this.onOpenRiwayat,
    this.onOpenProfile,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hideBalance = false;
  final ScrollController _scrollController = ScrollController();

  static const double _headerHeight = 62;
  static const double _scrollThreshold = 80;
  static const double _greenOverlap = 180;

  double _balance = 0.0;
  String _accountNumber = '';
  String _bankEwallet = '';
  String _accountOwner = '';
  String _accountStatus = 'unverified';

  final ArtikelService _artikelService = ArtikelService();
  List<ItemDataModel> _homeArtikelList = [];
  bool _loadingArtikel = true;

  final SetoranService _setoranService = SetoranService();
  List<TransaksiModel> _transactions = [];
  bool _loadingRiwayat = true;
  String? _riwayatError;

  static const int _maxHomeTransactions = 5;

  @override
  void initState() {
    super.initState();
    _loadBalance();
    _loadRiwayat();
    _loadHomeArtikel();
  }

  Future<void> _loadHomeArtikel() async {
    try {
      final result = await _artikelService.fetchArtikel();
      if (!mounted) return;
      setState(() {
        _homeArtikelList = result;
        _loadingArtikel = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingArtikel = false;
      });
      debugPrint('Gagal memuat artikel beranda: $e');
    }
  }

  Future<void> _loadRiwayat() async {
    if (mounted) {
      setState(() {
        _loadingRiwayat = true;
        _riwayatError = null;
      });
    }

    List<TransaksiModel>? result;
    String? error;

    try {
      final prefs = await SharedPreferences.getInstance();
      const tokenKeys = [
        'token',
        'auth_token',
        'access_token',
        'token_warga',
        'bearer_token',
      ];
      String token = '';
      for (final key in tokenKeys) {
        final value = prefs.getString(key);
        if (value != null && value.isNotEmpty) {
          token = value;
          break;
        }
      }

      if (token.isEmpty) {
        throw Exception(
          'Token tidak ditemukan di penyimpanan. Coba login ulang.',
        );
      }

      result = await _setoranService.getHistory(token);
    } on TimeoutException {
      error = 'Server tidak merespons. Periksa koneksi lalu coba lagi.';
    } on SocketException catch (e) {
      error = 'Tidak dapat terhubung ke server. ($e)';
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() {
      _loadingRiwayat = false;
      if (result != null) {
        _transactions = result.take(_maxHomeTransactions).toList();
      } else {
        _riwayatError = error ?? 'Gagal memuat riwayat.';
      }
    });
  }

  StatusSetoran _parseStatus(String statusStr) {
    final s = statusStr.toLowerCase();
    if (s.contains('terima') ||
        s.contains('selesai') ||
        s.contains('berhasil') ||
        s.contains('approved')) {
      return StatusSetoran.diterima;
    }
    if (s.contains('tolak') || s.contains('reject')) {
      return StatusSetoran.ditolak;
    }
    return StatusSetoran.menunggu;
  }

  String _transactionSubtitle(TransaksiModel trx) {
    final status = _parseStatus(trx.status);
    final nilai = formatRupiah(trx.totalNilai);

    switch (status) {
      case StatusSetoran.diterima:
        return 'Saldo+ $nilai';
      case StatusSetoran.menunggu:
        return 'Saldo+ $nilai';
      case StatusSetoran.ditolak:
        return 'Ditolak $nilai';
    }
  }

  Widget _buildHomeTransactionSection() {
    if (_loadingRiwayat) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
      );
    }

    if (_riwayatError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Text(
              _riwayatError!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadRiwayat, child: const Text('Coba lagi')),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Center(
          child: Text(
            'Belum ada transaksi.',
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      );
    }

    return TransactionHistoryCard(
      title: 'Riwayat Transaksi',
      actionText: 'semua',
      onSeeAll: widget.onOpenRiwayat ?? () => _comingSoon('Riwayat transaksi'),
      children: _transactions.map((trx) {
        return TransactionTile(
          title: 'Setor Sampah',
          subtitle: _transactionSubtitle(trx),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailHistoryPage(transaksi: trx),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Future<void> _loadBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saldo = prefs.getDouble('saldo_warga') ?? 0.0;
      final nomorRekening = prefs.getString('nomor_rekening') ?? '';
      final namaBankEwallet = prefs.getString('nama_bank_ewallet') ?? '';
      final namaPemilikRekening =
          prefs.getString('nama_pemilik_rekening') ?? '';
      final statusRekening = prefs.getString('status_rekening') ?? 'unverified';

      if (!mounted) return;

      setState(() {
        _balance = saldo;
        _accountNumber = nomorRekening;
        _bankEwallet = namaBankEwallet;
        _accountOwner = namaPemilikRekening;
        _accountStatus = statusRekening;
      });
    } catch (e) {
      debugPrint('Gagal mengambil saldo tersimpan: $e');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double get _progress {
    final offset = _scrollController.hasClients
        ? _scrollController.offset
        : 0.0;
    return (offset / _scrollThreshold).clamp(0.0, 1.0);
  }

  String _formatRupiah(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final integer = parts[0].replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return 'Rp$integer,${parts[1]}';
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$feature belum tersedia'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: _scrollController,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: topPadding + _headerHeight + _greenOverlap,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.primary,
                                Color.lerp(
                                  AppColors.primary,
                                  AppColors.primaryDark,
                                  0.35,
                                )!,
                              ],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(36),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          SizedBox(height: topPadding + _headerHeight),
                          const SizedBox(height: 16),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: _buildSummary(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // BAGIAN INFORMASI & TIPS (DENGAN SKELETON LOADING)
                  // ==========================================
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SectionHeader(
                      title: 'Informasi & Tips:',
                      actionText: 'semua',
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ArtikelEventPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height:
                        159, // 135 (tinggi kartu 16:9) + 8 (top) + 16 (bottom)
                    child: _loadingArtikel
                        ? ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            itemCount: 3,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              return const SkeletonBox(
                                width: 240,
                                height: 135,
                                borderRadius: 14,
                              );
                            },
                          )
                        : _homeArtikelList.isEmpty
                        ? const Center(
                            child: Text(
                              'Belum ada informasi.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                            itemCount: _homeArtikelList.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 16),
                            itemBuilder: (context, index) {
                              final item = _homeArtikelList[index];

                              return InfoTipCard(
                                width: 240,
                                height: 135, // Rasio tepat 16:9
                                imagePath: item.imageUrl ?? '',
                                title: item.title,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          DetailPage(data: item),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildHomeTransactionSection(),
                  ),
                  SizedBox(height: 24 + bottomPadding),
                ],
              ),
            ),
            _buildFixedHeader(topPadding),
          ],
        ),
      ),
      builder: (context, child) {
        final double progress = _progress;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: progress > 0.5
              ? SystemUiOverlayStyle.dark
              : SystemUiOverlayStyle.light,
          child: child!,
        );
      },
    );
  }

  Widget _buildFixedHeader(double topPadding) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _scrollController,
        builder: (context, child) {
          final double progress = _progress;
          final double colorProgress = Curves.easeOut.transform(
            (progress * 1.5).clamp(0.0, 1.0),
          );

          final Color textColor = Color.lerp(
            Colors.white,
            Colors.black87,
            colorProgress,
          )!;
          final Color subTextColor = Color.lerp(
            Colors.white70,
            Colors.black54,
            colorProgress,
          )!;
          final Color iconBgColor = Color.lerp(
            Colors.white.withOpacity(0.22),
            AppColors.primary.withOpacity(0.12),
            colorProgress,
          )!;
          final Color iconColor = Color.lerp(
            Colors.white,
            AppColors.primaryDark,
            colorProgress,
          )!;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 14 * progress,
                sigmaY: 14 * progress,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.88 * progress),
                      Colors.white.withOpacity(0.70 * progress),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.06 * progress),
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    topPadding > 12 ? topPadding - 12 : 4,
                    24,
                    0,
                  ),
                  child: SizedBox(
                    height: _headerHeight,
                    child: _buildGreeting(
                      textColor,
                      subTextColor,
                      iconBgColor,
                      iconColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGreeting(
    Color textColor,
    Color subTextColor,
    Color iconBgColor,
    Color iconColor,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Halo,',
                style: TextStyle(fontSize: 14, color: subTextColor),
              ),
              Text(
                widget.userName.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: Icons.emoji_events_outlined,
          bgColor: iconBgColor,
          iconColor: iconColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LeaderboardPage()),
            );
          },
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: Icons.headset_mic_outlined,
          bgColor: iconBgColor,
          iconColor: iconColor,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpCenterPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSummary() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: ReminderBanner(
            title: 'Waktunya persiapan setor sampah!',
            subtitle: 'Segera input data setoran Anda.',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const JadwalSetoranPage(),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: Transform.translate(
            offset: const Offset(0, -10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  BalanceCard(
                    balance: _formatRupiah(_balance),
                    accountNumber: _accountNumber.isEmpty
                        ? 'Belum tersedia'
                        : _accountNumber,
                    isHidden: _hideBalance,
                    onToggleVisibility: () {
                      setState(() {
                        _hideBalance = !_hideBalance;
                      });
                    },
                    onAddAccount:
                        widget.onOpenProfile ??
                        () {
                          _comingSoon('Halaman profile');
                        },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _QuickMenuItem(
                          imagePath: 'assets/images/recycling.png',
                          label: 'Setor\nSampah',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SetorSampahPage(),
                              ),
                            ).then((_) {
                              _loadBalance();
                              _loadRiwayat();
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _QuickMenuItem(
                          imagePath: 'assets/images/shopping-bag.png',
                          label: 'Produk\nDaur Ulang',
                          onTap:
                              widget.onOpenProduk ??
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ProductPage(
                                      tokenWarga: 'MASUKKAN_TOKEN_WARGA_ANDA',
                                    ),
                                  ),
                                );
                              },
                        ),
                      ),
                      Expanded(
                        child: _QuickMenuItem(
                          imagePath: 'assets/images/tag.png',
                          label: 'Harga\nSampah',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PricePage(),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: _QuickMenuItem(
                          imagePath: 'assets/images/calendar.png',
                          label: 'Jadwal\nSetoran',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const JadwalSetoranPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _QuickMenuItem({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Icon(icon, size: 22, color: iconColor),
      ),
    );
  }
}
