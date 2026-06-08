import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../partials/flash_message.dart';

class BookScreen extends StatefulWidget {
  const BookScreen({super.key});

  @override
  State<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends State<BookScreen> {
  Map<String, dynamic> _barang = {};
  List<dynamic> _bookedDates = [];
  bool isCart = false;
  List<dynamic> cartItems = [];
  
  DateTime focusedDay = DateTime.now();
  DateTime? tPinjam;
  DateTime? tKembali;
  int jumlah = 1;
  final catatanCtrl = TextEditingController();
  XFile? fileKtm;
  XFile? fileWajah;
  XFile? fileSurat;
  bool submitting = false;
  late Set<String> bookedSet;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      isCart = args['isCart'] ?? false;
      if (isCart) {
        cartItems = args['cartItems'] ?? [];
      } else {
        _barang = args['barang'] ?? {};
        jumlah = args['jumlah'] ?? 1;
      }
      _bookedDates = args['bookedDates'] ?? [];
      
      bookedSet = <String>{};
      for (final bd in _bookedDates) {
        try {
          final s = DateTime.parse(bd['tanggal_pinjam']);
          final e = DateTime.parse(bd['tanggal_kembali']);
          for (var dt = s; dt.isBefore(e.add(const Duration(days: 1))); dt = dt.add(const Duration(days: 1))) {
            bookedSet.add(DateFormat('yyyy-MM-dd').format(dt));
          }
        } catch (_) {}
      }
    }
  }

  void _showImageSourceSheet(bool isKtm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(isKtm ? 'Pilih Bukti KTM' : 'Pilih Foto Wajah', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppConst.primary),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera, isKtm);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppConst.primary),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery, isKtm);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, bool isKtm) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: source, imageQuality: 80);
    if (file != null) {
      setState(() {
        if (isKtm) {
          fileKtm = file;
        } else {
          fileWajah = file;
        }
      });
    }
  }

  Future<void> _pickDoc() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png', 'jpeg'],
    );
    if (result != null && result.files.single.path != null) {
      setState(() {
        fileSurat = XFile(result.files.single.path!);
      });
    }
  }

  Future<void> submit() async {
    if (tPinjam == null || tKembali == null) {
      FlashMessage.show(context, 'Pilih tanggal pinjam dan kembali (range).', isSuccess: false);
      return;
    }
    if (catatanCtrl.text.trim().isEmpty) {
      FlashMessage.show(context, 'Catatan wajib diisi.', isSuccess: false);
      return;
    }
    if (fileKtm == null || fileWajah == null || fileSurat == null) {
      FlashMessage.show(context, 'KTM, Foto Wajah, dan Surat Permohonan wajib diunggah.', isSuccess: false);
      return;
    }

    setState(() => submitting = true);
    try {
      final streamed = await ApiService.postMultipart(
        '/peminjaman',
        fields: {
          if (isCart) 'cart_items': jsonEncode(cartItems),
          if (!isCart) 'id_barang': '${_barang['id_barang']}',
          if (!isCart) 'jumlah': '$jumlah',
          'tanggal_pinjam': DateFormat('yyyy-MM-dd').format(tPinjam!),
          'tanggal_kembali': DateFormat('yyyy-MM-dd').format(tKembali!),
          'catatan_user': catatanCtrl.text.trim(),
          'source': 'mobile',
        },
        files: {
          'bukti_ktm': fileKtm!.path,
          'bukti_wajah': fileWajah!.path,
          'surat_permohonan': fileSurat!.path,
        },
        auth: true,
      );
      final res = await streamed.stream.bytesToString();
      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res);
      } catch (e) {
        throw Exception('Server mengembalikan respons tidak valid (kemungkinan error HTML dari server lama). Respons: ${res.length > 50 ? '${res.substring(0, 50)}...' : res}');
      }
      
      if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
        if (!mounted) return;
        Navigator.pop(context, true);
        FlashMessage.show(context, data['message'] ?? 'Pengajuan berhasil!', isSuccess: true);
      } else {
        throw Exception(data['message'] ?? 'Gagal mengajukan.');
      }
    } catch (e) {
      if (!mounted) return;
      FlashMessage.show(context, e.toString().replaceAll('Exception: ', ''), isSuccess: false);
    } finally {
      if (mounted) {
        setState(() => submitting = false);
      }
    }
  }

  Widget _buildFilePreview(String label, XFile? file, VoidCallback onPick, VoidCallback onRemove, {bool isDoc = false}) {
    if (file == null) {
      return GestureDetector(
        onTap: onPick,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: AppConst.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppConst.border, style: BorderStyle.solid),
          ),
          child: Row(
            children: [
              const Icon(Icons.upload_file, color: AppConst.textSecondary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: AppConst.textSecondary), overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      );
    }

    final isImage = file.path.toLowerCase().endsWith('.png') || file.path.toLowerCase().endsWith('.jpg') || file.path.toLowerCase().endsWith('.jpeg');

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppConst.success),
        boxShadow: [BoxShadow(color: AppConst.success.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          // Preview Thumbnail
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppConst.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.hardEdge,
            child: isImage
                ? Image.file(File(file.path), fit: BoxFit.cover)
                : const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 30),
          ),
          const SizedBox(width: 12),
          // File Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppConst.success, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(file.name, style: const TextStyle(fontSize: 13, color: AppConst.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Actions
          IconButton(
            icon: const Icon(Icons.visibility, color: AppConst.primary),
            tooltip: 'Lihat Dokumen',
            onPressed: () => OpenFilex.open(file.path),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: AppConst.error),
            tooltip: 'Hapus Dokumen',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final maxStok = _barang['stok'] ?? 1;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: AppBar(
        title: const Text('Pengajuan Peminjaman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConst.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Barang
            if (isCart)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartItems.length,
                separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                itemBuilder: (ctx, i) {
                  final item = cartItems[i];
                  final qty = item['jumlah'] ?? 1;
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConst.border),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                            color: AppConst.bg,
                            borderRadius: BorderRadius.circular(12),
                            image: (item['gambar'] != null && item['gambar'] != '')
                                ? DecorationImage(
                                    image: NetworkImage('${AppConst.imageBaseUrl}/barang/${item['gambar']}'),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (item['gambar'] == null || item['gambar'] == '')
                              ? const Icon(Icons.inventory_2_outlined, color: AppConst.textSecondary)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['nama_barang'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppConst.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('Jumlah Pinjam: $qty Unit', style: const TextStyle(fontSize: 13, color: AppConst.primary, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppConst.border),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppConst.bg,
                        borderRadius: BorderRadius.circular(12),
                        image: (_barang['gambar'] != null && _barang['gambar'] != '')
                            ? DecorationImage(
                                image: NetworkImage('${AppConst.imageBaseUrl}/barang/${_barang['gambar']}'),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: (_barang['gambar'] == null || _barang['gambar'] == '')
                          ? const Icon(Icons.inventory_2_outlined, color: AppConst.textSecondary)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_barang['nama_barang'] ?? '', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppConst.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('Stok Tersedia: $maxStok', style: const TextStyle(fontSize: 13, color: AppConst.primary, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            const SizedBox(height: 24),

            const Text('Pilih Tanggal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
            const SizedBox(height: 12),
            // Calendar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppConst.border),
              ),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: focusedDay,
                rangeStartDay: tPinjam,
                rangeEndDay: tKembali,
                rangeSelectionMode: RangeSelectionMode.enforced,
                availableCalendarFormats: const {CalendarFormat.month: 'Month'},
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                calendarStyle: const CalendarStyle(
                  rangeHighlightColor: Color(0xFFDBEAFE),
                  rangeStartDecoration: BoxDecoration(color: AppConst.primary, shape: BoxShape.circle),
                  rangeEndDecoration: BoxDecoration(color: AppConst.primary, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: Color(0x663B82F6), shape: BoxShape.circle),
                  holidayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                  holidayTextStyle: TextStyle(color: Colors.white),
                ),
                holidayPredicate: (day) {
                  return bookedSet.contains(DateFormat('yyyy-MM-dd').format(day));
                },
                enabledDayPredicate: (day) {
                  return !day.isBefore(DateTime(now.year, now.month, now.day));
                },
                onRangeSelected: (start, end, fDay) {
                  setState(() {
                    tPinjam = start;
                    tKembali = end;
                    focusedDay = fDay;
                  });
                },
                onPageChanged: (fDay) {
                  focusedDay = fDay;
                },
              ),
            ),
            const SizedBox(height: 16),

            // Ringkasan Tanggal
            if (tPinjam != null || tKembali != null)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(color: AppConst.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Mulai Pinjam', style: TextStyle(fontSize: 12, color: AppConst.primary)),
                        Text(tPinjam != null ? fmt.format(tPinjam!) : '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConst.primaryDark)),
                      ],
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: AppConst.primary, size: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Pengembalian', style: TextStyle(fontSize: 12, color: AppConst.primary)),
                        Text(tKembali != null ? fmt.format(tKembali!) : '-', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConst.primaryDark)),
                      ],
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Jumlah
            if (!isCart) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumlah Unit:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: jumlah > 1 ? () => setState(() => jumlah--) : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border.all(color: jumlah > 1 ? AppConst.primary : AppConst.border), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.remove, color: jumlah > 1 ? AppConst.primary : AppConst.textSecondary, size: 20),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('$jumlah', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      GestureDetector(
                        onTap: jumlah < maxStok ? () => setState(() => jumlah++) : null,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(border: Border.all(color: jumlah < maxStok ? AppConst.primary : AppConst.border), borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.add, color: jumlah < maxStok ? AppConst.primary : AppConst.textSecondary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Catatan
            const Text('Catatan / Keperluan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
            const SizedBox(height: 8),
            TextField(
              controller: catatanCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Jelaskan tujuan peminjaman...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConst.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppConst.border)),
              ),
            ),
            const SizedBox(height: 24),

            // File uploads
            const Text('Dokumen Persyaratan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
            const SizedBox(height: 8),
            _buildFilePreview('📄 KTM', fileKtm, () => _showImageSourceSheet(true), () => setState(() => fileKtm = null)),
            const SizedBox(height: 10),
            _buildFilePreview('📸 Foto Wajah', fileWajah, () => _showImageSourceSheet(false), () => setState(() => fileWajah = null)),
            const SizedBox(height: 10),
            _buildFilePreview('📝 Surat Permohonan (PDF/Img)', fileSurat, _pickDoc, () => setState(() => fileSurat = null), isDoc: true),
            const SizedBox(height: 32),

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
  }
}
