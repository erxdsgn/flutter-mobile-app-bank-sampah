import 'package:flutter/material.dart';

/// Halaman polos dengan judul di tengah. Dipakai sementara untuk tab yang
/// belum dibuat; ganti dengan halaman aslinya nanti.
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}