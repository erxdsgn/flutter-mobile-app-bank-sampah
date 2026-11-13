class LeaderboardEntry {
  final String idWarga;
  final int rank;
  final String nama;
  final String initials;
  final int totalPoints;
  final int totalSetor;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.idWarga,
    required this.rank,
    required this.nama,
    required this.initials,
    required this.totalPoints,
    required this.totalSetor,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final idWarga = json['id_warga']?.toString() ?? '';
    return LeaderboardEntry(
      idWarga: idWarga,
      rank: json['rank'] ?? 0,
      nama: json['nama'] ?? '',
      initials: json['initials'] ?? '',
      totalPoints: json['total_poin'] ?? 0,
      totalSetor: json['total_setor'] ?? 0,
      // Pencocokan otomatis: true jika id_warga dari API sama dengan yang tersimpan di SharedPreferences
      isCurrentUser: currentUserId != null && idWarga == currentUserId, 
    );
  }
}