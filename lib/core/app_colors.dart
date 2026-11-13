import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF43DC5E);
  static const Color border = Color(0xFFD9D9D9);
  static const Color hint = Color(0xFFBDBDBD);
  static const Color subtitle = Color(0xFF8A8A8A);
  static const Color text = Color(0xFF000000);

  // ---- Tambahan yang dibutuhkan oleh ProductPage & ProductCard ----
  static const Color green = Color(0xFF43DC5E);         // Alias/sama dengan primary
  static const Color muted = Color(0xFF8A8A8A);         // Bisa disamakan dengan subtitle atau hint
  static const Color avatarBorder = Color(0xFFF0F0F0);  // Warna latar/border placeholder
  static const Color textDark = Color(0xFF1E1E1E);      // Warna teks gelap utama

  // ---- Ditambahkan untuk halaman Home ----
  static const Color primaryDark = Color(0xFF38B54A);  
  static const Color primaryLight = Color(0xFFDDFCE3); 
  static const Color surfaceTint = Color(0xFFEFF7F1);  
  static const Color divider = Color(0xFFD5E3D9);      
  static const Color neutralLight = Color(0xFFF0F0F0); 

  // ---- Ditambahkan untuk Halaman Setoran & Status ----
  static const Color danger = Color(0xFFE53935);       
  static const Color surfaceGrey = Color(0xFFF5F6F8);   
  static const Color primarySoft = Color(0xFFF0FAF4);   
}