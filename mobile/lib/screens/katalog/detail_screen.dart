import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';
import '../../main.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/cart_provider.dart';
import '../../partials/flash_message.dart';
class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key});
  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  dynamic _barang;
  List<dynamic> _bookedDates = [];
  final Set<String> _bookedSet = {};
  bool _loading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = ModalRoute.of(context)?.settings.arguments;
    if (id != null && _barang == null) _fetch(id);
  }

  Future<void> _fetch(dynamic id) async {
    setState(() => _loading = true);
    try {
      final resB = await ApiService.get('/api/barang/$id');
      final resD = await ApiService.get('/api/barang/$id/booked-dates');
      final bData = jsonDecode(resB.body);
      final dData = jsonDecode(resD.body);
      setState(() {
        _barang = bData['data'];
        _bookedDates = dData['data'] ?? [];
        _bookedSet.clear();
        for (final bd in _bookedDates) {
          try {
            final s = DateTime.parse(bd['tanggal_pinjam']);
            final e = DateTime.parse(bd['tanggal_kembali']);
            for (var dt = s; dt.isBefore(e.add(const Duration(days: 1))); dt = dt.add(const Duration(days: 1))) {
              _bookedSet.add(DateFormat('yyyy-MM-dd').format(dt));
            }
          } catch (_) {}
        }
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = (_barang != null && _barang['gambar'] != null && _barang['gambar'] != '')
        ? '${AppConst.imageBaseUrl}/barang/${_barang['gambar']}'
        : null;

    return Scaffold(
      backgroundColor: AppConst.bg,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _barang == null
              ? const Center(child: Text('Barang tidak ditemukan'))
              : Column(
                  children: [
                    // Top Bar (Custom)
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]),
                              child: const Icon(Icons.arrow_back_ios_new_rounded, color: AppConst.textPrimary, size: 20),
                            ),
                          ),
                          Row(
                            children: [
                              _appBarIcon(Icons.notifications_outlined, () {}),
                              const SizedBox(width: 12),
                              _appBarIcon(Icons.shopping_cart_outlined, () {
                                Navigator.pushNamed(context, '/cart');
                              }, badgeCount: context.watch<CartProvider>().items.length),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Detached Image Card
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 20),
                              height: 280,
                              decoration: BoxDecoration(
                                color: AppConst.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                image: imgUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(imgUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: imgUrl == null
                                  ? const Center(child: Icon(Icons.inventory_2_rounded, color: AppConst.textSecondary, size: 64))
                                  : null,
                            ),
                            
                            // Content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Kategori badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppConst.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(_barang['nama_kategori'] ?? 'Umum', style: const TextStyle(color: AppConst.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(_barang['nama_barang'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                                  const SizedBox(height: 16),

                                  // Info cards
                                  _infoRow(Icons.inventory_2_outlined, 'Stok Tersedia', '${_barang['stok']} unit'),
                                  _infoRow(Icons.location_on_outlined, 'Lokasi', _barang['lokasi'] ?? '-'),
                                  _infoRow(Icons.build_outlined, 'Kondisi', _barang['kondisi'] ?? '-'),
                                  const SizedBox(height: 24),

                                  // Deskripsi
                                  if (_barang['deskripsi'] != null && _barang['deskripsi'] != '') ...[
                                    const Text('Deskripsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
                                    const SizedBox(height: 8),
                                    Text(_barang['deskripsi'], style: const TextStyle(fontSize: 14, color: AppConst.textSecondary, height: 1.5)),
                                    const SizedBox(height: 24),
                                  ],
                                  
                                  // Ketersediaan Alat
                                  const Text('Jadwal Ketersediaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppConst.border),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))],
                                    ),
                                    padding: const EdgeInsets.all(8),
                                    child: TableCalendar(
                                      firstDay: DateTime(2020),
                                      lastDay: DateTime.now().add(const Duration(days: 365)),
                                      focusedDay: DateTime.now(),
                                      availableCalendarFormats: const {CalendarFormat.month: 'Bulan'},
                                      headerStyle: const HeaderStyle(
                                        titleCentered: true,
                                        formatButtonVisible: false,
                                        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      calendarStyle: CalendarStyle(
                                        todayDecoration: BoxDecoration(
                                          color: _bookedSet.contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                              ? Colors.deepOrange
                                              : const Color(0x663B82F6),
                                          shape: BoxShape.circle,
                                          border: _bookedSet.contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                              ? Border.all(color: const Color.fromARGB(255, 57, 136, 226), width: 2.5)
                                              : null,
                                        ),
                                        todayTextStyle: TextStyle(
                                          color: _bookedSet.contains(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                                              ? Colors.white
                                              : AppConst.textPrimary,
                                        ),
                                        holidayDecoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                        holidayTextStyle: const TextStyle(color: Colors.white),
                                      ),
                                      holidayPredicate: (day) {
                                        return _bookedSet.contains(DateFormat('yyyy-MM-dd').format(day));
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      const Text('Jadwal padat (Terdapat peminjaman)', style: TextStyle(fontSize: 12, color: AppConst.textSecondary)),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _barang != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    // Tombol Ajukan Peminjaman
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: (_barang['stok'] ?? 0) > 0 
                            ? () async {
                                final res = await Navigator.pushNamed(context, '/book', arguments: {
                                  'barang': _barang,
                                  'bookedDates': _bookedDates,
                                });
                                if (res == true) {
                                  if (!mounted) return;
                                  Navigator.pop(this.context); // Close detail screen
                                  homeShellKey.currentState?.switchTab(2); // Go to Riwayat
                                }
                              } 
                            : null,
                          icon: const Icon(Icons.send_rounded, size: 20),
                          label: Text((_barang['stok'] ?? 0) > 0 ? 'Ajukan Peminjaman' : 'Stok Habis', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConst.primary,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: AppConst.border,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Tombol Tambah ke Keranjang
                    GestureDetector(
                      onTap: (_barang['stok'] ?? 0) > 0 ? () => _showAddToCartModal() : null,
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppConst.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.add_shopping_cart,
                          color: (_barang['stok'] ?? 0) > 0 ? AppConst.primary : AppConst.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _appBarIcon(IconData icon, VoidCallback onTap, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
                ]
              ),
              child: Icon(icon, color: AppConst.textPrimary, size: 22),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConst.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppConst.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppConst.primary),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppConst.textSecondary)),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppConst.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }



  void _showAddToCartModal() {
    final stok = _barang['stok'] ?? 0;
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
                            Text(
                              _barang['nama_barang'] ?? '',
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
                        final nav = Navigator.of(ctx);
                        try {
                          await context.read<CartProvider>().addItem(_barang, quantity: qty);
                          nav.pop();
                          if (!mounted) return;
                          FlashMessage.show(
                            context,
                            'Berhasil menambahkan $qty item ke keranjang',
                            isSuccess: true,
                          );
                        } catch (e) {
                          nav.pop();
                          if (!mounted) return;
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
}
