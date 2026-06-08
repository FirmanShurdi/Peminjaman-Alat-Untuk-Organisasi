import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/cart_provider.dart';
import '../../core/constants.dart';
import '../../partials/flash_message.dart';
import '../../partials/app_header.dart';

class BerandaScreen extends StatefulWidget {
  const BerandaScreen({super.key});
  @override
  State<BerandaScreen> createState() => _BerandaScreenState();
}

class _BerandaScreenState extends State<BerandaScreen> {
  List<dynamic> _allBarang = [];
  List<dynamic> _kategoriList = [];
  String _selectedKategori = 'Semua';
  String _searchQuery = '';
  bool _loading = true;

  final TextEditingController _searchCtrl = TextEditingController();

  int _currentTutorialStep = 0;
  late PageController _tutorialController;
  Timer? _tutorialTimer;
  Timer? _notifTimer;
  int _unreadNotifCount = 0;

  final List<String> _tutorialImages = [
    '/intro/step1.png',
    '/intro/step2.png',
    '/intro/step3.png',
    '/intro/step4.png',
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchUnread();
    _tutorialController = PageController(initialPage: 0);
    _startTutorialTimer();
    _notifTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchUnread());
  }

  Future<void> _fetchUnread() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn) return;
    try {
      final res = await ApiService.get('/notifikasi/unread-count', auth: true);
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final count = json['unread'] ?? 0;
        if (_unreadNotifCount != count && mounted) {
          setState(() => _unreadNotifCount = count);
        }
      }
    } catch (_) {}
  }

  void _startTutorialTimer() {
    _tutorialTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_tutorialController.hasClients) {
        int nextPage = _currentTutorialStep + 1;
        if (nextPage >= _tutorialImages.length) {
          nextPage = 0;
        }
        _tutorialController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tutorialTimer?.cancel();
    _notifTimer?.cancel();
    _tutorialController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final resBarang = await ApiService.get('/api/barang');
      final barangData = jsonDecode(resBarang.body);

      final resKat = await ApiService.get('/api/barang/kategori');
      final katData = jsonDecode(resKat.body);

      setState(() {
        _allBarang = (barangData['data'] as List?) ?? [];
        _kategoriList = (katData['data'] as List?) ?? [];
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  List<dynamic> get _filteredBarang {
    final list = _allBarang.where((b) {
      final stok = b['stok'] ?? 0;
      final matchStok = stok > 0;
      final matchKat =
          _selectedKategori == 'Semua' ||
          (b['nama_kategori'] ?? '').toString().toLowerCase() ==
              _selectedKategori.toLowerCase();
      final matchSearch =
          _searchQuery.isEmpty ||
          (b['nama_barang'] ?? '').toString().toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      return matchStok && matchKat && matchSearch;
    }).toList();
    return list.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final cart = context.watch<CartProvider>();
    final user = auth.user;
    final filtered = _filteredBarang;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppConst.primary),
            )
          : RefreshIndicator(
              color: AppConst.primary,
              onRefresh: _fetch,
              child: CustomScrollView(
                slivers: [
                  // ── HEADER & SEARCH BAR ──
                  SliverToBoxAdapter(
                    child: AppHeader(
                      userName: user?['nama'] ?? 'Pengguna',
                      cartCount: cart.itemCount,
                      notificationCount: _unreadNotifCount,
                      onNotificationClosed: _fetchUnread,
                      searchController: _searchCtrl,
                      onSearchChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),

                  // ── TUTORIAL CAROUSEL ──
                  SliverToBoxAdapter(child: _buildTutorialCarousel()),

                  // ── CATEGORY CHIPS ──
                  SliverToBoxAdapter(child: _buildCategoryChips()),

                  // ── PRODUCT GRID ──
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    sliver: filtered.isEmpty
                        ? SliverToBoxAdapter(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 64,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Tidak ada barang ditemukan.',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio:
                                      0.56, // Penyesuaian agar tidak terlalu panjang
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) =>
                                  _buildProductCard(filtered[index]),
                              childCount: filtered.length,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  // ══════════════════════════════════════════════
  //  CATEGORY CHIPS
  // ══════════════════════════════════════════════
  Widget _buildCategoryChips() {
    final allKats = [
      'Semua',
      ..._kategoriList.map((k) => k['nama_kategori'].toString()),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: 42,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: allKats.length,
          separatorBuilder: (context, index) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final kat = allKats[index];
            final isActive = _selectedKategori == kat;

            return GestureDetector(
              onTap: () => setState(() {
                _selectedKategori = kat;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? AppConst.primary : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? AppConst.primary
                        : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppConst.primary.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  kat,
                  style: TextStyle(
                    color: isActive ? Colors.white : AppConst.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  TUTORIAL CAROUSEL
  // ══════════════════════════════════════════════

  static const List<String> _stepTitles = [
    'Pilih Barang',
    'Isi Jadwal Peminjaman',
    'Upload Dokumen',
    'Ambil Barang',
  ];

  static const List<String> _stepDescs = [
    'Cari dan pilih alat yang ingin kamu pinjam dari katalog.',
    'Tentukan tanggal pinjam, tanggal kembali, dan jumlah unit.',
    'Unggah KTM dan foto selfie lalu kirim pengajuan.',
    'Tunggu persetujuan admin, lalu ambil barang di lokasi.',
  ];

  Widget _buildTutorialCarousel() {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text(
                  'Cara Peminjaman',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppConst.textPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppConst.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_currentTutorialStep + 1}/${_tutorialImages.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppConst.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320, // Format potret
            child: PageView.builder(
              controller: _tutorialController,
              onPageChanged: (idx) =>
                  setState(() => _currentTutorialStep = idx),
              itemCount: _tutorialImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppConst.primaryDark.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ── Gambar dengan zoom pada step1 ──
                        index == 0
                            ? _buildZoomableStep1()
                            : Image.network(
                                '${AppConst.imageBaseUrl}${_tutorialImages[index]}',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: const Color(0xFFF1F5F9),
                                  child: const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Color(0xFFCBD5E1),
                                      size: 40,
                                    ),
                                  ),
                                ),
                              ),

                        // ── Gradient overlay di bawah ──
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: 120,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.7),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Label step di bawah ──
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppConst.primary,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Step ${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _stepTitles[index],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _stepDescs[index],
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // ── Dot indicators ──
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_tutorialImages.length, (index) {
              final isActive = _currentTutorialStep == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: isActive ? 24 : 6,
                decoration: BoxDecoration(
                  color: isActive ? AppConst.primary : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  /// Step 1: Gambar landscape yang otomatis zoom ke card barang pertama
  Widget _buildZoomableStep1() {
    // Animasi zoom yang berjalan terus (pan & zoom ke card pertama)
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 2.2),
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOut,
      builder: (context, scaleVal, child) {
        return Transform(
          alignment: const Alignment(
            -0.85,
            0.3,
          ), // Fokus ke card kiri (barang pertama)
          transform: Matrix4.diagonal3Values(scaleVal, scaleVal, 1.0),
          child: child,
        );
      },
      child: Image.network(
        '${AppConst.imageBaseUrl}${_tutorialImages[0]}',
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: Icon(
              Icons.image_not_supported_outlined,
              color: Color(0xFFCBD5E1),
              size: 40,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  //  PRODUCT CARD (Grid item)
  // ══════════════════════════════════════════════
  Widget _buildProductCard(dynamic b) {
    final imgUrl = (b['gambar'] != null && b['gambar'] != '')
        ? '${AppConst.imageBaseUrl}/barang/${b['gambar']}'
        : null;
    final stok = b['stok'] ?? 0;
    final isAvailable = stok > 0;

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
