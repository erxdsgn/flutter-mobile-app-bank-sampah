// lib/views/history/history_detail_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/helpers/transaction_helpers.dart';
import '../../models/transaksi_model.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/skeleton_box.dart';

/// Detail satu transaksi dalam bentuk struk.
class DetailHistoryPage extends StatefulWidget {
  final TransaksiModel transaksi;
  final String? namaWarga;

  const DetailHistoryPage({
    super.key,
    required this.transaksi,
    this.namaWarga,
  });

  @override
  State<DetailHistoryPage> createState() => _DetailHistoryPageState();
}

class _DetailHistoryPageState extends State<DetailHistoryPage> {
  String _displayName = '';
  bool _loadingName = true;

  @override
  void initState() {
    super.initState();
    _resolveNamaWarga();
  }

  /// Konversi status string dari backend secara fleksibel & akurat
  StatusSetoran _parseStatus(String statusStr) {
    final s = statusStr.toLowerCase().trim();
    if (s.contains('tolak') ||
        s.contains('reject') ||
        s.contains('deni') ||
        s.contains('batal') ||
        s.contains('cancel')) {
      return StatusSetoran.ditolak;
    }
    if (s.contains('proses') ||
        s.contains('menunggu') ||
        s.contains('pending') ||
        s.contains('wait')) {
      return StatusSetoran.menunggu;
    }
    return StatusSetoran.diterima;
  }

  /// Mengambil nama warga asli dari SharedPreferences/UserModel jika dari API berupa ID
  Future<void> _resolveNamaWarga() async {
    String resolvedName = '';

    // 1. Cek parameter opsional namaWarga yang dikirim ke widget
    if (widget.namaWarga != null && widget.namaWarga!.trim().isNotEmpty) {
      final p = widget.namaWarga!.trim();
      if (!_isIdString(p)) {
        resolvedName = p;
      }
    }

    // 2. Cek SharedPreferences (karena nama warga yang login tersimpan di sini)
    if (resolvedName.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();

        // A. Cek kunci string langsung
        const stringKeys = [
          'nama_warga',
          'nama',
          'name',
          'nama_lengkap',
          'user_name',
          'username',
          'nama_pemilik_rekening',
        ];

        for (final key in stringKeys) {
          final val = prefs.getString(key);
          if (val != null && val.trim().isNotEmpty && !_isIdString(val.trim())) {
            resolvedName = val.trim();
            break;
          }
        }

        // B. Jika tidak ketemu, coba decode objek JSON 'user' / 'user_data' / 'userData'
        if (resolvedName.isEmpty) {
          const jsonKeys = ['user', 'user_data', 'userData', 'auth_user'];
          for (final jsonKey in jsonKeys) {
            final jsonStr = prefs.getString(jsonKey);
            if (jsonStr != null && jsonStr.isNotEmpty) {
              try {
                final Map<String, dynamic> map = jsonDecode(jsonStr);

                // Cek profil.nama (sesuai WargaModel)
                if (map['profil'] is Map<String, dynamic>) {
                  final profil = map['profil'] as Map<String, dynamic>;
                  final namaProfil = profil['nama']?.toString().trim();
                  if (namaProfil != null &&
                      namaProfil.isNotEmpty &&
                      !_isIdString(namaProfil)) {
                    resolvedName = namaProfil;
                    break;
                  }
                }

                // Cek field nama / username / name di level utama JSON
                final namaDirect = map['nama']?.toString().trim() ??
                    map['username']?.toString().trim() ??
                    map['name']?.toString().trim();
                if (namaDirect != null &&
                    namaDirect.isNotEmpty &&
                    !_isIdString(namaDirect)) {
                  resolvedName = namaDirect;
                  break;
                }
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        debugPrint('Gagal membaca nama dari SharedPreferences: $e');
      }
    }

    // 3. Cek transaksi.namaNasabah jika bukan berupa ID
    if (resolvedName.isEmpty) {
      final raw = widget.transaksi.namaNasabah.trim();
      if (raw.isNotEmpty && !_isIdString(raw)) {
        resolvedName = raw;
      }
    }

    // 4. Fallback default jika nama tidak ditemukan
    if (resolvedName.isEmpty) {
      resolvedName = 'Nasabah';
    }

    if (!mounted) return;
    setState(() {
      _displayName = resolvedName;
      _loadingName = false;
    });
  }

  /// Memeriksa apakah sebuah teks merupakan ID (angka, awalan ID-, WRG-, dll)
  bool _isIdString(String str) {
    final s = str.trim().toLowerCase();
    if (s.isEmpty) return true;
    if (RegExp(r'^\d+$').hasMatch(s)) return true;
    if (RegExp(r'^(id|wrg|warga|usr|user)[_\-\s0-9]').hasMatch(s)) return true;
    if (s == 'id_warga' || s == 'idwarga' || s == 'id') return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final status = _parseStatus(widget.transaksi.status);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const PrimaryAppBar(title: 'Riwayat Transaksi'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _loadingName
              ? const _ReceiptSkeleton()
              : _Receipt(
                  transaksi: widget.transaksi,
                  status: status,
                  namaWarga: _displayName,
                ),
        ),
      ),
    );
  }
}

// ======================================================
// STRUK SKELETON (SHIMMER LOADING)
// ======================================================

class _ReceiptSkeleton extends StatelessWidget {
  const _ReceiptSkeleton();

