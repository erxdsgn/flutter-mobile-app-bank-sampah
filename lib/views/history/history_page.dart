// lib/views/history/history_page.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/helpers/transaction_helpers.dart';
import '../../models/transaksi_model.dart';
import '../../services/setoran_service.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/skeleton_box.dart';
import '../../widgets/transaction_history_card.dart';
import '../../widgets/transaction_tile.dart';
import 'history_detail_page.dart';

enum FilterType { semua, bulan, tanggal }

class HistoryPage extends StatefulWidget {
  final String token;
  final StatusSetoran initialTab;

  const HistoryPage({
    super.key,
    required this.token,
    this.initialTab = StatusSetoran.menunggu,
  });

  @override
  State<HistoryPage> createState() => HistoryPageState();
}

class HistoryPageState extends State<HistoryPage> {
  final SetoranService _service = SetoranService();

  List<TransaksiModel> _all = [];
  bool _loading = true;
  String? _error;

  // State Filter Modern
  FilterType _filterType = FilterType.semua;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  DateTime _selectedDate = DateTime.now();

  static const List<String> _namaBulan = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember'
  ];

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    List<TransaksiModel>? result;
    String? error;

    try {
      result = await _service.getHistory(widget.token);
      result.sort((a, b) => b.id.compareTo(a.id));
    } on TimeoutException {
      error = 'Server tidak merespons. Periksa koneksi lalu coba lagi.';
    } on SocketException {
      error = 'Tidak dapat terhubung ke server.';
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result != null) {
        _all = result;
      } else {
        _error = error ?? 'Gagal memuat history.';
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

  List<TransaksiModel> _byStatus(StatusSetoran status) {
    var filtered = _all.where((t) => _parseStatus(t.status) == status).toList();

    if (_filterType == FilterType.bulan) {
      filtered = filtered.where((t) {
        try {
          final dt = DateTime.parse(t.tanggal);
          return dt.year == _selectedYear && dt.month == _selectedMonth;
        } catch (_) {
          return true;
        }
      }).toList();
    } else if (_filterType == FilterType.tanggal) {
      filtered = filtered.where((t) {
        try {
          final dt = DateTime.parse(t.tanggal);
          return dt.year == _selectedDate.year &&
              dt.month == _selectedDate.month &&
              dt.day == _selectedDate.day;
        } catch (_) {
          return true;
        }
      }).toList();
    }

    return filtered;
  }

  void _openDetail(TransaksiModel trx) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetailHistoryPage(transaksi: trx)),
    );
  }

  String get _filterLabel {
    if (_filterType == FilterType.bulan) {
      return '${_namaBulan[_selectedMonth - 1]} $_selectedYear';
    } else if (_filterType == FilterType.tanggal) {
      return '${_selectedDate.day} ${_namaBulan[_selectedDate.month - 1]} ${_selectedDate.year}';
    }
    return 'Semua Transaksi';
  }

  // ==========================================
  // MODAL BOTTOM SHEET FILTER MODERN
  // ==========================================
  void _showModernFilterSheet() {
    FilterType tempType = _filterType;
    int tempYear = _selectedYear;
    int tempMonth = _selectedMonth;
    DateTime tempDate = _selectedDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Filter Riwayat',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.neutralLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _filterTabChip('Semua', FilterType.semua, tempType, () {
                          setSheetState(() => tempType = FilterType.semua);
                        }),
                        _filterTabChip('Per Bulan', FilterType.bulan, tempType, () {
                          setSheetState(() => tempType = FilterType.bulan);
                        }),
                        _filterTabChip('Per Tanggal', FilterType.tanggal, tempType, () {
                          setSheetState(() => tempType = FilterType.tanggal);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (tempType == FilterType.bulan) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            setSheetState(() => tempYear--);
                          },
                        ),
                        Text(
                          '$tempYear',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            setSheetState(() => tempYear++);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final isSelected = (index + 1) == tempMonth;
                        return InkWell(
                          onTap: () {
                            setSheetState(() => tempMonth = index + 1);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.surfaceTint,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _namaBulan[index],
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.text,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else if (tempType == FilterType.tanggal) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded,
                                  color: AppColors.primary, size: 22),
                              const SizedBox(width: 10),
                              Text(
                                '${tempDate.day} ${_namaBulan[tempDate.month - 1]} ${tempDate.year}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.text,
                                ),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) {
                                setSheetState(() => tempDate = picked);
                              }
                            },
                            child: const Text('Ganti'),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Menampilkan seluruh riwayat transaksi.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterType = FilterType.semua;
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filterType = tempType;
                              _selectedYear = tempYear;
                              _selectedMonth = tempMonth;
                              _selectedDate = tempDate;
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Terapkan Filter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _filterTabChip(
    String label,
    FilterType type,
    FilterType currentType,
    VoidCallback onTap,
  ) {
    final isSelected = type == currentType;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pending = _byStatus(StatusSetoran.menunggu);
    final accepted = _byStatus(StatusSetoran.diterima);
    final rejected = _byStatus(StatusSetoran.ditolak);

    return DefaultTabController(
      length: 3,
      initialIndex: widget.initialTab.index,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: PrimaryAppBar(
          title: 'Riwayat Transaksi',
          automaticallyImplyLeading: false, // Menghilangkan tombol back otomatis
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              _buildTab('Menunggu', pending.length, highlight: true),
              _buildTab('Diterima', accepted.length),
              _buildTab('Ditolak', rejected.length),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: _buildBody(pending, accepted, rejected),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: Row(
        children: [
          InkWell(
            onTap: _showModernFilterSheet,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _filterType != FilterType.semua
                    ? AppColors.primary.withOpacity(0.12)
                    : AppColors.neutralLight,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _filterType != FilterType.semua
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Icon(
                Icons.tune_rounded,
                size: 20,
                color: _filterType != FilterType.semua
                    ? AppColors.primary
                    : Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: _showModernFilterSheet,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _filterLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.black45,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int count, {bool highlight = false}) {
    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (highlight && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB020),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBody(
    List<TransaksiModel> pending,
    List<TransaksiModel> accepted,
    List<TransaksiModel> rejected,
  ) {
    if (_loading) {
      return const _HistoryListSkeleton();
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: reload, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      children: [
        _StatusList(
          status: StatusSetoran.menunggu,
          items: pending,
          onRefresh: reload,
          onTap: _openDetail,
        ),
        _StatusList(
          status: StatusSetoran.diterima,
          items: accepted,
          onRefresh: reload,
          onTap: _openDetail,
        ),
        _StatusList(
          status: StatusSetoran.ditolak,
          items: rejected,
          onRefresh: reload,
          onTap: _openDetail,
        ),
      ],
    );
  }
}

// ======================================================
// SKELETON LOADING LIST RIWAYAT
// ======================================================

class _HistoryListSkeleton extends StatelessWidget {
  const _HistoryListSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SkeletonBox(width: 120, height: 14),
                  SkeletonBox(width: 80, height: 14),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),

              ...List.generate(4, (index) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      SkeletonBox(width: 38, height: 38, borderRadius: 19),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonBox(width: 110, height: 13),
                            SizedBox(height: 6),
                            SkeletonBox(width: 80, height: 10),
                          ],
                        ),
                      ),
                      SkeletonBox(width: 18, height: 18, borderRadius: 9),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

// ======================================================
// DAFTAR PER STATUS
// ======================================================

class _StatusList extends StatelessWidget {
  final StatusSetoran status;
  final List<TransaksiModel> items;
  final Future<void> Function() onRefresh;
  final void Function(TransaksiModel) onTap;

  const _StatusList({
    required this.status,
    required this.items,
    required this.onRefresh,
    required this.onTap,
  });

  String get _emptyText {
    switch (status) {
      case StatusSetoran.menunggu:
        return 'Tidak ada setoran yang menunggu konfirmasi admin.';
      case StatusSetoran.diterima:
        return 'Belum ada setoran yang diterima admin.';
      case StatusSetoran.ditolak:
        return 'Tidak ada setoran yang ditolak.';
    }
  }

  double get _totalPendapatan {
    return items.fold(0.0, (sum, item) => sum + item.totalNilai);
  }

  String _buildSubtitle(TransaksiModel trx) {
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

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          if (status == StatusSetoran.menunggu && items.isNotEmpty)
            _PendingNotice(count: items.length),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 80),
              child: Column(
                children: [
                  Icon(status.icon, size: 48, color: status.color.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  Text(
                    _emptyText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Colors.black45),
                  ),
                ],
              ),
            )
          else
            TransactionHistoryCard(
              title: 'Total Pendapatan',
              actionText: formatRupiah(_totalPendapatan),
              children: items.map((trx) {
                return TransactionTile(
                  title: 'Setor Sampah',
                  subtitle: _buildSubtitle(trx),
                  onTap: () => onTap(trx),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _PendingNotice extends StatelessWidget {
  final int count;

  const _PendingNotice({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: StatusSetoran.menunggu.softColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: StatusSetoran.menunggu.color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$count setoran menunggu konfirmasi admin. '
              'Saldo bertambah setelah setoran disetujui.',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}