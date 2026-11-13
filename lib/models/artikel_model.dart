class ItemDataModel {
  final int idArtikel;
  final String title;
  final String description;
  final String category;
  final bool isEvent;
  final String? extraInfo;
  final String? imageUrl;

  ItemDataModel({
    required this.idArtikel,
    required this.title,
    required this.description,
    required this.category,
    required this.isEvent,
    this.extraInfo,
    this.imageUrl,
  });

  factory ItemDataModel.fromJson(Map<String, dynamic> json) {
    String jenis = (json['jenis'] ?? 'artikel').toString().toLowerCase();
    bool isEv = jenis == 'acara' || jenis == 'event';

    String kategoriLabel = 'Artikel';
    if (jenis == 'edukasi') {
      kategoriLabel = 'Edukasi';
    } else if (isEv) {
      kategoriLabel = 'Event';
    }

    return ItemDataModel(
      idArtikel: json['id_artikel'],
      title: json['judul'] ?? '',
      description: json['konten'] ?? '',
      category: kategoriLabel,
      isEvent: isEv,
      extraInfo: json['tanggal_publish'] != null 
          ? 'Dipublikasikan: ${json['tanggal_publish'].toString().split('T')[0]}' 
          : 'Draft',
      imageUrl: json['gambar'],
    );
  }
}