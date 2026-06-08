import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/api_service.dart';
import '../../../core/constants.dart';
import '../../../partials/admin/navbar.dart';
import '../../../partials/admin/sidebar.dart';
import '../../../partials/flash_message.dart';

class AdminBarangScreen extends StatefulWidget {
  const AdminBarangScreen({super.key});

  @override
  State<AdminBarangScreen> createState() => _AdminBarangScreenState();
}

class _AdminBarangScreenState extends State<AdminBarangScreen> {
  List<dynamic> _allBarang = [];
  bool _loading = true;

  String _searchQuery = '';
  String _filterKategori = 'Semua';
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
      final res = await ApiService.get('/api/barang', auth: true);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        final List<dynamic> listData = data['data'];
        listData.sort((a, b) {
          final idA = int.tryParse(a['id_barang']?.toString() ?? '0') ?? 0;
          final idB = int.tryParse(b['id_barang']?.toString() ?? '0') ?? 0;
          return idB.compareTo(idA); // Descending (terbaru di atas)
        });
        setState(() => _allBarang = listData);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _deleteBarang(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Barang'),
        content: const Text('Apakah Anda yakin ingin menghapus barang ini? Data yang sudah dihapus tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await ApiService.sendMultipart('/api/barang/$id', method: 'DELETE', fields: {}, auth: true);
      final responseString = await res.stream.bytesToString();
      final data = jsonDecode(responseString);
      
      if (res.statusCode == 200) {
        if (mounted) FlashMessage.show(context, 'Barang berhasil dihapus', isSuccess: true);
        _fetch();
      } else {
        if (mounted) FlashMessage.show(context, data['message'] ?? 'Gagal menghapus barang', isSuccess: false);
      }
    } catch (e) {
      if (mounted) FlashMessage.show(context, 'Terjadi kesalahan jaringan', isSuccess: false);
    }
  }

  // 1. Filter & Search
  List<dynamic> get _filteredBarang {
    return _allBarang.where((item) {
      final kategori = (item['nama_kategori'] ?? '').toString().toLowerCase();
      final namaBarang = (item['nama_barang'] ?? '').toString().toLowerCase();
      final lokasi = (item['lokasi'] ?? '').toString().toLowerCase();
      final idBarang = (item['id_barang'] ?? '').toString().toLowerCase();

      bool matchKategori = _filterKategori == 'Semua' || 
          kategori == _filterKategori.toLowerCase() || 
          (_filterKategori == 'Lainnya' && !['elektronik', 'olahraga', 'acara', 'dokumentasi'].contains(kategori));

      bool matchSearch = _searchQuery.isEmpty ||
          namaBarang.contains(_searchQuery.toLowerCase()) ||
          lokasi.contains(_searchQuery.toLowerCase()) ||
          idBarang.contains(_searchQuery.toLowerCase());

      return matchKategori && matchSearch;
    }).toList();
  }

  // 2. Pagination
  List<dynamic> get _paginatedBarang {
    final list = _filteredBarang;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    if (startIndex >= list.length) return [];
    return list.skip(startIndex).take(_itemsPerPage).toList();
  }

  int get _totalPages {
    final total = (_filteredBarang.length / _itemsPerPage).ceil();
    return total > 0 ? total : 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: const AdminNavbar(title: 'Kelola Barang'),
      drawer: const AdminSidebar(activeRoute: 'Data Barang'),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetch,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredBarang.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(child: Text('Tidak ada data barang yang cocok.')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: _paginatedBarang.length,
                          itemBuilder: (context, index) {
                            final item = _paginatedBarang[index];
                            return _buildCardContent(item);
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
          // Add Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final refresh = await Navigator.pushNamed(context, '/admin_barang_tambah');
                if (refresh == true) _fetch();
              },
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Tambah Barang Baru', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConst.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search
          TextField(
            decoration: InputDecoration(
              hintText: 'Cari ID, Nama, atau Lokasi...',
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
          // Filter Kategori
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['Semua', 'Elektronik', 'Olahraga', 'Acara', 'Dokumentasi', 'Lainnya'].map((kategori) {
                final isSelected = _filterKategori == kategori;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(kategori),
                    selected: isSelected,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _filterKategori = kategori;
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

  Widget _buildCardContent(Map<String, dynamic> item) {
    final idBarang = (item['id_barang'] ?? '-').toString();
    final namaBarang = (item['nama_barang'] ?? 'Barang').toString();
    final kategori = (item['nama_kategori'] ?? 'Kategori').toString();
    final stok = int.tryParse(item['stok']?.toString() ?? '0') ?? 0;
    final kondisi = (item['kondisi'] ?? 'baik').toString().toLowerCase();
    final lokasi = (item['lokasi'] ?? '-').toString();
    final deskripsi = (item['deskripsi'] ?? '').toString();
    final img = item['gambar']?.toString() ?? '';
    
    // Status color mapping based on stok & kondisi
    Color statusColor = Colors.green;
    String statusText = 'Tersedia';
    if (stok <= 0) {
      statusColor = Colors.red;
      statusText = 'Habis';
    } else if (kondisi != 'baik') {
      statusColor = Colors.orange;
      statusText = 'Maintenance';
    }

    return InkWell(
      onTap: () async {
        final refresh = await Navigator.pushNamed(context, '/admin_barang_edit', arguments: idBarang);
        if (refresh == true) _fetch();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Barang dan ID
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Container(
                      height: 90,
                      width: 90,
                      decoration: BoxDecoration(
                        color: AppConst.bg,
                        image: img.isNotEmpty 
                          ? DecorationImage(
                              image: NetworkImage('${AppConst.imageBaseUrl}/barang/$img'),
                              fit: BoxFit.cover,
                            )
                          : null,
                      ),
                      child: img.isEmpty 
                        ? const Center(child: Icon(Icons.inventory_2_outlined, color: AppConst.textSecondary, size: 32))
                        : null,
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: const BorderRadius.only(
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          kondisi[0].toUpperCase() + kondisi.substring(1),
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ID: $idBarang',
                style: const TextStyle(fontSize: 10, color: AppConst.textSecondary, fontWeight: FontWeight.bold),
              ),
            ],
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
                        namaBarang,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
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
                        statusText.toUpperCase(),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Kategori: $kategori',
                  style: const TextStyle(fontSize: 12, color: AppConst.textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 14, color: AppConst.textSecondary),
                    const SizedBox(width: 4),
                    Text('Stok: $stok', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppConst.textPrimary)),
                    const SizedBox(width: 12),
                    const Icon(Icons.location_on_outlined, size: 14, color: AppConst.textSecondary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        lokasi, 
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppConst.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: () {
                      _deleteBarang(idBarang);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red, size: 14),
                          SizedBox(width: 4),
                          Text('Hapus', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                if (deskripsi.isNotEmpty) ...[
                  const Divider(height: 16),
                  Text(
                    deskripsi,
                    style: const TextStyle(fontSize: 12, color: AppConst.textSecondary, fontStyle: FontStyle.italic),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }
}
