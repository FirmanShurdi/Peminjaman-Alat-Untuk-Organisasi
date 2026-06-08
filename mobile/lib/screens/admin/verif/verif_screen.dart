import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../partials/flash_message.dart';
import '../../../partials/admin/navbar.dart';
import '../../../partials/admin/sidebar.dart';

class AdminVerifScreen extends StatefulWidget {
  const AdminVerifScreen({super.key});

  @override
  State<AdminVerifScreen> createState() => _AdminVerifScreenState();
}

class _AdminVerifScreenState extends State<AdminVerifScreen> {
  final TextEditingController _kodeController = TextEditingController();
  bool _loading = false;
  String _error = '';
  
  List<dynamic> _dataItems = [];
  Set<String> _checkedItems = {};
  
  File? _fileBukti;
  final TextEditingController _catatanController = TextEditingController();

  // Membuka Scanner
  Future<void> _openScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerPage()),
    );
    if (result != null && result.isNotEmpty) {
      _kodeController.text = result;
      _handleSearch();
    }
  }

  // Proses Pencarian Data
  Future<void> _handleSearch() async {
    final kode = _kodeController.text.trim().toUpperCase().replaceAll('PMJ-', '');
    if (kode.isEmpty) {
      setState(() => _error = 'Masukkan kode verifikasi.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
      _dataItems = [];
      _checkedItems.clear();
      _fileBukti = null;
      _catatanController.clear();
    });

    try {
      final res = await ApiService.get('/api/peminjaman', auth: true);
      final json = jsonDecode(res.body);
      
      if (json['status'] != 'success') throw Exception('Gagal memuat data.');

      final List<dynamic> allData = json['data'];
      
      final foundItems = allData.where((p) {
        final dbCode = (p['no_pesanan']?.toString() ?? p['id_peminjaman'].toString()).toUpperCase();
        return dbCode == kode || p['id_peminjaman'].toString() == kode;
      }).toList();

      if (foundItems.isEmpty) throw Exception('Kode peminjaman tidak ditemukan.');

      final processableItems = foundItems.where((p) => 
        ['menunggu', 'disetujui', 'diambil', 'terlambat'].contains(p['status'])
      ).toList();

      if (processableItems.isEmpty) {
        throw Exception('Semua barang dengan kode ini tidak dapat diproses (peminjaman telah selesai/ditolak).');
      }

      setState(() {
        _dataItems = processableItems;
        _checkedItems = Set.from(processableItems.map((p) => p['id_peminjaman'].toString()));
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  // Pick Image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 70);
    if (picked != null) {
      setState(() => _fileBukti = File(picked.path));
    }
  }

  // Submit Processing
  Future<void> _handleSubmit() async {
    bool needsBukti = false;
    for (var item in _dataItems) {
      final id = item['id_peminjaman'].toString();
      if (!_checkedItems.contains(id)) continue;
      
      final status = item['status'];
      final nextStatus = status == 'menunggu' ? 'disetujui' : (status == 'disetujui' ? 'diambil' : 'selesai');
      if (nextStatus == 'diambil' || nextStatus == 'selesai') {
        needsBukti = true;
        break;
      }
    }

    if (needsBukti && _fileBukti == null) {
      setState(() => _error = 'Foto bukti serah/terima wajib diunggah.');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    int processedCount = 0;
    try {
      for (var item in _dataItems) {
        final id = item['id_peminjaman'].toString();
        final isChecked = _checkedItems.contains(id);
        
        if (!isChecked && item['status'] != 'menunggu') continue;

        String nextStatus;
        if (!isChecked) {
          nextStatus = 'ditolak';
        } else {
          if (item['status'] == 'menunggu') {
            nextStatus = 'disetujui';
          } else if (item['status'] == 'disetujui') {
            nextStatus = 'diambil';
          } else {
            nextStatus = 'selesai';
          }
        }

        final Map<String, String> fields = {
          'status': nextStatus,
          'source': 'mobile',
        };
        if (_catatanController.text.trim().isNotEmpty) {
          fields['catatan_admin'] = _catatanController.text.trim();
        }

        final Map<String, String> files = {};
        if (_fileBukti != null && (nextStatus == 'diambil' || nextStatus == 'selesai')) {
          files['bukti'] = _fileBukti!.path;
        }

        final res = await ApiService.sendMultipart(
          '/api/peminjaman/$id/status',
          fields: fields,
          files: files.isNotEmpty ? files : null,
          auth: true,
        );

        if (res.statusCode == 200) {
          processedCount++;
        }
      }

      if (mounted) {
        FlashMessage.show(context, 'Berhasil memproses $processedCount barang.', isSuccess: true);
        setState(() {
          _dataItems = [];
          _kodeController.clear();
          _fileBukti = null;
        });
      }
    } catch (e) {
      setState(() => _error = 'Gagal memproses data: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: const AdminNavbar(title: 'Verifikasi Peminjaman'),
      drawer: const AdminSidebar(activeRoute: 'Verifikasi QR'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Box
            Container(
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
                  const Text('Pencarian Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _kodeController,
                          decoration: InputDecoration(
                            hintText: 'PMJ-XXXXXX',
                            filled: true,
                            fillColor: AppConst.bg,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _openScanner,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppConst.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.qr_code_scanner, color: AppConst.primary),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _handleSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Cari Data', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),

            if (_error.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                child: Text(_error, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
              ),

            if (_dataItems.isNotEmpty)
              _buildDataResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildDataResult() {
    final firstItem = _dataItems[0];
    final kode = firstItem['no_pesanan'] ?? firstItem['id_peminjaman'];

    return Container(
      margin: const EdgeInsets.only(top: 24),
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
          const Text('Hasil Verifikasi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(height: 24),
          _infoRow('Kode', 'PMJ-$kode'),
          _infoRow('Peminjam', firstItem['nama_user']),
          const SizedBox(height: 16),
          
          const Text('Daftar Barang (Centang untuk memproses)', style: TextStyle(fontSize: 13, color: AppConst.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          
          ..._dataItems.map((item) {
            final id = item['id_peminjaman'].toString();
            final isChecked = _checkedItems.contains(id);
            
            String textStatus;
            if (isChecked) {
              if (item['status'] == 'menunggu') {
                textStatus = 'Disetujui';
              } else if (item['status'] == 'disetujui') {
                textStatus = 'Diambil';
              } else {
                textStatus = 'Selesai';
              }
            } else {
              if (item['status'] == 'menunggu') {
                textStatus = 'Ditolak';
              } else {
                textStatus = 'Dilewati (Tetap)';
              }
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isChecked ? Colors.blue.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isChecked ? Colors.blue.shade200 : Colors.red.shade200),
              ),
              child: CheckboxListTile(
                value: isChecked,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      _checkedItems.add(id);
                    } else {
                      _checkedItems.remove(id);
                    }
                  });
                },
                title: Text('${item['nama_barang']} (${item['jumlah']} unit)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text('Status akan menjadi: $textStatus', style: TextStyle(color: isChecked ? AppConst.primary : Colors.red, fontSize: 12)),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                dense: true,
              ),
            );
          }),

          const SizedBox(height: 16),
          // Jika ada yang butuh bukti
          if (_dataItems.any((item) => _checkedItems.contains(item['id_peminjaman'].toString()) && item['status'] != 'menunggu'))
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Unggah Foto Bukti (Wajib)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (_fileBukti == null)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt, size: 18),
                          label: const Text('Kamera'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library, size: 18),
                          label: const Text('Galeri'),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(_fileBukti!, width: 60, height: 60, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(_fileBukti!.path.split('/').last, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() => _fileBukti = null),
                      )
                    ],
                  )
              ],
            ),

          const SizedBox(height: 16),
          const Text('Catatan Admin (Opsional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Tambahkan catatan jika diperlukan...',
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
              onPressed: _loading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConst.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Proses Verifikasi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppConst.textSecondary, fontSize: 13))),
          const Text(': ', style: TextStyle(color: AppConst.textSecondary, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
        ],
      ),
    );
  }
}

// Scanner Page
class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
            final code = barcodes.first.rawValue!;
            controller.stop();
            Navigator.pop(context, code);
          }
        },
      ),
    );
  }
}
