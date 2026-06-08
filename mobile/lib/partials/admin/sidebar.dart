import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../flash_message.dart';

class AdminSidebar extends StatelessWidget {
  final String activeRoute;

  const AdminSidebar({
    super.key,
    this.activeRoute = 'Dashboard',
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Drawer(
      backgroundColor: AppConst.bg,
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: AppConst.primary),
            accountName: Text('Halo, ${auth.user?['nama'] ?? 'Admin'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            accountEmail: Text(auth.user?['email'] ?? 'admin@pinjamin.com'),
            currentAccountPicture: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(8),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.dashboard_rounded, 
              color: activeRoute == 'Dashboard' ? AppConst.primary : AppConst.textSecondary,
            ),
            title: Text(
              'Dashboard', 
              style: TextStyle(
                fontWeight: activeRoute == 'Dashboard' ? FontWeight.w600 : FontWeight.normal,
                color: activeRoute == 'Dashboard' ? AppConst.textPrimary : AppConst.textSecondary,
              )
            ),
            selected: activeRoute == 'Dashboard',
            selectedTileColor: AppConst.primary.withValues(alpha: 0.1),
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              if (activeRoute != 'Dashboard') {
                nav.pushReplacementNamed('/admin');
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.inventory_2_outlined, 
              color: activeRoute == 'Data Barang' ? AppConst.primary : AppConst.textSecondary,
            ),
            title: Text(
              'Data Barang', 
              style: TextStyle(
                fontWeight: activeRoute == 'Data Barang' ? FontWeight.w600 : FontWeight.normal,
                color: activeRoute == 'Data Barang' ? AppConst.textPrimary : AppConst.textSecondary,
              )
            ),
            selected: activeRoute == 'Data Barang',
            selectedTileColor: AppConst.primary.withValues(alpha: 0.1),
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              if (activeRoute != 'Data Barang') {
                nav.pushReplacementNamed('/admin_barang');
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.swap_horiz_rounded, 
              color: activeRoute == 'Peminjaman' ? AppConst.primary : AppConst.textSecondary,
            ),
            title: Text(
              'Peminjaman', 
              style: TextStyle(
                fontWeight: activeRoute == 'Peminjaman' ? FontWeight.w600 : FontWeight.normal,
                color: activeRoute == 'Peminjaman' ? AppConst.textPrimary : AppConst.textSecondary,
              )
            ),
            selected: activeRoute == 'Peminjaman',
            selectedTileColor: AppConst.primary.withValues(alpha: 0.1),
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              if (activeRoute != 'Peminjaman') {
                nav.pushReplacementNamed('/admin_peminjaman');
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.group_outlined, 
              color: activeRoute == '/admin_users' ? AppConst.primary : AppConst.textSecondary,
            ),
            title: Text(
              'Manajemen User', 
              style: TextStyle(
                fontWeight: activeRoute == '/admin_users' ? FontWeight.w600 : FontWeight.normal,
                color: activeRoute == '/admin_users' ? AppConst.textPrimary : AppConst.textSecondary,
              )
            ),
            selected: activeRoute == '/admin_users',
            selectedTileColor: AppConst.primary.withValues(alpha: 0.1),
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              if (activeRoute != '/admin_users') {
                nav.pushReplacementNamed('/admin_users');
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.qr_code_scanner_rounded, 
              color: activeRoute == 'Verifikasi QR' ? AppConst.primary : AppConst.textSecondary,
            ),
            title: Text(
              'Verifikasi QR', 
              style: TextStyle(
                fontWeight: activeRoute == 'Verifikasi QR' ? FontWeight.w600 : FontWeight.normal,
                color: activeRoute == 'Verifikasi QR' ? AppConst.textPrimary : AppConst.textSecondary,
              )
            ),
            selected: activeRoute == 'Verifikasi QR',
            selectedTileColor: AppConst.primary.withValues(alpha: 0.1),
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              if (activeRoute != 'Verifikasi QR') {
                nav.pushReplacementNamed('/admin_verif');
              }
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.phone_android_rounded, color: AppConst.primary),
            title: const Text('Buka Aplikasi', style: TextStyle(color: AppConst.textPrimary, fontWeight: FontWeight.w600)),
            onTap: () {
              final nav = Navigator.of(context);
              nav.pop();
              nav.pushNamed('/home');
            },
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppConst.error),
            title: const Text('Logout', style: TextStyle(color: AppConst.error, fontWeight: FontWeight.w600)),
            onTap: () async {
              await auth.logout();
              if (context.mounted) {
                FlashMessage.show(
                  context,
                  'Logout berhasil. Sampai jumpa!',
                  isSuccess: true,
                );
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
