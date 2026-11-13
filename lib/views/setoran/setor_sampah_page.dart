import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/item_setoran_model.dart';
import '../../models/kategori_sampah_model.dart';
import '../../services/setoran_service.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/setoran_info_header.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/summary_box.dart';
import '../../widgets/waste_item_tile.dart';
import 'tambah_sampah_page.dart';

class SetorSampahPage extends StatefulWidget {
  /// Token API hasil login (bisa dikosongkan jika ingin otomatis ambil dari SharedPreferences).
  final String? token;

  /// Nama warga yang tampil di kartu "Nama".
  final String? namaWarga;

  const SetorSampahPage({
    super.key,
    this.token,
    this.namaWarga,
  });

  @override
  State<SetorSampahPage> createState() => _SetorSampahPageState();
}

class _SetorSampahPageState extends State<SetorSampahPage> {
  final _service = SetoranService();
  final DateTime _tanggal = DateTime.now();

  List<KategoriSampahModel> _categories = [];
  final List<ItemSetoranModel> _items = [];

  bool _isLoadingCategories = true;
  String? _categoryError;
  bool _isSubmitting = false;

  String? _resolvedToken;
  String _resolvedNamaWarga = 'WARGA';

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Ambil token dari parameter, jika null/kosong ambil dari SharedPreferences
    _resolvedToken = (widget.token != null && widget.token!.isNotEmpty)
        ? widget.token
        : prefs.getString('auth_token');

    // Ambil nama warga dari parameter, jika null/kosong ambil dari SharedPreferences
    _resolvedNamaWarga = (widget.namaWarga != null && widget.namaWarga!.isNotEmpty)
        ? widget.namaWarga!
        : (prefs.getString('nama_warga') ?? 'WARGA');

    if (mounted) {
      setState(() {});
    }

