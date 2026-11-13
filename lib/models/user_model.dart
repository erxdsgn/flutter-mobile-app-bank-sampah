class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final String? avatarUrl; // <-- TAMBAHKAN INI
  final WargaModel? profil;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    this.avatarUrl, // <-- TAMBAHKAN INI
    this.profil,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: int.tryParse(json['id'].toString()) ?? 0,
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'warga',
      avatarUrl: json['avatar_url'] as String?, // <-- TAMBAHKAN INI
      profil: json['profil'] != null
          ? WargaModel.fromJson(json['profil'])
          : null,
    );
  }
}

class WargaModel {
  final String idWarga;
  final String nik;
  final String nama;
  final String? noHp;
  final String? alamat;
  final double saldo;
  final String namaBankEwallet;
  final String nomorRekening;
  final String namaPemilikRekening;
  final String statusRekening;

  WargaModel({
    required this.idWarga,
    required this.nik,
    required this.nama,
    this.noHp,
    this.alamat,
    required this.saldo,
    this.namaBankEwallet = '',
    this.nomorRekening = '',
    this.namaPemilikRekening = '',
    required this.statusRekening,
  });

  factory WargaModel.fromJson(Map<String, dynamic> json) {
    return WargaModel(
      idWarga: json['id_warga']?.toString() ?? '',
      nik: json['nik']?.toString() ?? '',
      nama: json['nama']?.toString() ?? '',
      noHp: json['no_hp']?.toString(),
      alamat: json['alamat']?.toString(),
      saldo: double.tryParse(json['saldo']?.toString() ?? '') ?? 0.0,
      namaBankEwallet: json['nama_bank_ewallet']?.toString() ?? '',
      nomorRekening: json['nomor_rekening']?.toString() ?? '',
      namaPemilikRekening: json['nama_pemilik_rekening']?.toString() ?? '',
      statusRekening: json['status_rekening']?.toString() ?? 'unverified',
    );
  }
}