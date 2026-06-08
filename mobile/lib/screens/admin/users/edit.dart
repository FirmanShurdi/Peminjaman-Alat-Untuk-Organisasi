import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../partials/flash_message.dart';

class AdminUserEditScreen extends StatefulWidget {
  final String idUser;

  const AdminUserEditScreen({super.key, required this.idUser});

  @override
  State<AdminUserEditScreen> createState() => _AdminUserEditScreenState();
}

class _AdminUserEditScreenState extends State<AdminUserEditScreen> {
  final _formKey = GlobalKey<FormState>();
  
  bool _loading = true;
  bool _saving = false;

  // Form Fields
  String _nim = '';
  String _nama = '';
  String _email = '';
  String _password = '';
  String _role = 'anggota';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final res = await ApiService.get('/admin/users/${widget.idUser}', auth: true);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        final item = data['data'];
        _nim = item['nim']?.toString() ?? '';
        _nama = item['nama']?.toString() ?? '';
        _email = item['email']?.toString() ?? '';
        _role = item['role']?.toString().toLowerCase() ?? 'anggota';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _saving = true);

    try {
      final Map<String, dynamic> body = {
        'nim': _nim,
        'nama': _nama,
        'email': _email,
        'role': _role,
      };

      if (_password.isNotEmpty) {
        body['password'] = _password;
      }

      final res = await ApiService.put('/admin/users/${widget.idUser}', body, auth: true);
      final data = jsonDecode(res.body);

      if (res.statusCode == 200 || res.statusCode == 201) {
        if (mounted) {
          FlashMessage.show(context, data['message'] ?? 'User berhasil diubah', isSuccess: true);
          Navigator.pop(context, true); // refresh list
        }
      } else {
        if (mounted) {
          FlashMessage.show(context, data['message'] ?? 'Gagal mengubah user', isSuccess: false);
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
        title: const Text('Edit User'),
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
                    _buildLabel('NIM / NIK *'),
                    _buildTextField(
                      initialValue: _nim,
                      hint: 'Masukkan NIM / NIK',
                      onSaved: (val) => _nim = val ?? '',
                      validator: (val) => val == null || val.isEmpty ? 'NIM wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel('Nama Lengkap *'),
                    _buildTextField(
                      initialValue: _nama,
                      hint: 'Masukkan nama lengkap',
                      onSaved: (val) => _nama = val ?? '',
                      validator: (val) => val == null || val.isEmpty ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Email *'),
                    _buildTextField(
                      initialValue: _email,
                      hint: 'Contoh: budi@kampus.ac.id',
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (val) => _email = val ?? '',
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Email wajib diisi';
                        if (!val.endsWith('@kampus.ac.id')) return 'Email harus menggunakan domain @kampus.ac.id';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Password (Kosongkan jika tidak diubah)'),
                    _buildTextField(
                      initialValue: '',
                      hint: 'Masukkan password baru...',
                      obscureText: true,
                      onSaved: (val) => _password = val ?? '',
                      validator: (val) {
                        if (val != null && val.isNotEmpty && val.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    _buildLabel('Role *'),
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                      items: ['anggota', 'admin', 'superadmin'].map((String val) {
                        return DropdownMenuItem<String>(
                          value: val,
                          child: Text(val[0].toUpperCase() + val.substring(1)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() => _role = val ?? 'anggota');
                      },
                      onSaved: (val) => _role = val ?? 'anggota',
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
    TextInputType? keyboardType,
    bool obscureText = false,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      keyboardType: keyboardType,
      obscureText: obscureText,
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
}
