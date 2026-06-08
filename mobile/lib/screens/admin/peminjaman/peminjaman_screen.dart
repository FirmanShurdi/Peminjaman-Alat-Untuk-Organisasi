import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../partials/admin/navbar.dart';
import '../../../partials/admin/sidebar.dart';
import '../../../partials/flash_message.dart';

class AdminPeminjamanScreen extends StatefulWidget {
  const AdminPeminjamanScreen({super.key});

  @override
  State<AdminPeminjamanScreen> createState() => _AdminPeminjamanScreenState();
}

class _AdminPeminjamanScreenState extends State<AdminPeminjamanScreen> {
  List<dynamic> _allPeminjaman = [];
  bool _loading = true;

  String _searchQuery = '';
  String _filterStatus = 'Semua';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/api/peminjaman', auth: true);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() => _allPeminjaman = data['data']);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _deletePeminjaman(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Peminjaman'),
        content: const Text('Apakah Anda yakin ingin menghapus data peminjaman ini?'),
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
      final res = await ApiService.delete('/api/peminjaman/$id', auth: true);
      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        if (mounted) FlashMessage.show(context, 'Data peminjaman berhasil dihapus', isSuccess: true);
        _fetch();
      } else {
        if (mounted) FlashMessage.show(context, data['message'] ?? 'Gagal menghapus data', isSuccess: false);
      }
    } catch (e) {
      if (mounted) FlashMessage.show(context, 'Terjadi kesalahan jaringan.', isSuccess: false);
    }
  }

  // 1. Filter, Search & Grouping
  List<List<dynamic>> get _filteredAndGrouped {
    // 1. Group by no_pesanan first to keep Cart items together
    Map<String, List<dynamic>> groups = {};
    for (var item in _allPeminjaman) {
      final np = (item['no_pesanan'] ?? item['id_peminjaman']).toString();
      if (!groups.containsKey(np)) groups[np] = [];
      groups[np]!.add(item);
    }

    // 2. Filter groups based on search and status
    List<List<dynamic>> result = [];
    for (var group in groups.values) {
      bool groupMatches = false;
      
      for (var item in group) {
        final status = (item['status'] ?? '').toString().toLowerCase();
        final noPesanan = (item['no_pesanan'] ?? '').toString().toLowerCase();
        final namaBarang = (item['nama_barang'] ?? '').toString().toLowerCase();
        final namaUser = (item['nama_user'] ?? '').toString().toLowerCase();

        final filterClean = _filterStatus.toLowerCase().replaceAll(' ', '_');
        bool matchStatus = _filterStatus == 'Semua' || status == filterClean;
        bool matchSearch = _searchQuery.isEmpty ||
            noPesanan.contains(_searchQuery.toLowerCase()) ||
            namaBarang.contains(_searchQuery.toLowerCase()) ||
            namaUser.contains(_searchQuery.toLowerCase());

        if (matchStatus && matchSearch) {
          groupMatches = true;
          break; // If one item in the cart matches, show the whole cart!
        }
      }

      if (groupMatches) {
        result.add(group);
      }
    }

    return result;
  }

  // 2. Pagination
  List<List<dynamic>> get _paginatedGroups {
    final groups = _filteredAndGrouped;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= groups.length) return [];
    return groups.skip(startIndex).take(_itemsPerPage).toList();
  }

  int get _totalPages {
    final total = (_filteredAndGrouped.length / _itemsPerPage).ceil();
    return total > 0 ? total : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: const AdminNavbar(title: 'Kelola Peminjaman'),
      drawer: const AdminSidebar(activeRoute: 'Peminjaman'),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAndGrouped.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Tidak ada data peminjaman yang cocok.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _paginatedGroups.length,
                          itemBuilder: (context, index) {
                            final group = _paginatedGroups[index];
                            return _buildGroupCard(group);
                          },
                        ),
            ),
          ),
          if (!_loading && _totalPages > 1) _buildPagination(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari No Pesanan, User, atau Barang...',
              prefixIcon: const Icon(Icons.search, color: AppConst.textSecondary),
              filled: true,
              fillColor: AppConst.bg,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 1;
              });
            },
          ),
          const SizedBox(height: 12),
          // Filter Status
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Menunggu', 'Disetujui', 'Diambil', 'Selesai', 'Selesai Terlambat', 'Terlambat', 'Ditolak', 'Dibatalkan'].map((status) {
                final isSelected = _filterStatus == status;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(status),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _filterStatus = status;
                          _currentPage = 1;
                        });
                      }
                    },
                    selectedColor: AppConst.primary.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected ? AppConst.primary : AppConst.textSecondary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppConst.primary : Colors.grey.shade300,
                    ),
                  ),
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConst.bg,
              foregroundColor: AppConst.textPrimary,
              elevation: 0,
            ),
            child: const Text('Sebelumnya'),
          ),
          Text('Halaman $_currentPage dari $_totalPages', style: const TextStyle(fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: _currentPage < _totalPages ? () => setState(() => _currentPage++) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConst.primary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            child: const Text('Selanjutnya'),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupCard(List<dynamic> group) {
    if (group.isEmpty) return const SizedBox();
    
    final isMultiple = group.length > 1;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background stacked cards (Cart indicator)
          if (isMultiple)
            Positioned(
              bottom: -10,
              left: 12,
              right: 12,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
              ),
            ),
          if (isMultiple)
            Positioned(
              bottom: -5,
              left: 6,
              right: 6,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                ),
              ),
            ),
          
          // Main Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isMultiple ? AppConst.primary.withValues(alpha: 0.5) : Colors.transparent, 
                width: isMultiple ? 1.5 : 0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Column(
              children: group.asMap().entries.map((entry) {
                final idx = entry.key;
                final it = entry.value;
                return Column(
                  children: [
                    _buildCardContent(it, isMultiple),
                    if (idx < group.length - 1)
                      Divider(color: Colors.grey.shade200, height: 32, thickness: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildCardContent(Map<String, dynamic> item, bool isMultiple) {
    final noPesanan = (item['no_pesanan'] ?? '-').toString();
    final idPeminjaman = (item['id_peminjaman'] ?? '-').toString();
    final namaBarang = (item['nama_barang'] ?? 'Barang').toString();
    final namaUser = (item['nama_user'] ?? 'User').toString();
    final idUser = (item['id_user'] ?? '-').toString();
    final idBarang = (item['id_barang'] ?? '-').toString();
    final status = (item['status'] ?? 'menunggu').toString();
    
    // Status color mapping
    Color statusColor = Colors.grey;
    if (status == 'menunggu') {
      statusColor = Colors.orange;
    } else if (status == 'disetujui') {
      statusColor = Colors.blue;
    } else if (status == 'diambil') {
      statusColor = Colors.indigo;
    } else if (status == 'selesai') {
      statusColor = Colors.green;
    } else if (status == 'ditolak' || status == 'dibatalkan') {
      statusColor = Colors.red;
    } else if (status == 'terlambat' || status == 'selesai_terlambat') {
      statusColor = Colors.deepOrange;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final refresh = await Navigator.pushNamed(context, '/admin_peminjaman_edit', arguments: idPeminjaman);
          if (refresh == true) {
            _fetch();
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
        // Kiri: QR Code & ID
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: noPesanan,
                version: QrVersions.auto,
                size: 70,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noPesanan,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
            Text(
              'ID: $idPeminjaman',
              style: const TextStyle(fontSize: 10, color: AppConst.textSecondary),
            ),
          ],
        ),
        const SizedBox(width: 12),
        // Kanan: Info Barang & User (dengan garis penyambung di kiri)
        Expanded(
          child: Container(
            padding: const EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            namaBarang,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text('ID Barang: $idBarang', style: const TextStyle(fontSize: 12, color: AppConst.textSecondary)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    onPressed: () => _deletePeminjaman(idPeminjaman),
                  )
                ],
              ),
              const SizedBox(height: 12),
              
              // Gambar Barang
              if (item['gambar'] != null && item['gambar'].toString().isNotEmpty)
                Container(
                  height: 100,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppConst.bg,
                    image: DecorationImage(
                      image: NetworkImage('${AppConst.imageBaseUrl}/barang/${item['gambar']}'),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 100,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppConst.bg,
                  ),
                  child: const Center(child: Icon(Icons.inventory_2_outlined, color: AppConst.textSecondary, size: 40)),
                ),

              Row(
                children: [
                  const Icon(Icons.person_outline, size: 16, color: AppConst.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '$namaUser (ID: $idUser)',
                      style: const TextStyle(fontSize: 13, color: AppConst.textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 16, color: AppConst.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Verifikator: Admin',
                      style: const TextStyle(fontSize: 12, color: AppConst.textSecondary),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
        )
        ],
      ),
      ),
      ),
    );
  }
}
