import 'package:flutter/material.dart';
import '../core/app_colors.dart';

/// Kartu hijau tua berisi saldo tabungan dan nomor rekening.
/// Ikon mata dipakai untuk menyembunyikan / menampilkan saldo.
class BalanceCard extends StatelessWidget {
  final String balance;
  final String accountNumber;
  final bool isHidden;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onAddAccount; // Callback opsional untuk mengarah ke Profile

  const BalanceCard({
    super.key,
    required this.balance,
    required this.accountNumber,
    required this.isHidden,
    required this.onToggleVisibility,
    this.onAddAccount,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAccountEmpty =
        accountNumber.isEmpty || accountNumber == 'Belum tersedia';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo Tabungan',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(
                  isHidden ? 'Rp ••••••••' : balance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onToggleVisibility,
                behavior: HitTestBehavior.opaque,
                child: Icon(
                  isHidden
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 24,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1.5, color: AppColors.primary),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'No. rek $accountNumber',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, color: Colors.white),
                ),
              ),
              if (isAccountEmpty) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onAddAccount,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 14,
                          color: Colors.black87,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Atur',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}