  @override
  Widget build(BuildContext context) {
    return PhysicalShape(
      clipper: const _ZigzagClipper(),
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Skeleton
            const Row(
              children: [
                SkeletonBox(width: 38, height: 38, borderRadius: 19),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 70, height: 10),
                    SizedBox(height: 6),
                    SkeletonBox(width: 100, height: 14),
                  ],
                ),
                Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SkeletonBox(width: 80, height: 10),
                    SizedBox(height: 6),
                    SkeletonBox(width: 90, height: 12),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),
            const _DashedDivider(),
            const SizedBox(height: 14),

            // Info Row Skeleton (Tanggal & Nama)
            Row(
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      SkeletonBox(width: 24, height: 24, borderRadius: 12),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 40, height: 10),
                          SizedBox(height: 4),
                          SkeletonBox(width: 85, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: AppColors.divider,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                const Expanded(
                  child: Row(
                    children: [
                      SkeletonBox(width: 24, height: 24, borderRadius: 12),
                      SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonBox(width: 35, height: 10),
                          SizedBox(height: 4),
                          SkeletonBox(width: 90, height: 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const SkeletonBox(width: double.infinity, height: 50, borderRadius: 14),
            const SizedBox(height: 16),

            const SkeletonBox(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 8),
            const SkeletonBox(width: double.infinity, height: 24),
            const SizedBox(height: 8),
            const SkeletonBox(width: double.infinity, height: 24),

            const SizedBox(height: 12),
            const _DashedDivider(),
            const SizedBox(height: 12),

            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 70, height: 12),
                SkeletonBox(width: 50, height: 12),
              ],
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SkeletonBox(width: 60, height: 14),
                SkeletonBox(width: 80, height: 14),
              ],
            ),
            const SizedBox(height: 16),

            const SkeletonBox(width: double.infinity, height: 50, borderRadius: 14),
            const SizedBox(height: 18),

            const Center(child: SkeletonBox(width: 80, height: 12)),
            const SizedBox(height: 8),
            const Center(child: SkeletonBox(width: 180, height: 10)),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// STRUK
// ======================================================

class _Receipt extends StatelessWidget {
  final TransaksiModel transaksi;
  final StatusSetoran status;
  final String namaWarga;

  const _Receipt({
    required this.transaksi,
    required this.status,
    required this.namaWarga,
  });

  String _totalSampah() {
    final totals = <String, double>{};
    for (final item in transaksi.items) {
      totals[item.satuan] = (totals[item.satuan] ?? 0) + item.jumlah;
    }
    if (totals.isEmpty) return '';
    return totals.entries
        .map((e) => '${formatJumlah(e.value)}${e.key}')
        .join(' | ');
  }

  @override
  Widget build(BuildContext context) {
    final catatan = transaksi.catatanAdmin?.trim() ?? '';

    return PhysicalShape(
      clipper: const _ZigzagClipper(),
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 30, 18, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 14),
            const _DashedDivider(),
            const SizedBox(height: 14),
            _buildInfoRow(),
            const SizedBox(height: 14),
            _StatusBanner(status: status),
            const SizedBox(height: 16),
            _buildItemsTable(),
            const SizedBox(height: 12),
            const _DashedDivider(),
            const SizedBox(height: 12),
            if (_totalSampah().isNotEmpty)
              _SummaryRow(label: 'Total Sampah', value: _totalSampah()),
            _SummaryRow(
              label: 'Total Nilai',
              value: formatRupiah(transaksi.totalNilai),
              valueColor: status.color,
              bold: true,
            ),
            const SizedBox(height: 16),
            if (status == StatusSetoran.ditolak)
              _CatatanAdminBox(catatan: catatan)
            else if (catatan.isNotEmpty)
              _SummaryRow(label: 'Catatan Admin', value: catatan),
            const SizedBox(height: 12),
            if (status != StatusSetoran.ditolak)
              _SaldoBox(status: status, nilai: transaksi.totalNilai),
            const SizedBox(height: 18),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.recycling_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bank Sampah',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Sahabat Ibu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'Bukti Setor Sampah',
              style: TextStyle(fontSize: 10.5, color: Colors.black45),
            ),
            const SizedBox(height: 2),
            Text(
              transaksi.nomorBukti.isEmpty ? '-' : transaksi.nomorBukti,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        Expanded(
          child: _InfoCell(
            icon: Icons.calendar_month_rounded,
            label: 'Tanggal',
            value: formatTanggal(transaksi.tanggal),
          ),
        ),
        Container(
          height: 36,
          width: 1,
          color: AppColors.divider,
          margin: const EdgeInsets.symmetric(horizontal: 10),
        ),
        Expanded(
          child: _InfoCell(
            icon: Icons.person_rounded,
            label: 'Nama',
            value: formatNamaRingkas(namaWarga),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable() {
    const headerStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.bold,
      color: Colors.black54,
    );
    const cellStyle = TextStyle(fontSize: 12, color: AppColors.text);

    if (transaksi.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Text(
            'Tidak ada rincian item.',
            style: TextStyle(fontSize: 12, color: Colors.black45),
          ),
        ),
      );
    }

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(width: 24, child: Text('No', style: headerStyle)),
              Expanded(flex: 3, child: Text('Jenis', style: headerStyle)),
              Expanded(
                flex: 2,
                child: Text('Berat', style: headerStyle, textAlign: TextAlign.right),
              ),
              Expanded(
                flex: 3,
                child: Text('Subtotal', style: headerStyle, textAlign: TextAlign.right),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),
        ...List.generate(transaksi.items.length, (i) {
          final item = transaksi.items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${i + 1}', style: cellStyle),
                ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaKategori,
                        style: cellStyle.copyWith(fontWeight: FontWeight.w600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${formatRupiah(item.hargaSatuan)}/${item.satuan}',
                        style: const TextStyle(fontSize: 10.5, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${formatJumlah(item.jumlah)} ${item.satuan}',
                    style: cellStyle,
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    formatRupiah(item.subtotal),
                    style: cellStyle.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        const Text(
          'Terima Kasih',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 30, height: 1, color: AppColors.border),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                'Bersama kita wujudkan lingkungan yang lebih baik',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 10.5, color: Colors.black45),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 30, height: 1, color: AppColors.border),
          ],
        ),
        const SizedBox(height: 10),
        const Icon(Icons.eco_rounded, color: AppColors.primary, size: 22),
      ],
    );
  }
}

// ======================================================
// WIDGET DUKUNGAN
// ======================================================

class _CatatanAdminBox extends StatelessWidget {
  final String catatan;