    _loadKategori();
  }

  // ==========================================
  // DATA
  // ==========================================
  Future<void> _loadKategori() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });

    try {
      if (_resolvedToken == null || _resolvedToken!.isEmpty) {
        throw Exception('Sesi berakhir, silakan login ulang.');
      }

      final res = await _service.getKategori(_resolvedToken!);
      if (!mounted) return;
      setState(() {
        _categories = res;
        _isLoadingCategories = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingCategories = false;
        _categoryError = _errorMessage(e);
      });
    }
  }

  String _errorMessage(Object e) {
    if (e is SocketException) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }
    if (e is TimeoutException) return 'Koneksi terlalu lambat, coba lagi.';
    return e.toString().replaceFirst('Exception: ', '');
  }

  double get _totalPendapatan =>
      _items.fold<double>(0, (sum, i) => sum + i.subtotal);

  /// Total per satuan, mis. "13kg | 1 unit | 3 set".
  String get _summaryTotalSampah {
    if (_items.isEmpty) return '0kg';
    final totals = <String, double>{};
    for (final item in _items) {
      final unit = item.kategori.satuan;
      totals[unit] = (totals[unit] ?? 0) + item.jumlah;
    }
    return totals.entries
        .map((e) => Formatters.jumlah(e.value, e.key))
        .join(' | ');
  }

  // ==========================================
  // AKSI
  // ==========================================
  Future<void> _tambahSampah() async {
    if (_categories.isEmpty) {
      _showSnackBar('Kategori sampah belum tersedia', isError: true);
      return;
    }

    final res = await Navigator.of(context).push<ItemSetoranModel>(
      MaterialPageRoute(
        builder: (_) => TambahSampahPage(
          daftarKategori: _categories,
          namaWarga: _resolvedNamaWarga,
        ),
      ),
    );
    if (res == null || !mounted) return;

    setState(() {
      // Kategori yang sama digabung, supaya id_kategori tidak dobel
      // pada data yang dikirim ke server.
      final index = _items.indexWhere(
        (i) => i.kategori.idKategori == res.kategori.idKategori,
      );
      if (index >= 0) {
        final total = _items[index].jumlah + res.jumlah;
        _items[index].jumlah = double.parse(total.toStringAsFixed(2));
      } else {
        _items.add(res);
      }
    });
  }

  Future<void> _submit() async {
    if (_items.isEmpty) {
      _showSnackBar('Tambahkan minimal 1 jenis sampah', isError: true);
      return;
    }

    if (_resolvedToken == null || _resolvedToken!.isEmpty) {
      _showSnackBar('Sesi berakhir, silakan login ulang', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final ok = await _service.submitSetoran(
        token: _resolvedToken!,
        items: _items,
      );
      if (!mounted) return;
      if (ok) {
        _showSnackBar('Setoran sampah berhasil dikirim', isError: false);
        // true = ada setoran baru, halaman sebelumnya bisa memuat ulang data.
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(_errorMessage(e), isError: true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.redAccent : AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  // ==========================================
  // UI
  // ==========================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimaryAppBar(title: 'Setor Sampah'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _isLoadingCategories
                    ? const _SetorSampahSkeleton()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        children: [
                          SetoranInfoHeader(
                            namaWarga: _resolvedNamaWarga,
                            tanggal: Formatters.tanggal(_tanggal),
                          ),
                          const SizedBox(height: 24),

                          const Text(
                            'Detail Setor Sampah',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          const SizedBox(height: 12),

                          if (_items.isEmpty)
                            const _EmptyItems()
                          else
                            for (final item in _items)
                              WasteItemTile(
                                key: ValueKey(item.kategori.idKategori),
                                item: item,
                                onDelete: () =>
                                    setState(() => _items.remove(item)),
                              ),

                          if (_categoryError != null) ...[
                            const SizedBox(height: 4),
                            _CategoryError(
                              message: _categoryError!,
                              onRetry: _loadKategori,
                            ),
                          ],
                          const SizedBox(height: 6),

                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              side: BorderSide(
                                color: (_isLoadingCategories ||
                                        _categoryError != null)
                                    ? AppColors.border
                                    : AppColors.primary,
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.add, size: 22),
                            label: const Text(
                              'Tambah Sampah',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            onPressed: (_isLoadingCategories ||
                                    _categoryError != null)
                                ? null
                                : _tambahSampah,
                          ),
                          const SizedBox(height: 20),

                          SummaryBox(
                            icon: Icons.scale_outlined,
                            label: 'Total Sampah',
                            value: _summaryTotalSampah,
                          ),
                          const SizedBox(height: 12),
                          SummaryBox(
                            icon: Icons.monetization_on_outlined,
                            label: 'Total Pendapatan',
                            value: Formatters.rupiah(_totalPendapatan),
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(
                text: 'Konfirmasi',
                isLoading: _isSubmitting,
                onPressed: _isLoadingCategories ? null : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// SKELETON LOADING SETOR SAMPAH
// ======================================================

class _SetorSampahSkeleton extends StatelessWidget {
  const _SetorSampahSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        // Skeleton Info Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceGrey,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              SkeletonBox(width: 44, height: 44, borderRadius: 22),
              SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 70, height: 10),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 14),
                ],
              ),
              Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonBox(width: 60, height: 10),
                  SizedBox(height: 6),
                  SkeletonBox(width: 90, height: 12),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Judul Detail Skeleton
        const SkeletonBox(width: 150, height: 16),
        const SizedBox(height: 12),

        // Skeleton Kotak Tambah Sampah Placeholder
        const SkeletonBox(width: double.infinity, height: 80, borderRadius: 12),
        const SizedBox(height: 16),

        // Skeleton Tombol Tambah Sampah
        const SkeletonBox(width: double.infinity, height: 48, borderRadius: 12),
        const SizedBox(height: 20),

        // Skeleton Summary Cards
        const SkeletonBox(width: double.infinity, height: 54, borderRadius: 12),
        const SizedBox(height: 12),
        const SkeletonBox(width: double.infinity, height: 54, borderRadius: 12),
      ],
    );
  }
}

/// Tampilan saat belum ada sampah yang ditambahkan.
class _EmptyItems extends StatelessWidget {
  const _EmptyItems();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 32, color: AppColors.hint),
          SizedBox(height: 8),
          Text(
            'Belum ada sampah ditambahkan',
            style: TextStyle(fontSize: 13, color: AppColors.subtitle),
          ),
        ],
      ),
    );
  }
}

/// Pesan gagal memuat kategori + tombol coba lagi.
class _CategoryError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _CategoryError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: AppColors.danger.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 20, color: AppColors.danger),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppColors.danger),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Coba lagi',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}