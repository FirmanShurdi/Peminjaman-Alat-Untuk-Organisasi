import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../main.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});
  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  List<dynamic> _barangList = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resBarang = await ApiService.get('/api/barang');
      final barangData = jsonDecode(resBarang.body);
      setState(() {
        _barangList = (barangData['data'] as List?)?.take(4).toList() ?? [];
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return RefreshIndicator(
      onRefresh: _fetch,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 0),
              children: [
                _buildHeroSection(user),
                _buildCaraKerjaSection(user),
                _buildKatalogSection(),
                _buildLokasiSection(user),
              ],
            ),
    );
  }

  // ══════ SECTION 1 — HERO ══════
  Widget _buildHeroSection(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          Text('Halo, ${user?['nama'] ?? 'Pengguna'} 👋', style: const TextStyle(fontSize: 16, color: AppConst.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          // Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppConst.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
            child: const Text('Platform Manajemen Eksklusif', style: TextStyle(color: AppConst.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 16),
          // H1
          const Text('Infrastruktur\nInventaris\nProfesional', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, height: 1.1, color: AppConst.textPrimary)),
          const SizedBox(height: 14),
          const Text('Kelola dan optimalkan peminjaman alat organisasi Anda dengan sistem cerdas yang aman, cepat, dan transparan.', style: TextStyle(fontSize: 14, color: AppConst.textSecondary, height: 1.5)),
          const SizedBox(height: 28),
          
          // Features
          _heroFeature(Icons.security, 'Keamanan Data', 'Verifikasi multi-lapis'),
          _heroFeature(Icons.flash_on, 'Akses Instan', 'Persetujuan kilat'),
          _heroFeature(Icons.inventory_2, 'Katalog Sentral', '100+ alat tersedia'),
          _heroFeature(Icons.touch_app, 'Sistem Intuitif', 'Booking anti-ribet'),
          
          const SizedBox(height: 28),
          
          // Buttons
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => context.findAncestorStateOfType<HomeShellState>()?.switchTab(1),
              style: ElevatedButton.styleFrom(backgroundColor: AppConst.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0),
              child: const Text('Pinjam Sekarang', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.findAncestorStateOfType<HomeShellState>()?.switchTab(1),
              style: OutlinedButton.styleFrom(foregroundColor: AppConst.textPrimary, side: const BorderSide(color: AppConst.border, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Lihat Katalog', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroFeature(IconData icon, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppConst.bg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppConst.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppConst.textPrimary)),
              const SizedBox(height: 2),
              Text(sub, style: const TextStyle(fontSize: 13, color: AppConst.textSecondary)),
            ],
          )
        ],
      ),
    );
  }

  // ══════ SECTION 2 — CARA KERJA ══════
  Widget _buildCaraKerjaSection(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: AppConst.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppConst.border)),
            child: const Text('Cara Kerja', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConst.textSecondary)),
          ),
          const SizedBox(height: 14),
          const Text('Pinjam Alat dalam\n4 Langkah Mudah', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppConst.textPrimary, height: 1.2)),
          const SizedBox(height: 10),
          const Text('Proses sederhana untuk meminjam alat organisasi dari awal hingga selesai.', style: TextStyle(fontSize: 14, color: AppConst.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          
          _stepCard('1', Icons.search, 'Pilih Alat', 'Jelajahi katalog dan pilih alat yang kamu butuhkan untuk kegiatanmu.'),
          _stepCard('2', Icons.calendar_today, 'Pilih Tanggal', 'Tentukan tanggal pinjam dan kembali sesuai kebutuhan kegiatan.'),
          _stepCard('3', Icons.edit_document, 'Isi Data', 'Lengkapi data peminjam dan keperluan peminjaman dengan benar.'),
          _stepCard('4', Icons.check_circle_outline, 'Konfirmasi & Pinjam', 'Konfirmasi peminjaman, ambil alat, dan gunakan dengan bertanggung jawab.'),
          
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppConst.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Butuh Bantuan?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppConst.textPrimary)),
                const SizedBox(height: 6),
                const Text('Tim kami siap membantu proses peminjamanmu.', style: TextStyle(fontSize: 13, color: AppConst.textSecondary)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {}, // Trigger WA in real app
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Hubungi Kami', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConst.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _stepCard(String num, IconData icon, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppConst.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Text(num, style: const TextStyle(color: AppConst.primary, fontWeight: FontWeight.w900, fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: AppConst.textPrimary),
                    const SizedBox(width: 8),
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppConst.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(desc, style: const TextStyle(fontSize: 13, color: AppConst.textSecondary, height: 1.5)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ══════ SECTION 3 — KATALOG ══════
  Widget _buildKatalogSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: AppConst.bg, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppConst.border)),
            child: const Text('Koleksi Inventaris', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConst.textSecondary)),
          ),
          const SizedBox(height: 14),
          const Text('Alat Operasional\nUnggulan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppConst.textPrimary, height: 1.2)),
          const SizedBox(height: 10),
          const Text('Daftar inventaris premium dengan tingkat ketersediaan tinggi untuk mendukung kegiatan Anda.', style: TextStyle(fontSize: 14, color: AppConst.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          
          ..._barangList.map((b) => _buildKatalogCard(b)),
          
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.findAncestorStateOfType<HomeShellState>()?.switchTab(1),
              style: OutlinedButton.styleFrom(foregroundColor: AppConst.textPrimary, side: const BorderSide(color: AppConst.border, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Lihat Semua Katalog', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildKatalogCard(dynamic b) {
    final imgUrl = (b['gambar'] != null && b['gambar'] != '')
        ? '${AppConst.baseUrl}/barang/${b['gambar']}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppConst.border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 160,
              width: double.infinity,
              child: imgUrl != null
                  ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _placeholderImg())
                  : _placeholderImg(),
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(b['nama_kategori'] ?? 'Alat Umum', style: const TextStyle(fontSize: 12, color: AppConst.primary, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Premium', style: TextStyle(fontSize: 10, color: Color(0xFFD97706), fontWeight: FontWeight.w800)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(b['nama_barang'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppConst.textPrimary)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 18, color: AppConst.textSecondary),
                    const SizedBox(width: 8),
                    const Text('Sisa Stok: ', style: TextStyle(fontSize: 14, color: AppConst.textSecondary)),
                    Text('${b['stok']} Unit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 18, color: AppConst.textSecondary),
                    const SizedBox(width: 8),
                    Text(b['lokasi'] ?? 'Gudang Utama', style: const TextStyle(fontSize: 14, color: AppConst.textSecondary)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/detail', arguments: b['id_barang']),
                    style: ElevatedButton.styleFrom(backgroundColor: AppConst.bg, foregroundColor: AppConst.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: const Text('Lihat Detail & Pinjam', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _placeholderImg() => Container(
    color: AppConst.bg,
    child: const Center(child: Icon(Icons.inventory_2_outlined, color: AppConst.textSecondary, size: 40)),
  );

  // ══════ SECTION 4 — LOKASI ══════
  Widget _buildLokasiSection(Map<String, dynamic>? user) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 100),
      color: AppConst.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Kunjungi Pusat\nGudang Kami', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppConst.textPrimary, height: 1.2)),
          const SizedBox(height: 10),
          const Text('Pengambilan dan pengembalian barang dilakukan di gudang utama Politeknik Elektronika Negeri Surabaya.', style: TextStyle(fontSize: 14, color: AppConst.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppConst.border)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Jam Operasional', style: TextStyle(fontSize: 12, color: AppConst.textSecondary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Senin - Jumat, 08:00 - 16:00 WIB', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: AppConst.border),
                ),
                const Text('Titik Pengambilan / Pengembalian', style: TextStyle(fontSize: 12, color: AppConst.textSecondary, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Gudang Utama PENS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.support_agent, size: 20),
                    label: const Text('Hubungi Admin', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    style: OutlinedButton.styleFrom(foregroundColor: AppConst.textPrimary, side: const BorderSide(color: AppConst.border, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 40),
          Center(
            child: Text('© ${DateTime.now().year} PinjamIN — Sistem Peminjaman Alat', style: const TextStyle(fontSize: 12, color: AppConst.textSecondary)),
          )
        ],
      ),
    );
  }
}
