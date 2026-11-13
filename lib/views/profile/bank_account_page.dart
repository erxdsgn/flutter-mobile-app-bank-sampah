import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../widgets/primary_app_bar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/skeleton_box.dart';

class BankAccountPage extends StatefulWidget {
  const BankAccountPage({super.key});

  @override
  State<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends State<BankAccountPage> {
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = true;
  bool _isSaving = false;

  // Data profil existing
  String _currentUsername = '';
  String _currentNama = '';
  String _statusRekening = 'unverified';

  // Form Controllers & State
  String? _selectedBank;
  final TextEditingController _nomorRekeningController = TextEditingController();
  final TextEditingController _namaPemilikController = TextEditingController();

  // Daftar Pilihan Bank & E-Wallet
  final List<String> _bankOptions = [
    'Bank BCA',
    'Bank BRI',
    'Bank Mandiri',
    'Bank BNI',
    'Bank BSI',
    'GoPay',
    'OVO',
    'DANA',
    'ShopeePay',
    'LinkAja',
  ];

  @override
  void initState() {
    super.initState();
    _loadBankAccountData();
  }

  @override
  void dispose() {
    _nomorRekeningController.dispose();
    _namaPemilikController.dispose();
    super.dispose();
  }

  // --- AMBIL DATA DARI API ---
  Future<void> _loadBankAccountData() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.get('me');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['data'];
        final profil = data['profil'] ?? {};

        _currentUsername = data['username'] ?? '';
        _currentNama = profil['nama'] ?? '';
        _statusRekening = profil['status_rekening']?.toString() ?? 'unverified';

        final bankExisting = profil['nama_bank_ewallet']?.toString().trim() ?? '';
        final noRekExisting = profil['nomor_rekening']?.toString().trim() ?? '';
        final namaPemilikExisting = profil['nama_pemilik_rekening']?.toString().trim() ?? '';

        setState(() {
          if (bankExisting.isNotEmpty && bankExisting != 'null') {
            if (_bankOptions.contains(bankExisting)) {
              _selectedBank = bankExisting;
            } else {
              _bankOptions.add(bankExisting);
              _selectedBank = bankExisting;
            }
          } else {
            _selectedBank = null;
          }

          _nomorRekeningController.text = (noRekExisting != 'null') ? noRekExisting : '';
          _namaPemilikController.text = (namaPemilikExisting.isNotEmpty && namaPemilikExisting != 'null')
              ? namaPemilikExisting
              : _currentNama;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error load bank data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- HELPER FORMAT NOMOR REKENING (SPASI SETIAP 4 ANGKA) ---
  String _formatSpacedRekening(String raw) {
    final clean = raw.replaceAll(RegExp(r'\D'), '');
    if (clean.isEmpty) return '-';

    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write('  ');
      }
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  // --- SIMPAN DATA REKENING ---
  Future<void> _saveBankAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final payload = {
        'username': _currentUsername,
        'nama': _currentNama,
        'nama_bank_ewallet': _selectedBank ?? '',
        'nomor_rekening': _nomorRekeningController.text.trim(),
        'nama_pemilik_rekening': _namaPemilikController.text.trim(),
      };

      final response = await ApiService.put(
        'update-profile',
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200 && data['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Data rekening berhasil diperbarui!"),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Gagal menyimpan data rekening"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Koneksi error: $e"),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: const PrimaryAppBar(
        title: "Rekening Bank Tujuan",
        automaticallyImplyLeading: true,
      ),
      body: _isLoading
          ? _buildSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- 1. KARTU REKENING TERDAFTAR ---
                    _buildBankCardHeader(),
                    const SizedBox(height: 16),

                    // --- 2. BANNER INFORMASI / PERINGATAN ---
                    _buildWarningBanner(),
                    const SizedBox(height: 20),

                    // --- 3. CONTAINER FORMULIR ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.black.withOpacity(0.05)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dropdown Bank
                          const Text(
                            "Pilih Bank / E-Wallet",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBank,
                            hint: const Text(
                              "Pilih Bank atau E-Wallet",
                              style: TextStyle(color: AppColors.muted, fontSize: 14),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF4A5568)),
                            decoration: _inputDecoration(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF2D3748),
                              fontWeight: FontWeight.w500,
                            ),
                            items: _bankOptions.map((bank) {
                              return DropdownMenuItem(
                                value: bank,
                                child: Text(bank),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedBank = val);
                            },
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return "Pilih jenis bank atau e-wallet";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Nomor Rekening
                          const Text(
                            "Nomor Rekening / HP",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nomorRekeningController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3748),
                            ),
                            decoration: _inputDecoration(
                              hint: "Contoh: 889920201772",
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Nomor rekening wajib diisi";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Nama Pemilik Rekening
                          const Text(
                            "Nama Pemilik Rekening",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _namaPemilikController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3748),
                            ),
                            decoration: _inputDecoration(
                              hint: "Nama sesuai rekening",
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return "Nama pemilik rekening wajib diisi";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // --- 4. PRIMARY BUTTON ---
                          PrimaryButton(
                            text: "Simpan Perubahan",
                            isLoading: _isSaving,
                            onPressed: _isSaving ? null : _saveBankAccount,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // --- WIDGET KARTU DIGITAL GREEN DENGAN IKON TERAMPIL ---
  Widget _buildBankCardHeader() {
    final bank = (_selectedBank != null && _selectedBank!.isNotEmpty)
        ? _selectedBank!
        : 'Belum Terdaftar';

    final rawNoRek = _nomorRekeningController.text.trim();
    final noRekFormatted = _formatSpacedRekening(rawNoRek);

    final rawNama = _namaPemilikController.text.trim();
    final nama = rawNama.isNotEmpty
        ? rawNama.toUpperCase()
        : (_currentNama.isNotEmpty ? _currentNama.toUpperCase() : '-');

    final isTerverifikasi = _statusRekening.toLowerCase() == 'verified' ||
        _statusRekening.toLowerCase() == 'active' ||
        _statusRekening.toLowerCase() == 'terverifikasi';

    final isEwallet = bank.contains('GoPay') ||
        bank.contains('OVO') ||
        bank.contains('DANA') ||
        bank.contains('ShopeePay') ||
        bank.contains('LinkAja');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF007A5E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007A5E).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // --- IKON WATERMARK SISI KANAN KARTU (TELAH DIPERBAIKI) ---
          Positioned(
            right: 10,
            bottom: 10,
            child: Icon(
              isEwallet
                  ? Icons.account_balance_wallet_rounded
                  : Icons.credit_card_rounded,
              size: 80,
              color: Colors.white.withOpacity(0.18),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "REKENING TERDAFTAR",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),

                  // BADGE STATUS VERIFIKASI
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white30, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isTerverifikasi
                              ? Icons.check_circle
                              : Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isTerverifikasi ? "Terverifikasi" : "Belum Terverifikasi",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // NAMA BANK BESERTA IKON UTAMA
              Row(
                children: [
                  Icon(
                    isEwallet ? Icons.account_balance_wallet : Icons.account_balance,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    bank,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // NOMOR REKENING DENGAN SPASI PER 4 ANGKA
              Text(
                noRekFormatted,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "a.n. $nama",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET BANNER WARNING KUNING ---
  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Color(0xFFD97706),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.info, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF92400E),
                  height: 1.4,
                ),
                children: const [
                  TextSpan(text: "Pastikan nama pada pemilik rekening "),
                  TextSpan(
                    text: "sama persis",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text: " dengan nama akun Anda untuk kelancaran penarikan saldo sampah.",
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- STYLING DEKORASI INPUT ---
  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  // --- SKELETON LOADING ---
  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonBox(width: double.infinity, height: 160, borderRadius: 20),
          SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 60, borderRadius: 14),
          SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: 300, borderRadius: 20),
        ],
      ),
    );
  }
}