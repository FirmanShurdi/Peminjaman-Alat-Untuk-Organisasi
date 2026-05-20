import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  dynamic _barang;
  List<dynamic> _bookedDates = [];
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments;
    if (id != null && _barang == null) _fetch(id);
  }

  Future<void> _fetch(dynamic id) async {
    setState(() => _loading = true);
    try {
      final resB = await ApiService.get('/api/barang/$id');
      final resD = await ApiService.get('/api/barang/$id/booked-dates');
      final bData = jsonDecode(resB.body);
      final dData = jsonDecode(resD.body);
      setState(() {
        _barang = bData['data'];
        _bookedDates = dData['data'] ?? [];
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = (_barang != null && _barang['gambar'] != null && _barang['gambar'] != '')
        ? '${AppConst.baseUrl}/barang/${_barang['gambar']}'
        : null;

    return Scaffold(
      backgroundColor: AppConst.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _barang == null
              ? const Center(child: Text('Barang tidak ditemukan'))
              : CustomScrollView(
                  slivers: [
                    // Image header
                    SliverAppBar(
                      expandedHeight: 260,
                      pinned: true,
                      backgroundColor: AppConst.primary,
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: imgUrl != null
                            ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => Container(color: AppConst.primary))
                            : Container(
                                color: AppConst.primary,
                                child: const Center(child: Icon(Icons.inventory_2_rounded, color: Colors.white54, size: 64)),
                              ),
                      ),
                    ),

                    // Content
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Kategori badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConst.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(_barang['nama_kategori'] ?? 'Umum', style: const TextStyle(color: AppConst.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(height: 10),
                            Text(_barang['nama_barang'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                            const SizedBox(height: 16),

                            // Info cards
                            _infoRow(Icons.inventory_2_outlined, 'Stok Tersedia', '${_barang['stok']} unit'),
                            _infoRow(Icons.location_on_outlined, 'Lokasi', _barang['lokasi'] ?? '-'),
                            _infoRow(Icons.build_outlined, 'Kondisi', _barang['kondisi'] ?? '-'),
                            const SizedBox(height: 24),

                            // Deskripsi
                            if (_barang['deskripsi'] != null && _barang['deskripsi'] != '') ...[
                              const Text('Deskripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
                              const SizedBox(height: 8),
                              Text(_barang['deskripsi'], style: const TextStyle(fontSize: 14, color: AppConst.textSecondary, height: 1.5)),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _barang != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: (_barang['stok'] ?? 0) > 0 ? () => _showBookingSheet() : null,
                    icon: const Icon(Icons.send_rounded, size: 20),
                    label: Text((_barang['stok'] ?? 0) > 0 ? 'Ajukan Peminjaman' : 'Stok Habis', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConst.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppConst.border,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppConst.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppConst.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppConst.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConst.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Booking Bottom Sheet ────────────────────────────────
  void _showBookingSheet() {
    DateTime? tPinjam;
    DateTime? tKembali;
    int jumlah = 1;
    final catatanCtrl = TextEditingController();
    XFile? fileKtm;
    XFile? fileWajah;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setBS) {
          Future<void> pickDate(bool isStart) async {
            final now = DateTime.now();
            final d = await showDatePicker(
              context: ctx,
              initialDate: now.add(const Duration(days: 1)),
              firstDate: now,
              lastDate: now.add(const Duration(days: 365)),
            );
            if (d == null) return;

            // cek booked
            final bookedSet = <String>{};
            for (final bd in _bookedDates) {
              final s = DateTime.parse(bd['tanggal_pinjam']);
              final e = DateTime.parse(bd['tanggal_kembali']);
              for (var dt = s; dt.isBefore(e); dt = dt.add(const Duration(days: 1))) {
                bookedSet.add(DateFormat('yyyy-MM-dd').format(dt));
              }
            }
            if (bookedSet.contains(DateFormat('yyyy-MM-dd').format(d))) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Tanggal ini sudah dipesan.'), backgroundColor: AppConst.error));
              return;
            }

            setBS(() {
              if (isStart) {
                tPinjam = d;
                if (tKembali != null && tKembali!.isBefore(d)) tKembali = null;
              } else {
                tKembali = d;
              }
            });
          }

          Future<void> pickFile(bool isKtm) async {
            final picker = ImagePicker();
            final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
            if (file != null) setBS(() => isKtm ? fileKtm = file : fileWajah = file);
          }

          Future<void> submit() async {
            if (tPinjam == null || tKembali == null) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pilih tanggal pinjam dan kembali.'), backgroundColor: AppConst.error));
              return;
            }
            if (catatanCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Catatan wajib diisi.'), backgroundColor: AppConst.error));
              return;
            }
            if (fileKtm == null || fileWajah == null) {
              ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('KTM dan Foto wajah wajib diunggah.'), backgroundColor: AppConst.error));
              return;
            }

            setBS(() => submitting = true);
            try {
              final streamed = await ApiService.postMultipart(
                '/peminjaman',
                fields: {
                  'id_barang': '${_barang['id_barang']}',
                  'jumlah': '$jumlah',
                  'tanggal_pinjam': DateFormat('yyyy-MM-dd').format(tPinjam!),
                  'tanggal_kembali': DateFormat('yyyy-MM-dd').format(tKembali!),
                  'catatan_user': catatanCtrl.text.trim(),
                },
                files: {
                  'bukti_ktm': fileKtm!.path,
                  'bukti_wajah': fileWajah!.path,
                },
                auth: true,
              );
              final res = await streamed.stream.bytesToString();
              final data = jsonDecode(res);
              if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
                if (ctx.mounted) Navigator.pop(ctx);
                if (!ctx.mounted) return;
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text(data['message'] ?? 'Pengajuan berhasil!'),
                  backgroundColor: AppConst.success,
                ));
              } else {
                throw Exception(data['message'] ?? 'Gagal mengajukan.');
              }
            } catch (e) {
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: AppConst.error));
            }
            setBS(() => submitting = false);
          }

          final fmt = DateFormat('dd MMM yyyy');

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.85),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppConst.border, borderRadius: BorderRadius.circular(2)))),
                  const SizedBox(height: 16),
                  const Text('Ajukan Peminjaman', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                  const SizedBox(height: 20),

                  // Date pickers
                  Row(
                    children: [
                      Expanded(child: _dateBtn('Tgl Pinjam', tPinjam != null ? fmt.format(tPinjam!) : 'Pilih', () => pickDate(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _dateBtn('Tgl Kembali', tKembali != null ? fmt.format(tKembali!) : 'Pilih', () => pickDate(false))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Jumlah
                  Row(
                    children: [
                      const Text('Jumlah:', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: jumlah > 1 ? () => setBS(() => jumlah--) : null),
                      Text('$jumlah', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(icon: const Icon(Icons.add_circle_outline, color: AppConst.primary), onPressed: () => setBS(() => jumlah++)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Catatan
                  TextField(
                    controller: catatanCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Catatan / Keperluan',
                      filled: true,
                      fillColor: AppConst.bg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // File uploads
                  _uploadBtn('📄 KTM', fileKtm?.name, () => pickFile(true)),
                  const SizedBox(height: 10),
                  _uploadBtn('📸 Foto Wajah', fileWajah?.name, () => pickFile(false)),
                  const SizedBox(height: 24),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: submitting ? null : submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: submitting
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                          : const Text('Kirim Pengajuan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _dateBtn(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(color: AppConst.bg, borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppConst.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConst.textPrimary)),
          ],
        ),
      ),
    );
  }

  Widget _uploadBtn(String label, String? filename, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppConst.bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: filename != null ? AppConst.success : AppConst.border, style: BorderStyle.solid),
        ),
        child: Row(
          children: [
            Icon(filename != null ? Icons.check_circle : Icons.upload_file, color: filename != null ? AppConst.success : AppConst.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text(filename ?? label, style: TextStyle(fontSize: 14, color: filename != null ? AppConst.textPrimary : AppConst.textSecondary), overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
    );
  }
}