  const _CatatanAdminBox({required this.catatan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.report_problem_rounded, color: Colors.redAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'Catatan Penolakan Admin',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            catatan.isNotEmpty ? catatan : 'Tidak ada catatan tambahan dari admin.',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBanner extends StatelessWidget {
  final StatusSetoran status;

  const _StatusBanner({required this.status});

  String get _title {
    switch (status) {
      case StatusSetoran.menunggu:
        return 'Menunggu Konfirmasi Admin';
      case StatusSetoran.diterima:
        return 'Transaksi Berhasil';
      case StatusSetoran.ditolak:
        return 'Setoran Ditolak';
    }
  }

  String get _subtitle {
    switch (status) {
      case StatusSetoran.menunggu:
        return 'Saldo bertambah setelah setoran disetujui admin';
      case StatusSetoran.diterima:
        return 'Terimakasih telah menjaga lingkungan';
      case StatusSetoran.ditolak:
        return 'Lihat catatan admin di bawah untuk alasannya';
    }
  }

  IconData get _icon {
    switch (status) {
      case StatusSetoran.menunggu:
        return Icons.hourglass_top_rounded;
      case StatusSetoran.diterima:
        return Icons.check_rounded;
      case StatusSetoran.ditolak:
        return Icons.close_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: status.color,
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: status.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle,
                  style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.text),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: valueColor ?? AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaldoBox extends StatelessWidget {
  final StatusSetoran status;
  final double nilai;

  const _SaldoBox({required this.status, required this.nilai});

  @override
  Widget build(BuildContext context) {
    final pending = status == StatusSetoran.menunggu;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_rounded,
            color: status.color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pending ? 'Saldo Akan Bertambah' : 'Saldo Anda Bertambah',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: status.color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(nilai),
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          Icon(
            pending ? Icons.schedule_rounded : Icons.north_east_rounded,
            color: status.color,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dash = 6.0;
        const gap = 5.0;
        final count = (constraints.maxWidth / (dash + gap)).floor().clamp(1, 200);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(width: dash, height: 1.2, color: AppColors.border),
          ),
        );
      },
    );
  }
}

class _ZigzagClipper extends CustomClipper<Path> {
  const _ZigzagClipper();

  static const double _toothHeight = 10;
  static const double _toothWidth = 20;

  @override
  Path getClip(Size size) {
    final count = (size.width / _toothWidth).floor().clamp(1, 200);
    final w = size.width / count;

    final path = Path()..moveTo(0, _toothHeight);

    for (var i = 0; i < count; i++) {
      path.lineTo(w * i + w / 2, 0);
      path.lineTo(w * (i + 1), _toothHeight);
    }

    path.lineTo(size.width, size.height - _toothHeight);

    for (var i = count; i > 0; i--) {
      path.lineTo(w * i - w / 2, size.height);
      path.lineTo(w * (i - 1), size.height - _toothHeight);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _ZigzagClipper oldClipper) => false;
}