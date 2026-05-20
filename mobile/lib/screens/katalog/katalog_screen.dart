import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';

class KatalogScreen extends StatefulWidget {
  const KatalogScreen({super.key});
  @override
  State<KatalogScreen> createState() => _KatalogScreenState();
}

class _KatalogScreenState extends State<KatalogScreen> {
  List<dynamic> _barang = [];
  List<dynamic> _kategori = [];
  String _activeKat = 'Semua';
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

  List<dynamic> get _filtered => _activeKat == 'Semua'
      ? _barang
      : _barang.where((b) => b['nama_kategori'] == _activeKat).toList();

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
                            (ctx, i) => _card(_filtered[i]),
                            childCount: _filtered.length,
                          ),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.72,
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

  Widget _card(dynamic b) {
    final imgUrl = (b['gambar'] != null && b['gambar'] != '') ? '${AppConst.baseUrl}/barang/${b['gambar']}' : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: b['id_barang']),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: SizedBox(
                  width: double.infinity,
                  child: imgUrl != null
                      ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (_, _, _) => _ph())
                      : _ph(),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b['nama_kategori'] ?? '', style: const TextStyle(fontSize: 10, color: AppConst.primary, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(b['nama_barang'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppConst.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 12, color: AppConst.textSecondary),
                        const SizedBox(width: 3),
                        Text('Stok: ${b['stok']}', style: const TextStyle(fontSize: 11, color: AppConst.textSecondary)),
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

  Widget _ph() => Container(color: AppConst.bg, child: const Center(child: Icon(Icons.image_outlined, color: AppConst.textSecondary, size: 28)));
}
