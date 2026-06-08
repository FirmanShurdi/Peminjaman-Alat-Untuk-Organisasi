import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../partials/flash_message.dart';

class AdminPeminjamanEditScreen extends StatefulWidget {
  final String idPeminjaman;
  const AdminPeminjamanEditScreen({super.key, required this.idPeminjaman});

  @override
  State<AdminPeminjamanEditScreen> createState() => _AdminPeminjamanEditScreenState();
}

class _AdminPeminjamanEditScreenState extends State<AdminPeminjamanEditScreen> {
  Map<String, dynamic>? _peminjaman;
  bool _loading = true;
  bool _saving = false;

  String _status = 'menunggu';
  final _catatanController = TextEditingController();

  final List<String> _statusOptions = [
    'menunggu', 'disetujui', 'diambil', 'terlambat', 'selesai', 'ditolak', 'dibatalkan'
  ];

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final res = await ApiService.get('/api/peminjaman/${widget.idPeminjaman}', auth: true);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() {
          _peminjaman = data['data'];
          _status = (_peminjaman?['status'] ?? 'menunggu').toString();
          // Remove "selesai_terlambat" if returned by DB since it's a virtual status
          if (_status == 'selesai_terlambat') _status = 'selesai';
          
          if (!_statusOptions.contains(_status)) {
            _status = 'menunggu';
          }
          _catatanController.text = (_peminjaman?['catatan_admin'] ?? '').toString();
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final streamedResponse = await ApiService.sendMultipart(
        '/api/peminjaman/${widget.idPeminjaman}/status',
        fields: {
          'status': _status,
          'catatan_admin': _catatanController.text,
          'source': 'mobile',
        },
        auth: true,
      );
      
      final res = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(res.body);

      if (mounted) {
        if (data['status'] == 'success') {
          FlashMessage.show(context, 'Status berhasil diperbarui', isSuccess: true);
          Navigator.pop(context, true); // true to indicate refresh needed
        } else {
          FlashMessage.show(context, data['message'] ?? 'Gagal memperbarui status', isSuccess: false);
        }
      }
    } catch (_) {
      if (mounted) FlashMessage.show(context, 'Terjadi kesalahan jaringan', isSuccess: false);
    }
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: AppBar(
        title: const Text('Edit Peminjaman', style: TextStyle(color: AppConst.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: AppConst.textPrimary),
        elevation: 1,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _peminjaman == null
              ? const Center(child: Text('Data tidak ditemukan'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoCard(),
                      const SizedBox(height: 20),
                      _buildEditForm(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoCard() {
    final noPesanan = (_peminjaman!['no_pesanan'] ?? '-').toString();
    final namaBarang = (_peminjaman!['nama_barang'] ?? '-').toString();
    final namaUser = (_peminjaman!['nama_user'] ?? '-').toString();
    final tglPinjam = _peminjaman!['tanggal_pinjam'] ?? '-';
    final tglKembali = _peminjaman!['tanggal_kembali'] ?? '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informasi Peminjaman', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _buildInfoRow('ID', widget.idPeminjaman),
          _buildInfoRow('No Pesanan', noPesanan),
          _buildInfoRow('Peminjam', namaUser),
          _buildInfoRow('Barang', namaBarang),
          _buildInfoRow('Tgl Pinjam', tglPinjam.toString().split('T')[0]),
          _buildInfoRow('Tgl Kembali', tglKembali.toString().split('T')[0]),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppConst.textSecondary, fontSize: 13))),
          const Text(': ', style: TextStyle(color: AppConst.textSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Perbarui Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          const Text('Status Peminjaman', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConst.textSecondary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppConst.bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _status,
                isExpanded: true,
                items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _status = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Catatan Admin', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppConst.textSecondary)),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tulis pesan atau catatan untuk peminjam...',
              filled: true,
              fillColor: AppConst.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConst.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _saving 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
    );
  }
}
