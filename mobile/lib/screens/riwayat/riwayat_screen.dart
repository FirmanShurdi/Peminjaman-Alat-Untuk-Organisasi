import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../partials/flash_message.dart';

const _statusCfg = {
  'menunggu':   {'label': 'Menunggu',   'color': 0xFFF59E0B, 'bg': 0xFFFEF3C7},
  'disetujui':  {'label': 'Disetujui',  'color': 0xFF3B82F6, 'bg': 0xFFDBEAFE},
  'diambil':    {'label': 'Diambil',    'color': 0xFF8B5CF6, 'bg': 0xFFEDE9FE},
  'terlambat':  {'label': 'Terlambat',  'color': 0xFFEF4444, 'bg': 0xFFFEE2E2},
  'selesai':    {'label': 'Selesai',    'color': 0xFF10B981, 'bg': 0xFFD1FAE5},
  'ditolak':    {'label': 'Ditolak',    'color': 0xFF6B7280, 'bg': 0xFFF3F4F6},
  'dibatalkan': {'label': 'Dibatalkan', 'color': 0xFF6B7280, 'bg': 0xFFF3F4F6},
};

String _genCode(int id) => ((id * 2654435761) & 0xFFFFFFFF).toRadixString(16).substring(0, 6).toUpperCase().padLeft(6, '0');

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key});
  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  List<dynamic> _data = [];
  bool _loading = true;
  String _filter = 'semua';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/peminjaman/milik-saya', auth: true);
      final json = jsonDecode(res.body);
      setState(() {
        _data = json['data'] ?? [];
        _data.sort((a, b) => (b['id_peminjaman'] ?? 0).compareTo(a['id_peminjaman'] ?? 0));
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<dynamic> get _filtered => _filter == 'semua' ? _data : _data.where((p) => p['status'] == _filter).toList();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _fetch,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Riwayat Peminjaman', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Lacak status pengajuan Anda', style: TextStyle(color: AppConst.textSecondary, fontSize: 14)),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 38,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: ['semua', 'menunggu', 'disetujui', 'diambil', 'selesai', 'ditolak', 'dibatalkan'].map((s) {
                              final active = _filter == s;
                              final label = s == 'semua' ? 'Semua' : (_statusCfg[s]?['label'] as String? ?? s);
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(label, style: TextStyle(color: active ? Colors.white : AppConst.textSecondary, fontWeight: FontWeight.w600, fontSize: 12)),
                                  selected: active,
                                  selectedColor: AppConst.primary,
                                  backgroundColor: Colors.white,
                                  side: BorderSide(color: active ? AppConst.primary : AppConst.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  onSelected: (_) => setState(() => _filter = s),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _filtered.isEmpty
                    ? const SliverFillRemaining(child: Center(child: Text('Belum ada riwayat peminjaman.', style: TextStyle(color: AppConst.textSecondary))))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _itemCard(i),
                            childCount: _filtered.length,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _itemCard(int i) {
    final p = _filtered[i];
    final status = p['status'] ?? 'menunggu';
    final cfg = _statusCfg[status] ?? _statusCfg['menunggu']!;
    final fmtD = DateFormat('dd MMM yyyy');

    final noPesanan = p['no_pesanan'];
    final isCart = noPesanan != null && _filtered.where((x) => x['no_pesanan'] == noPesanan).length > 1;
    final jumlah = p['jumlah'] ?? 1;

    bool isFirst = true;
    bool isLast = true;
    if (isCart) {
      isFirst = i == 0 || _filtered[i - 1]['no_pesanan'] != noPesanan;
      isLast = i == _filtered.length - 1 || _filtered[i + 1]['no_pesanan'] != noPesanan;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isCart)
            SizedBox(
              width: 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!isFirst)
                    Positioned(
                      top: 0,
                      bottom: null,
                      height: 48,
                      width: 2.5,
                      child: Container(color: AppConst.primary.withValues(alpha: 0.5)),
                    ),
                  if (!isLast)
                    Positioned(
                      top: 48,
                      bottom: 0,
                      width: 2.5,
                      child: Container(color: AppConst.primary.withValues(alpha: 0.5)),
                    ),
                  Positioned(
                    top: 48 - 4,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppConst.primary, width: 2.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: () => _showDetail(p),
              child: Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
                ),
                child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['nama_barang'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
                  const SizedBox(height: 4),
                  Text('${fmtD.format(DateTime.parse(p['tanggal_pinjam']).toLocal())} — ${fmtD.format(DateTime.parse(p['tanggal_kembali']).toLocal())}',
                      style: const TextStyle(fontSize: 12, color: AppConst.textSecondary)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(cfg['bg'] as int),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(cfg['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(cfg['color'] as int))),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppConst.bg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('$jumlah Unit', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppConst.textSecondary)),
                      ),
                      if (isCart) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.shopping_cart_outlined, size: 12, color: Colors.blue),
                              SizedBox(width: 4),
                              Text('Keranjang', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppConst.textSecondary),
          ],
        ),
      ),
    ),
  ),
  ],
  ),
  );
}

  // ─── Detail Bottom Sheet ─────────────────────────────────
  void _showDetail(dynamic p) {
    final status = p['status'] ?? 'menunggu';
    final cfg = _statusCfg[status] ?? _statusCfg['menunggu']!;
    final fmtD = DateFormat('dd MMM yyyy');
    final code = p['no_pesanan'] != null ? 'PMJ-${p['no_pesanan']}' : 'PMJ-${_genCode(p['id_peminjaman'])}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppConst.border, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Expanded(child: Text(p['nama_barang'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConst.textPrimary))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: Color(cfg['bg'] as int), borderRadius: BorderRadius.circular(6)),
                      child: Text(cfg['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(cfg['color'] as int))),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Catatan admin
                if (p['catatan_admin'] != null && p['catatan_admin'] != '') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('📝 Catatan Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(p['catatan_admin'], style: const TextStyle(fontSize: 13, color: AppConst.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Info rows
                _detailRow('Jumlah', '${p['jumlah']} unit'),
                _detailRow('Tgl Pinjam', fmtD.format(DateTime.parse(p['tanggal_pinjam']).toLocal())),
                _detailRow('Tgl Kembali', fmtD.format(DateTime.parse(p['tanggal_kembali']).toLocal())),
                if (p['catatan_user'] != null) _detailRow('Catatan', p['catatan_user']),
                const SizedBox(height: 16),

                // QR Code (untuk status menunggu/disetujui/diambil)
                if (status == 'menunggu' || status == 'disetujui' || status == 'diambil') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppConst.bg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConst.border),
                    ),
                    child: Column(
                      children: [
                        const Text('Kode Verifikasi', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Tunjukkan QR Code ini kepada admin', style: TextStyle(fontSize: 12, color: AppConst.textSecondary)),
                        const SizedBox(height: 16),
                        QrImageView(data: code, version: QrVersions.auto, size: 160),
                        const SizedBox(height: 12),
                        Text(code, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2, color: AppConst.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Tombol Batalkan
                if (status == 'menunggu') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelPeminjaman(p['id_peminjaman'], ctx),
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: const Text('Batalkan Pengajuan', style: TextStyle(fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppConst.error,
                        side: const BorderSide(color: AppConst.error),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelPeminjaman(int id, BuildContext ctx) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin membatalkan pengajuan ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Tidak')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Ya, Batalkan', style: TextStyle(color: AppConst.error))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final res = await ApiService.patch('/peminjaman/$id/batal', {}, auth: true);
      final data = jsonDecode(res.body);
      if (res.statusCode < 300) {
        if (ctx.mounted) Navigator.pop(ctx);
        if (!mounted) return;
        FlashMessage.show(context, data['message'] ?? 'Berhasil dibatalkan.', isSuccess: true);
        _fetch();
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      if (!mounted) return;
      FlashMessage.show(context, e.toString().replaceAll('Exception: ', ''), isSuccess: false);
    }
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppConst.textSecondary))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConst.textPrimary))),
        ],
      ),
    );
  }
}
