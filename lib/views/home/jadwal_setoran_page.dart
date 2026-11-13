import 'package:flutter/material.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

import '../../core/app_colors.dart';
import '../../models/jadwal_setoran_model.dart';
import '../../services/jadwal_setoran_service.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton_box.dart';

class JadwalSetoranPage extends StatefulWidget {
  const JadwalSetoranPage({super.key});

  @override
  State<JadwalSetoranPage> createState() => _JadwalSetoranPageState();
}

class _JadwalSetoranPageState extends State<JadwalSetoranPage> {
  final JadwalSetoranService _service = JadwalSetoranService();
  final DeviceCalendarPlugin _calendarPlugin = DeviceCalendarPlugin();

  bool _isLoading = true;
  bool _isSavingReminder = false;
  String? _selectedSessionId;

  // Menyimpan ID sesi yang sudah diaktifkan pengingatnya secara independen
  final Set<String> _activeReminderSessionIds = {};

  List<JadwalSetoran> _monthlySessions = [];

  @override
  void initState() {
    super.initState();
    tz_data.initializeTimeZones();
    _fetchScheduleData();
  }

  /// Mengambil data dari Backend Laravel & mengurutkan:
  /// - Sesi aktif: diurutkan dari tanggal paling dekat ke mendatang
  /// - Sesi selesai: dipindahkan ke paling bawah
  Future<void> _fetchScheduleData() async {
    try {
      final data = await _service.getJadwalSetoran();
      if (mounted) {
        final activeSessions = data.where((s) => !s.isCompleted).toList();
        final completedSessions = data.where((s) => s.isCompleted).toList();

        activeSessions.sort((a, b) => a.fullDate.compareTo(b.fullDate));
        completedSessions.sort((a, b) => b.fullDate.compareTo(a.fullDate));

        final sortedData = [...activeSessions, ...completedSessions];

        setState(() {
          _monthlySessions = sortedData;
          _isLoading = false;

          if (_monthlySessions.isNotEmpty) {
            final activeSession = _monthlySessions.firstWhere(
              (s) => !s.isCompleted,
              orElse: () => _monthlySessions.first,
            );
            _selectedSessionId = activeSession.id;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  JadwalSetoran? get _activeSession {
    if (_monthlySessions.isEmpty) return null;
    return _monthlySessions.firstWhere(
      (s) => s.id == _selectedSessionId,
      orElse: () => _monthlySessions.first,
    );
  }

  /// Menyimpan agenda 1-Klik secara langsung ke dalam Kalender HP (Background)
  Future<void> _addToDeviceCalendarDirectly(JadwalSetoran session) async {
    final isReminderActive = _activeReminderSessionIds.contains(session.id);

    // Toggle matikan pengingat
    if (isReminderActive) {
      setState(() {
        _activeReminderSessionIds.remove(session.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengingat setoran dibatalkan.'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    setState(() => _isSavingReminder = true);

    try {
      // 1. Minta & validasi izin akses Kalender Perangkat
      var permissionsGranted = await _calendarPlugin.hasPermissions();
      if (!permissionsGranted.isSuccess || !(permissionsGranted.data ?? false)) {
        permissionsGranted = await _calendarPlugin.requestPermissions();
      }

      if (!(permissionsGranted.data ?? false)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin akses kalender ditolak.'),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // 2. Ambil daftar kalender di HP
      final calendarsResult = await _calendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess ||
          calendarsResult.data == null ||
          calendarsResult.data!.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tidak ditemukan akun kalender aktif di HP Anda. Pastikan Google Calendar/akun HP sudah terhubung.',
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Filter hanya kalender yang tidak read-only
      final writableCalendars =
          calendarsResult.data!.where((c) => c.isReadOnly == false).toList();

      if (writableCalendars.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tidak ada kalender yang dapat diubah (writable) pada perangkat ini.',
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final Calendar defaultCalendar = writableCalendars.firstWhere(
        (c) => c.isDefault ?? false,
        orElse: () => writableCalendars.first,
      );

      tz.Location location;
      try {
        location = tz.getLocation('Asia/Jakarta');
      } catch (_) {
        location = tz.local;
      }

      final startTZ = tz.TZDateTime.from(session.fullDate, location);
      final endTZ = tz.TZDateTime.from(
        session.fullDate.add(const Duration(hours: 4)),
        location,
      );

      // 3. Buat dan simpan agenda secara otomatis tanpa membuka UI Kalender HP
      final event = Event(
        defaultCalendar.id,
        title: 'Jadwal Setor Sampah - ${session.sessionTitle}',
        description:
            'Persiapkan sampah yang sudah dipilah sesuai kategori sebelum disetorkan ke Bank Sampah.',
        location: session.wilayah ??
            'Perumahan Taman Gading No.99, Kel. Sumber Sari, Kec. Kaliwates',
        start: startTZ,
        end: endTZ,
      );

      final createResult = await _calendarPlugin.createOrUpdateEvent(event);

      if (createResult?.isSuccess == true && createResult?.data != null) {
        setState(() {
          _activeReminderSessionIds.add(session.id);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Pengingat (${session.dayNumber} ${session.monthYear}) berhasil disimpan ke Kalender HP!',
              ),
              backgroundColor: AppColors.primaryDark,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        final errors =
            createResult?.errors.map((e) => e.errorMessage).join(", ");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Gagal menyimpan ke kalender: ${errors?.isNotEmpty == true ? errors : "Terjadi kesalahan internal"}',
              ),
              backgroundColor: AppColors.danger,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingReminder = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surfaceGrey,
      appBar: const PrimaryAppBar(title: 'Jadwal Setoran'),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _fetchScheduleData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Card Utama / Skeleton Loading
              _isLoading
                  ? _buildHeroCardSkeleton()
                  : (_activeSession != null
                      ? _buildHeroScheduleCard(_activeSession!)
                      : const SizedBox.shrink()),
              const SizedBox(height: 16),

              // 2. Daftar Jadwal Bulan Ini
              _isLoading
                  ? _buildMonthlyScheduleSkeleton()
                  : _buildMonthlyScheduleSection(),
              const SizedBox(height: 16),

              // 3. Kartu Lokasi Penimbangan
              _buildLocationCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCardSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 160, height: 22, borderRadius: 8),
              SkeletonBox(width: 80, height: 22, borderRadius: 20),
            ],
          ),
          SizedBox(height: 20),
          Row(
            children: [
              SkeletonBox(width: 110, height: 95, borderRadius: 14),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 100, height: 16),
                    SizedBox(height: 8),
                    SkeletonBox(width: 140, height: 28, borderRadius: 8),
                    SizedBox(height: 8),
                    SkeletonBox(
                      width: double.infinity,
                      height: 24,
                      borderRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: 52, borderRadius: 12),
        ],
      ),
    );
  }

  Widget _buildMonthlyScheduleSkeleton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SkeletonBox(width: 140, height: 20),
              SkeletonBox(width: 70, height: 20, borderRadius: 20),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 60, borderRadius: 12),
          SizedBox(height: 10),
          SkeletonBox(width: double.infinity, height: 60, borderRadius: 12),
        ],
      ),
    );
  }

  Widget _buildHeroScheduleCard(JadwalSetoran session) {
    final isReminderActive = _activeReminderSessionIds.contains(session.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(19),
                topRight: Radius.circular(19),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jadwal Setor Sampah',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Bulan ${session.monthYear}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: session.isCompleted
                        ? const Color(0xFFE0E0E0)
                        : const Color(0xFFFFD54F),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        session.isCompleted
                            ? Icons.check_circle_outline
                            : Icons.hourglass_top_rounded,
                        size: 13,
                        color: session.isCompleted
                            ? AppColors.subtitle
                            : AppColors.textDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        session.countdownText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: session.isCompleted
                              ? AppColors.subtitle
                              : AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 110,
                      padding: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(13),
                                topRight: Radius.circular(13),
                              ),
                            ),
                            child: Text(
                              session.dayName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Text(
                              '${session.dayNumber}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark,
                                height: 1.1,
                              ),
                            ),
                          ),
                          Text(
                            session.monthYear,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.subtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                color: AppColors.primaryDark,
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Jam Setor Opsional',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.subtitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutralLight,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              session.timeRange,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primaryDark,
                                  size: 14,
                                ),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Petugas siaga di lokasi',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  text: isReminderActive ? 'Hapus Pengingat' : 'Ingatkan Saya',
                  isLoading: _isSavingReminder,
                  isOutlined: isReminderActive,
                  icon: isReminderActive
                      ? Icons.notifications_off_rounded
                      : Icons.notifications_active_rounded,
                  onPressed: () => _addToDeviceCalendarDirectly(session),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.divider),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.primaryDark,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pastikan sampah sudah dipilah sesuai kategori sebelum disetorkan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryDark,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyScheduleSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 16,
                        color: AppColors.primaryDark,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Jadwal Bulan Ini',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Diurutkan dari jadwal terdekat & mendatang',
                    style: TextStyle(fontSize: 10, color: AppColors.subtitle),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  '${_monthlySessions.length} Setoran',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Column(
            children: _monthlySessions.map((session) {
              final isSelected = session.id == _selectedSessionId;
              final isCompleted = session.isCompleted;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0),
                child: InkWell(
                  onTap: isCompleted
                      ? null
                      : () {
                          setState(() {
                            _selectedSessionId = session.id;
                          });
                        },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.white
                          : (isSelected ? AppColors.primarySoft : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCompleted
                            ? AppColors.border.withOpacity(0.6)
                            : (isSelected
                                  ? AppColors.primary
                                  : AppColors.border),
                        width: isSelected && !isCompleted ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    session.sessionTitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: isCompleted
                                          ? AppColors.subtitle
                                          : AppColors.primaryDark,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? AppColors.neutralLight
                                          : const Color(0xFFFFD54F),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      session.countdownText,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: isCompleted
                                            ? AppColors.subtitle
                                            : AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${session.dayNumber.toString().padLeft(2, '0')} ${session.monthYear}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isCompleted
                                      ? AppColors.subtitle
                                      : AppColors.textDark,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${session.dayName} • ${session.timeRange}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? AppColors.subtitle
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCompleted
                                  ? AppColors.hint
                                  : (isSelected
                                        ? AppColors.primaryDark
                                        : AppColors.hint),
                              width: isSelected && !isCompleted ? 2 : 1.5,
                            ),
                          ),
                          child: isSelected && !isCompleted
                              ? Center(
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primaryDark,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppColors.danger,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lokasi Penimbangan',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Perumahan Taman Gading No.99, Kel. Sumber Sari, Kec. Kaliwates',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.subtitle,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Membuka rute lokasi di Peta...'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.map_outlined,
                    size: 15,
                    color: AppColors.primaryDark,
                  ),
                  label: const Text(
                    'Buka Peta',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menghubungi PJ via WhatsApp...'),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    size: 15,
                    color: AppColors.primaryDark,
                  ),
                  label: const Text(
                    'Hubungi PJ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: AppColors.primarySoft,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}