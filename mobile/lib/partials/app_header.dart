import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/auth_provider.dart';
import '../core/constants.dart';
import '../screens/notifikasi/notifikasi_screen.dart';

/// Widget Header + Search Bar yang dapat digunakan di banyak halaman.
///
/// [userName] — Nama pengguna untuk sapaan.
/// [cartCount] — Jumlah item di keranjang (ditampilkan sebagai badge).
/// [searchController] — Controller untuk TextField pencarian.
/// [onSearchChanged] — Callback saat teks pencarian berubah.
/// [showSearch] — Tampilkan search bar atau tidak (default: true).
class AppHeader extends StatelessWidget {
  final String userName;
  final int cartCount;
  final int notificationCount;
  final VoidCallback? onNotificationClosed;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final bool showSearch;
  final bool showBackBtn;

  const AppHeader({
    super.key,
    required this.userName,
    this.cartCount = 0,
    this.notificationCount = 0,
    this.onNotificationClosed,
    this.searchController,
    this.onSearchChanged,
    this.showSearch = true,
    this.showBackBtn = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            _buildHeader(context),
            if (showSearch) const SizedBox(height: 52),
            if (!showSearch) const SizedBox(height: 8),
          ],
        ),
        if (showSearch)
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _buildSearchBar(context),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════
  //  HEADER — Blue gradient with greeting + icons
  // ══════════════════════════════════════════════
  Widget _buildHeader(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(20, topPad + 16, 20, 48),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF60A5FA), AppConst.primary, AppConst.primaryDark],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: AppConst.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Logo + Text + Icons
          Row(
            children: [
              // Back Button (Optional)
              if (showBackBtn)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              // Logo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.network(
                    '${AppConst.imageBaseUrl}/intro/logo.png',
                    width: 26,
                    height: 26,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.handshake_rounded,
                      color: AppConst.primary,
                      size: 26,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Greeting or App Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (userName != 'Pengguna') ...[
                      const Text(
                        'Halo,',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      const Text(
                        'PinjamIN',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Dashboard button for Admins
              if (context.watch<AuthProvider>().user?['role'] == 'admin') ...[
                _headerIcon(Icons.dashboard_rounded, () {
                  Navigator.pop(context); // Go back to Dashboard from Home
                }),
                const SizedBox(width: 8),
              ],
              // Notification Bell
              _headerIcon(Icons.notifications_outlined, () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
                );
                if (onNotificationClosed != null) {
                  onNotificationClosed!();
                }
              }, badgeCount: notificationCount),
            ],
          ),

          const SizedBox(height: 24),

          // Animated Elegant Hero text
          const _AnimatedHeroText(),

          const SizedBox(height: 12),

          Center(
            child: Text(
              'Kelola peminjaman inventaris untuk acara organisasi\nlebih cepat, rapi, dan terstruktur.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 14,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap, {int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -4,
              right: -4,
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
    );
  }

  // ══════════════════════════════════════════════
  //  SEARCH BAR
  // ══════════════════════════════════════════════
  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppConst.primaryDark.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 22),
            const Icon(Icons.search_rounded, color: AppConst.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: onSearchChanged,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppConst.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: const InputDecoration(
                  hintText: 'Cari alat yang ingin dipinjam...',
                  hintStyle: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  isDense: true,
                ),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: AppConst.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppConst.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedHeroText extends StatefulWidget {
  const _AnimatedHeroText();

  @override
  State<_AnimatedHeroText> createState() => _AnimatedHeroTextState();
}

class _AnimatedHeroTextState extends State<_AnimatedHeroText> {
  final List<String> _phrases = [
    'Pinjam Alat Kampus\nLebih Praktis',
    'Bebas Antrean &\nCepat Disetujui',
    'Persiapan Event\nJadi Terencana',
  ];
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _phrases.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.4),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Text(
          _phrases[_currentIndex],
          key: ValueKey<String>(_phrases[_currentIndex]),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            height: 1.3,
            color: Colors.white, // Putih murni memberikan kesan paling elegan pada gradient biru
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
