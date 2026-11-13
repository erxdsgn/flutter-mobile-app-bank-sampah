class JadwalSetoran {
  final String id; // Ubah dari int menjadi String
  final String sessionTitle;
  final String dayName;
  final int dayNumber;
  final String monthYear;
  final DateTime fullDate;
  final String timeRange;
  final String countdownText;
  final bool isCompleted;
  final String? wilayah;
  final int? kuotaMaksimal;
  final String? keterangan;
  final String status;

  JadwalSetoran({
    required this.id,
    required this.sessionTitle,
    required this.dayName,
    required this.dayNumber,
    required this.monthYear,
    required this.fullDate,
    required this.timeRange,
    required this.countdownText,
    required this.isCompleted,
    this.wilayah,
    this.kuotaMaksimal,
    this.keterangan,
    required this.status,
  });

  factory JadwalSetoran.fromJson(Map<String, dynamic> json) {
    return JadwalSetoran(
      id: (json['id'] ?? json['id_jadwal'])?.toString() ?? '',
      sessionTitle: json['sessionTitle']?.toString() ?? '',
      dayName: json['dayName']?.toString() ?? '',
      dayNumber: json['dayNumber'] is int
          ? json['dayNumber']
          : int.tryParse(json['dayNumber']?.toString() ?? '0') ?? 0,
      monthYear: json['monthYear']?.toString() ?? '',
      fullDate: DateTime.tryParse(json['fullDate']?.toString() ?? '') ?? DateTime.now(),
      timeRange: json['timeRange']?.toString() ?? '',
      countdownText: json['countdownText']?.toString() ?? '',
      isCompleted: json['isCompleted'] == true ||
          json['isCompleted'] == 1 ||
          json['isCompleted'] == '1',
      wilayah: json['wilayah']?.toString(),
      kuotaMaksimal: json['kuotaMaksimal'] != null
          ? (json['kuotaMaksimal'] is int
              ? json['kuotaMaksimal']
              : int.tryParse(json['kuotaMaksimal'].toString()))
          : null,
      keterangan: json['keterangan']?.toString(),
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionTitle': sessionTitle,
      'dayName': dayName,
      'dayNumber': dayNumber,
      'monthYear': monthYear,
      'fullDate': fullDate.toIso8601String(),
      'timeRange': timeRange,
      'countdownText': countdownText,
      'isCompleted': isCompleted,
      'wilayah': wilayah,
      'kuotaMaksimal': kuotaMaksimal,
      'keterangan': keterangan,
      'status': status,
    };
  }
}