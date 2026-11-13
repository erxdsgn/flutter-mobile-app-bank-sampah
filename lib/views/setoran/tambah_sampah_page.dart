// lib/views/setoran/tambah_sampah_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../core/formatters.dart';
import '../../models/item_setoran_model.dart';
import '../../models/kategori_sampah_model.dart';
import '../../widgets/app_dropdown_field.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/setoran_info_header.dart';

class TambahSampahPage extends StatefulWidget {
  final List<KategoriSampahModel> daftarKategori;
  final String namaWarga;

  const TambahSampahPage({
    super.key,
    required this.daftarKategori,
    required this.namaWarga,
  });

  @override
  State<TambahSampahPage> createState() => _TambahSampahPageState();
}

class _TambahSampahPageState extends State<TambahSampahPage> {
  /// Satuan yang boleh berkoma (mis. 2,5 kg). Satuan lain (unit, set, dst.)
  /// hanya menerima bilangan bulat. Tambahkan satuan lain di sini bila perlu.
  static const Set<String> _satuanDesimal = {'kg'};

  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController(text: '1');
  final DateTime _tanggal = DateTime.now();

  KategoriSampahModel? _kategori;

  @override
  void initState() {
    super.initState();
    _jumlahController.addListener(_onJumlahChanged);
  }

  @override
  void dispose() {
    _jumlahController.removeListener(_onJumlahChanged);
    _jumlahController.dispose();
    super.dispose();
  }

  void _onJumlahChanged() {
    if (mounted) setState(() {}); // perbarui estimasi nilai
  }

  bool _isDesimal(KategoriSampahModel? k) =>
      k != null && _satuanDesimal.contains(k.satuan.trim().toLowerCase());

  bool get _boleDesimal => _isDesimal(_kategori);

  double get _jumlah => Formatters.parseAngka(_jumlahController.text) ?? 0;

  double get _estimasi => (_kategori?.hargaSatuan ?? 0) * _jumlah;

  void _onKategoriChanged(KategoriSampahModel? val) {
    // Jika satuan baru tidak boleh berkoma, bulatkan jumlah yang terlanjur
    // berkoma.
    final lama = _jumlah;
    if (!_isDesimal(val) && lama % 1 != 0) {
      final bulat = lama.round();
      _jumlahController.text = (bulat < 1 ? 1 : bulat).toString();
    }
    setState(() => _kategori = val);
  }

  void _confirm() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      ItemSetoranModel(
        kategori: _kategori!,
        jumlah: double.parse(_jumlah.toStringAsFixed(2)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PrimaryAppBar(title: 'Tambah Sampah'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SetoranInfoHeader(
                        namaWarga: widget.namaWarga,
                        tanggal: Formatters.tanggal(_tanggal),
                      ),
                      const SizedBox(height: 24),

                      // Kategori (lebar) + Jumlah (sempit)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 13,
                            child: AppDropdownField<KategoriSampahModel>(
                              label: 'Kategori Sampah',
                              hint: 'pilih kategori...',
                              value: _kategori,
                              items: widget.daftarKategori,
                              itemLabel: (k) => k.namaKategori,
                              validator: (v) =>
                                  v == null ? 'Pilih kategori' : null,
                              onChanged: _onKategoriChanged,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 7,
                            child: AppTextField(
                              label: _kategori == null
                                  ? 'Jumlah'
                                  : 'Jumlah (${_kategori!.satuan})',
                              hint: '1',
                              controller: _jumlahController,
                              textInputAction: TextInputAction.done,
                              maxLength: 7,
                              keyboardType: _boleDesimal
                                  ? const TextInputType.numberWithOptions(
                                      decimal: true,
                                    )
                                  : TextInputType.number,
                              inputFormatters: _boleDesimal
                                  ? [
                                      // maks. 4 digit + 2 desimal, titik/koma
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d{0,4}([.,]\d{0,2})?'),
                                      ),
                                    ]
                                  : [FilteringTextInputFormatter.digitsOnly],
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Wajib diisi';
                                }
                                final n = Formatters.parseAngka(v);
                                if (n == null || n <= 0) return 'Harus > 0';
                                if (!_boleDesimal && n % 1 != 0) {
                                  return 'Harus bulat';
                                }
                                if (n > 9999) return 'Terlalu besar';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _EstimateCard(
                        estimasi: _estimasi,
                        kategori: _kategori,
                        jumlah: _jumlah,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: PrimaryButton(text: 'Konfirmasi', onPressed: _confirm),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kartu estimasi nilai. Setelah kategori dipilih, ditampilkan juga
/// rincian perhitungannya (harga satuan x jumlah).
class _EstimateCard extends StatelessWidget {
  final double estimasi;
  final KategoriSampahModel? kategori;
  final double jumlah;

  const _EstimateCard({
    required this.estimasi,
    required this.kategori,
    required this.jumlah,
  });

  @override
  Widget build(BuildContext context) {
    final k = kategori;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Estimasi nilai',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryDark,
                ),
              ),
              Text(
                Formatters.rupiah(estimasi),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          if (k != null) ...[
            const SizedBox(height: 6),
            Text(
              '${Formatters.rupiah(k.hargaSatuan)} / ${k.satuan}'
              '  ×  ${Formatters.jumlah(jumlah, k.satuan)}',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }
}