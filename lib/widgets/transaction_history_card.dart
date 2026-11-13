// lib/widgets/transaction_history_card.dart
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import 'section_header.dart';

class TransactionHistoryCard extends StatelessWidget {
  final String title;
  final String? actionText;
  final VoidCallback? onSeeAll;
  final List<Widget> children;

  const TransactionHistoryCard({
    super.key,
    this.title = 'Riwayat Transaksi',
    this.actionText,
    this.onSeeAll,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    for (var i = 0; i < children.length; i++) {
      items.add(children[i]);

      if (i != children.length - 1) {
        items.add(
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AppColors.divider,
            ),
          ),
        );
      }
    }

    return Container(
      // Memberikan efek bayangan lembut agar card timbul dari background
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const _TicketBorderPainter(),
        child: ClipPath(
          clipper: const _TicketCardClipper(),
          child: Container(
            width: double.infinity,
            color: Colors.white, // <-- Putih bersih agar tidak menyatu dengan background abu-abu muda
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: actionText != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                              ),
                            ),
                            Text(
                              actionText!,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        )
                      : SectionHeader(
                          title: title,
                          onAction: onSeeAll,
                          titleStyle: const TextStyle(
                            fontSize: 15,
                            color: AppColors.text,
                          ),
                        ),
                ),

                // Garis putus-putus di antara header dan transaksi
                const _TicketDivider(),

                const SizedBox(height: 4),

                ...items,

                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ======================================================
// BENTUK KARTU DENGAN CEKUNGAN KIRI DAN KANAN
// ======================================================

class _TicketCardClipper extends CustomClipper<Path> {
  const _TicketCardClipper();

  @override
  Path getClip(Size size) {
    return _buildTicketPath(size);
  }

  @override
  bool shouldReclip(covariant _TicketCardClipper oldClipper) {
    return false;
  }
}

// ======================================================
// BORDER KARTU MENGIKUTI BENTUK CEKUNGAN
// ======================================================

class _TicketBorderPainter extends CustomPainter {
  const _TicketBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildTicketPath(size);

    final paint = Paint()
      ..color = Colors.grey.shade300 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5; // <-- Diperkecil menjadi 0.5 agar border terlihat sangat tipis dan rapi

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TicketBorderPainter oldDelegate) {
    return false;
  }
}

// ======================================================
// PATH KARTU
// ======================================================

Path _buildTicketPath(Size size) {
  const cornerRadius = 22.0;
  const notchRadius = 13.0;
  const notchCenterY = 55.0;

  const inset = 0.5;

  final left = inset;
  final top = inset;
  final right = size.width - inset;
  final bottom = size.height - inset;

  final cy = top + notchCenterY;
  final r = notchRadius;

  final path = Path();

  // Mulai dari sudut kiri atas
  path.moveTo(left + cornerRadius, top);

  // Sudut kanan atas
  path.lineTo(right - cornerRadius, top);
  path.quadraticBezierTo(
    right,
    top,
    right,
    top + cornerRadius,
  );

  // Menuju cekungan kanan
  path.lineTo(right, cy - r);

  // Cekungan kanan
  path.cubicTo(
    right - (r * 1.33),
    cy - r,
    right - (r * 1.33),
    cy + r,
    right,
    cy + r,
  );

  // Sisi kanan bawah
  path.lineTo(right, bottom - cornerRadius);

  path.quadraticBezierTo(
    right,
    bottom,
    right - cornerRadius,
    bottom,
  );

  // Sisi bawah
  path.lineTo(left + cornerRadius, bottom);

  // Sudut kiri bawah
  path.quadraticBezierTo(
    left,
    bottom,
    left,
    bottom - cornerRadius,
  );

  // Menuju cekungan kiri
  path.lineTo(left, cy + r);

  // Cekungan kiri
  path.cubicTo(
    left + (r * 1.33),
    cy + r,
    left + (r * 1.33),
    cy - r,
    left,
    cy - r,
  );

  // Sisi kiri atas
  path.lineTo(left, top + cornerRadius);

  path.quadraticBezierTo(
    left,
    top,
    left + cornerRadius,
    top,
  );

  path.close();

  return path;
}

// ======================================================
// GARIS PUTUS-PUTUS
// ======================================================

class _TicketDivider extends StatelessWidget {
  const _TicketDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 26,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 18),
        child: Center(
          child: _DashedLine(),
        ),
      ),
    );
  }
}

// ======================================================
// DASHED LINE
// ======================================================

class _DashedLine extends StatelessWidget {
  const _DashedLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 8.0;
        const dashGap = 8.0;

        final count = (constraints.maxWidth /
                (dashWidth + dashGap))
            .floor()
            .clamp(1, 200);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (index) => Container(
              width: dashWidth,
              height: 1.5,
              color: AppColors.border,
            ),
          ),
        );
      },
    );
  }
}