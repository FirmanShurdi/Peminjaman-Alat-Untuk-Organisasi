import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import 'package:provider/provider.dart';
import '../../core/cart_provider.dart';
import '../../partials/flash_message.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});
  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  List<dynamic> _barang = [];
  List<dynamic> _kategori = [];
  String _activeKat = 'Semua';
  String _searchQuery = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resB = await ApiService.get('/api/barang');
      final resK = await ApiService.get('/api/barang/kategori');
      final bData = jsonDecode(resB.body);
      final kData = jsonDecode(resK.body);
      setState(() {
        _barang = bData['data'] ?? [];
        _kategori = kData['data'] ?? [];
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<dynamic> get _filtered {
    return _barang.where((b) {
      final matchKat = _activeKat == 'Semua' || b['nama_kategori'] == _activeKat;
      final matchSearch = _searchQuery.isEmpty ||
          (b['nama_barang'] ?? '').toString().toLowerCase().contains(_searchQuery.toLowerCase());
      return matchKat && matchSearch;
    }).toList();
  }

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
                        const Text('Katalog Barang', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                        const SizedBox(height: 4),
                        const Text('Temukan alat yang Anda butuhkan', style: TextStyle(color: AppConst.textSecondary, fontSize: 14)),
                        const SizedBox(height: 16),
                        // Pencarian
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search_rounded, color: AppConst.textSecondary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  style: const TextStyle(fontSize: 14, color: AppConst.textPrimary),
                                  decoration: const InputDecoration(
                                    hintText: 'Cari alat...',
                                    hintStyle: TextStyle(color: AppConst.textSecondary, fontSize: 14),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Kategori chips
                        SizedBox(
                          height: 40,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _chip('Semua'),
                              ..._kategori.map((k) => _chip(k['nama_kategori'] ?? '')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                _filtered.isEmpty
                    ? const SliverFillRemaining(child: Center(child: Text('Belum ada barang di kategori ini.', style: TextStyle(color: AppConst.textSecondary))))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverGrid(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _buildProductCard(_filtered[i]),
                            childCount: _filtered.length,
                          ),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.56,
                          ),
                        ),
                      ),
              ],
            ),
    );
  }

  Widget _chip(String label) {
    final active = _activeKat == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: active ? Colors.white : AppConst.textSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
        selected: active,
        selectedColor: AppConst.primary,
        backgroundColor: Colors.white,
        side: BorderSide(color: active ? AppConst.primary : AppConst.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        onSelected: (_) => setState(() => _activeKat = label),
      ),
    );
  }

  Widget _buildProductCard(dynamic b) {
    final isAvailable = (b['stok'] ?? 0) > 0;
    final stok = b['stok'] ?? 0;
    final imgUrl = (b['gambar'] != null && b['gambar'] != '')
        ? '${AppConst.imageBaseUrl}/barang/${b['gambar']}'
        : null;

    return GestureDetector(
      onTap: () =>
          Navigator.pushNamed(context, '/detail', arguments: b['id_barang']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppConst.primaryDark.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGE ──
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: double.infinity,
                      child: imgUrl != null
                          ? Image.network(
                              imgUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _placeholderImg(),
                            )
                          : _placeholderImg(),
                    ),
                  ),
                  // Availability badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAvailable
                            ? AppConst.success.withValues(alpha: 0.9)
                            : AppConst.error.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isAvailable ? 'Tersedia' : 'Habis',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── INFO ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      b['nama_barang'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppConst.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Category
                    Text(
                      b['nama_kategori'] ?? 'Umum',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppConst.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Description
                    Expanded(
                      child: Text(
                        b['deskripsi'] ??
                            'Tidak ada deskripsi untuk barang ini.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppConst.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Bottom row: stock + add button
                    Row(
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 14,
                          color: AppConst.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Stok: $stok',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppConst.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        // Add / Detail button
                        GestureDetector(
                          onTap: isAvailable
                              ? () => _showAddToCartModal(context, b)
                              : null,
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: isAvailable
                                  ? const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF60A5FA),
                                        AppConst.primaryDark,
                                      ],
                                    )
                                  : LinearGradient(
                                      colors: [
                                        Colors.grey.shade300,
                                        Colors.grey.shade400,
                                      ],
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isAvailable
                                  ? [
                                      BoxShadow(
                                        color: AppConst.primary.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToCartModal(BuildContext context, dynamic b) {
    final stok = b['stok'] ?? 0;
    if (stok <= 0) return;

    int qty = 1;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext ctx, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppConst.bg,
                          image: (b['gambar'] != null && b['gambar'] != '')
                              ? DecorationImage(
                                  image: NetworkImage('${AppConst.imageBaseUrl}/barang/${b['gambar']}'),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: (b['gambar'] == null || b['gambar'] == '')
                            ? const Icon(Icons.inventory_2_outlined, color: AppConst.textSecondary)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b['nama_barang'] ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppConst.textPrimary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Stok Tersedia: $stok Unit',
                              style: const TextStyle(fontSize: 13, color: AppConst.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text('Atur Jumlah Peminjaman', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          if (qty > 1) setModalState(() => qty--);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: qty > 1 ? AppConst.primary : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.remove, color: qty > 1 ? AppConst.primary : Colors.grey[400], size: 24),
                        ),
                      ),
                      Text(
                        '$qty',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppConst.textPrimary),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (qty < stok) setModalState(() => qty++);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: qty < stok ? AppConst.primary : Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.add, color: qty < stok ? AppConst.primary : Colors.grey[400], size: 24),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await context.read<CartProvider>().addItem(b, quantity: qty);
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          FlashMessage.show(
                            context,
                            'Berhasil menambahkan $qty item ke keranjang',
                            isSuccess: true,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          Navigator.pop(ctx);
                          FlashMessage.show(
                            context,
                            e.toString().replaceAll('Exception: ', ''),
                            isSuccess: false,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConst.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('Masukkan Keranjang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _placeholderImg() => Container(
    color: const Color(0xFFF1F5F9),
    child: const Center(
      child: Icon(
        Icons.inventory_2_outlined,
        color: Color(0xFFCBD5E1),
        size: 36,
      ),
    ),
  );
}
