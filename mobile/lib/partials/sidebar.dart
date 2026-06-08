import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../core/auth_provider.dart';
import 'flash_message.dart';

class Sidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartItemCount;
  final AuthProvider auth;

  const Sidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.cartItemCount,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, 'Beranda'),
              _navItem(1, Icons.inventory_2_rounded, 'Katalog'),
              _navItem(2, Icons.history_rounded, 'Riwayat'),
              _navItem(
                3,
                Icons.shopping_cart_rounded,
                'Keranjang',
                badgeCount: cartItemCount,
              ),
              _navLogout(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label, {int badgeCount = 0}) {
    final active = currentIndex == idx;
    final hasBadge = badgeCount > 0;

    return GestureDetector(
      onTap: () => onTap(idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppConst.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: active ? AppConst.primary : AppConst.textSecondary,
                ),
                if (hasBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppConst.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 9 ? '9+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? AppConst.primary : AppConst.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navLogout(BuildContext context) {
    final isLoggedIn = auth.isLoggedIn;

    return GestureDetector(
      onTap: () async {
        if (!isLoggedIn) {
          Navigator.pushNamed(context, '/login');
          return;
        }

        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Yakin ingin keluar?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: AppConst.error),
                ),
              ),
            ],
          ),
        );

        if (confirm == true) {
          await auth.logout();
          if (context.mounted) {
            FlashMessage.show(
              context,
              'Logout berhasil. Sampai jumpa!',
              isSuccess: true,
            );
            // Cukup kembalikan ke tab Beranda
            onTap(0);
          }
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLoggedIn ? Icons.logout_rounded : Icons.login_rounded,
              size: 24,
              color: isLoggedIn ? AppConst.error : AppConst.primary,
            ),
            const SizedBox(height: 2),
            Text(
              isLoggedIn ? 'Logout' : 'Login',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isLoggedIn ? AppConst.error : AppConst.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
