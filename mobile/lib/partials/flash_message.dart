import 'package:flutter/material.dart';

class FlashMessage {
  /// Menampilkan flash notification (Snackbar) melayang di dekat bagian atas layar.
  ///
  /// Untuk menurunkan posisi flash (lebih ke bawah), kecilkan angka pengurangannya.
  /// Contoh: `size.height - 180` akan berada LEBIH BAWAH daripada `size.height - 160`.
  static void show(BuildContext context, String message, {bool isSuccess = true}) {
    final color = isSuccess ? const Color.fromARGB(255, 37, 132, 215) : const Color(0xFFEF4444);
    final icon = isSuccess ? Icons.check_circle_outline_rounded : Icons.error_outline_rounded;

    // CARA KEBAWAHIN:
    // Ubah angka pengurang ini. Semakin besar angkanya, letak flash akan SEMAKIN KE BAWAH!
    // (Sebelumnya 160, sekarang saya ubah ke 180 agar sedikit lebih turun)
    final double bottomMargin = MediaQuery.of(context).size.height - 200;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.up,
        margin: EdgeInsets.only(
          bottom: bottomMargin,
          left: 16,
          right: 16,
        ),
        duration: const Duration(seconds: 2),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF1E293B),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
                child: const Icon(Icons.close_rounded, color: Color.fromARGB(255, 36, 120, 239), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
