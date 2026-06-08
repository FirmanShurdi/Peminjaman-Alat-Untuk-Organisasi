import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../partials/flash_message.dart';

class AdminBarangEditScreen extends StatefulWidget {
  final String idBarang;

  const AdminBarangEditScreen({super.key, required this.idBarang});

  @override
  State<AdminBarangEditScreen> createState() => _AdminBarangEditScreenState();
}

class _AdminBarangEditScreenState extends State<AdminBarangEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _loading = true;
  bool _saving = false;

  List<dynamic> _kategoriList = [];

  // Form Fields
  String _namaBarang = '';
  String _deskripsi = '';
  String _idKategori = '';
  String _kondisi = 'baik';
  bool _isKondisiBaru = false;
  String _kondisiCustom = '';
  int _stok = 0;
  String _lokasi = '';
  String _existingGambar = '';

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch Kategori
      final resKat = await ApiService.get('/api/barang/kategori', auth: true);
      final dataKat = jsonDecode(resKat.body);
      if (dataKat['status'] == 'success') {
        _kategoriList = dataKat['data'];
      }

      // Fetch Barang details
      final res = await ApiService.get('/api/barang/${widget.idBarang}', auth: true);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        final item = data['data'];
        _namaBarang = item['nama_barang']?.toString() ?? '';
        _deskripsi = item['deskripsi']?.toString() ?? '';
        _idKategori = item['id_kategori']?.toString() ?? '';
        _kondisi = item['kondisi']?.toString() ?? 'baik';
        
        final List<String> standardOptions = ['baik', 'rusak', 'maintenance'];
        if (!standardOptions.contains(_kondisi.toLowerCase())) {
          _kondisiCustom = _kondisi;
          _kondisi = 'baru';
          _isKondisiBaru = true;
        }

        _stok = int.tryParse(item['stok']?.toString() ?? '0') ?? 0;
        _lokasi = item['lokasi']?.toString() ?? '';
        _existingGambar = item['gambar']?.toString() ?? '';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_idKategori.isEmpty) {
      FlashMessage.show(context, 'Kategori harus dipilih', isSuccess: false);
      return;
    }

    _formKey.currentState!.save();
    setState(() => _saving = true);

    try {
      final Map<String, String> fields = {
        'nama_barang': _namaBarang,
        'deskripsi': _deskripsi,
        'id_kategori': _idKategori,
        'kondisi': _kondisi,
        'stok': _stok.toString(),
        'lokasi': _lokasi,
      };

      if (_imageFile != null) {
        // Menggunakan multipart/form-data jika ada gambar baru
        final Map<String, String> files = {'gambar': _imageFile!.path};
        
        final streamedRes = await ApiService.sendMultipart(
          '/api/barang/${widget.idBarang}',
          method: 'PUT',
          fields: fields,
          files: files,
          auth: true,
        );

        final response = await streamedRes.stream.bytesToString();
        final data = jsonDecode(response);

        if (streamedRes.statusCode == 200 || streamedRes.statusCode == 201) {
          if (mounted) {
            FlashMessage.show(context, data['message'] ?? 'Data berhasil diubah', isSuccess: true);
            Navigator.pop(context, true); // true indicates refresh needed
          }
        } else {
          if (mounted) {
            FlashMessage.show(context, data['message'] ?? 'Gagal mengubah data', isSuccess: false);
          }
        }
      } else {
        // Menggunakan standard JSON PUT jika tidak ada gambar baru
        if (_existingGambar.isNotEmpty) {
          fields['gambar'] = _existingGambar;
        }
        
        final res = await ApiService.put(
          '/api/barang/${widget.idBarang}',
          fields,
          auth: true,
        );

        final data = jsonDecode(res.body);

        if (res.statusCode == 200 || res.statusCode == 201) {
          if (mounted) {
            FlashMessage.show(context, data['message'] ?? 'Data berhasil diubah', isSuccess: true);
            Navigator.pop(context, true); // true indicates refresh needed
          }
        } else {
          if (mounted) {
            FlashMessage.show(context, data['message'] ?? 'Gagal mengubah data', isSuccess: false);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        FlashMessage.show(context, 'Terjadi kesalahan jaringan.', isSuccess: false);
      }
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: AppBar(
        title: const Text('Edit Barang'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImagePicker(),
                    const SizedBox(height: 24),
                    _buildLabel('Nama Barang *'),
                    _buildTextField(
                      initialValue: _namaBarang,
                      hint: 'Contoh: Proyektor Epson',
                      onSaved: (val) => _namaBarang = val ?? '',
                      validator: (val) => val == null || val.isEmpty ? 'Nama barang wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Kategori *'),
                    _buildDropdownKategori(),
                    const SizedBox(height: 16),
                    _buildLabel('Deskripsi'),
                    _buildTextField(
                      initialValue: _deskripsi,
                      hint: 'Deskripsi singkat...',
                      maxLines: 3,
                      onSaved: (val) => _deskripsi = val ?? '',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Stok *'),
                              _buildTextField(
                                initialValue: _stok.toString(),
                                keyboardType: TextInputType.number,
                                onSaved: (val) => _stok = int.tryParse(val ?? '0') ?? 0,
                                validator: (val) => val == null || val.isEmpty ? 'Stok wajib diisi' : null,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Kondisi'),
                              _buildDropdownKondisi(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Lokasi Penyimpanan'),
                    _buildTextField(
                      initialValue: _lokasi,
                      hint: 'Contoh: Lemari A',
                      onSaved: (val) => _lokasi = val ?? '',
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConst.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, color: AppConst.textPrimary, fontSize: 14)),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: validator,
      onSaved: onSaved,
    );
  }

  Widget _buildDropdownKategori() {
    return DropdownButtonFormField<String>(
      initialValue: _idKategori.isNotEmpty ? _idKategori : null,
      hint: const Text('Pilih Kategori'),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      items: _kategoriList.map((kat) {
        return DropdownMenuItem<String>(
          value: kat['id_kategori'].toString(),
          child: Text(kat['nama_kategori'].toString()),
        );
      }).toList(),
      onChanged: (val) {
        setState(() => _idKategori = val ?? '');
      },
      validator: (val) => val == null || val.isEmpty ? 'Pilih kategori' : null,
    );
  }

  Widget _buildDropdownKondisi() {
    final List<String> options = ['baik', 'rusak', 'maintenance', 'baru'];
    String currentValue = _kondisi.toLowerCase();
    if (!options.contains(currentValue)) {
      currentValue = 'baik'; // fallback
      _kondisi = 'baik';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: currentValue,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
          items: options.map((k) {
            return DropdownMenuItem<String>(
              value: k,
              child: Text(k[0].toUpperCase() + k.substring(1)), // Capitalize first letter
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              _kondisi = val ?? 'baik';
              _isKondisiBaru = _kondisi == 'baru';
            });
          },
          onSaved: (val) {
            if (val != 'baru') _kondisi = val ?? 'baik';
          },
        ),
        if (_isKondisiBaru) ...[
          const SizedBox(height: 8),
          _buildTextField(
            initialValue: _kondisiCustom,
            hint: 'Masukkan kondisi baru...',
            onSaved: (val) {
              if (_isKondisiBaru) _kondisi = val ?? '';
            },
            validator: (val) => _isKondisiBaru && (val == null || val.isEmpty) ? 'Kondisi wajib diisi' : null,
          ),
        ],
      ],
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel('Foto Barang'),
        Center(
          child: Container(
            height: 180,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 2, style: BorderStyle.solid),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: _imageFile != null
                  ? Image.file(_imageFile!, fit: BoxFit.cover)
                  : (_existingGambar.isNotEmpty
                      ? Image.network('${AppConst.imageBaseUrl}/barang/$_existingGambar', fit: BoxFit.cover)
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Belum ada foto', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        )),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Ubah via Kamera'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConst.primary.withValues(alpha: 0.1),
                foregroundColor: AppConst.primary,
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined, size: 18),
              label: const Text('Pilih dari Galeri'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConst.primary.withValues(alpha: 0.1),
                foregroundColor: AppConst.primary,
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
