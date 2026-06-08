import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../partials/admin/navbar.dart';
import '../../../partials/admin/sidebar.dart';
import '../../../partials/flash_message.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  List<dynamic> _allUsers = [];
  bool _loading = true;

  String _searchQuery = '';
  String _filterRole = 'Semua';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/admin/users', auth: true);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        final List<dynamic> listData = data['data'];
        listData.sort((a, b) {
          final idA = int.tryParse(a['id_user']?.toString() ?? '0') ?? 0;
          final idB = int.tryParse(b['id_user']?.toString() ?? '0') ?? 0;
          return idB.compareTo(idA); // Descending (terbaru di atas)
        });
        setState(() => _allUsers = listData);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _deleteUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus User'),
        content: const Text('Apakah Anda yakin ingin menghapus user ini? Data yang sudah dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.delete('/admin/users/$id', auth: true);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (mounted) FlashMessage.show(context, 'User berhasil dihapus', isSuccess: true);
        _fetch();
      } else {
        if (mounted) FlashMessage.show(context, data['message'] ?? 'Gagal menghapus user', isSuccess: false);
      }
    } catch (e) {
      if (mounted) FlashMessage.show(context, 'Terjadi kesalahan jaringan.', isSuccess: false);
    }
  }

  List<dynamic> get _filteredUsers {
    return _allUsers.where((u) {
      final n = u['nama']?.toString().toLowerCase() ?? '';
      final r = u['role']?.toString().toLowerCase() ?? '';
      
      final matchQuery = n.contains(_searchQuery.toLowerCase());
      final matchRole = _filterRole == 'Semua' || r == _filterRole.toLowerCase();

      return matchQuery && matchRole;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: const AdminNavbar(title: 'Manajemen User'),
      drawer: const AdminSidebar(activeRoute: '/admin_users'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelola User',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConst.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manajemen data anggota dan admin.',
                    style: TextStyle(fontSize: 14, color: AppConst.textSecondary),
                  ),
                  const SizedBox(height: 20),

                  // Tambah User Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final refresh = await Navigator.pushNamed(context, '/admin_users_tambah');
                        if (refresh == true) _fetch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.person_add_outlined, color: Colors.white),
                      label: const Text('Tambah User Baru', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Search and Filter
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            hintText: 'Cari nama user...',
                            prefixIcon: const Icon(Icons.search, color: AppConst.textSecondary),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filterRole,
                            items: ['Semua', 'Anggota', 'Admin', 'Superadmin'].map((String val) {
                              return DropdownMenuItem<String>(
                                value: val,
                                child: Text(val),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _filterRole = val!);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // List
                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? const Center(child: Text('Tidak ada user ditemukan.', style: TextStyle(color: AppConst.textSecondary)))
                        : ListView.separated(
                            itemCount: _filteredUsers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (ctx, i) => _buildCardUser(_filteredUsers[i]),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCardUser(dynamic item) {
    final idUser = (item['id_user'] ?? '-').toString();
    final nama = (item['nama'] ?? 'User').toString();
    final nim = (item['nim'] ?? '-').toString();
    final email = (item['email'] ?? '-').toString();
    final role = (item['role'] ?? 'anggota').toString().toLowerCase();
    
    Color roleColor = Colors.blue;
    if (role == 'admin' || role == 'superadmin') {
      roleColor = AppConst.primary;
    }

    return InkWell(
      onTap: () async {
        final refresh = await Navigator.pushNamed(context, '/admin_users_edit', arguments: idUser);
        if (refresh == true) _fetch();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Placeholder
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: roleColor.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Text(
                  nama[0].toUpperCase(),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: roleColor),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Info Kanan
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          nama,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          role.toUpperCase(),
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'NIM: $nim',
                    style: const TextStyle(fontSize: 12, color: AppConst.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Email: $email',
                    style: const TextStyle(fontSize: 12, color: AppConst.textSecondary),
                  ),
                ],
              ),
            ),
            // Tombol Delete
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteUser(idUser),
              tooltip: 'Hapus User',
            ),
          ],
        ),
      ),
    );
  }
}
