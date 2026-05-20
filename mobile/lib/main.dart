import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/beranda/beranda_screen.dart';
import 'screens/katalog/katalog_screen.dart';
import 'screens/katalog/detail_screen.dart';
import 'screens/riwayat/riwayat_screen.dart';
import 'screens/notifikasi/notifikasi_screen.dart';
import 'screens/admin/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider()..loadFromStorage(),
      child: const PinjamINApp(),
    ),
  );
}

class PinjamINApp extends StatelessWidget {
  const PinjamINApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PinjamIN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorSchemeSeed: AppConst.primary,
        scaffoldBackgroundColor: AppConst.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(color: AppConst.textPrimary, fontSize: 20, fontWeight: FontWeight.w700),
          iconTheme: IconThemeData(color: AppConst.textPrimary),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const _AuthGate());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeShell());
          case '/detail':
            return MaterialPageRoute(
              builder: (_) => const DetailScreen(),
              settings: settings,
            );
          default:
            return MaterialPageRoute(builder: (_) => const _AuthGate());
        }
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isLoggedIn) {
      if (auth.user?['role'] == 'admin') {
        return const AdminDashboardScreen();
      }
      return const HomeShell();
    }
    return const LoginScreen();
  }
}

// ─── Home Shell dengan Bottom Navigation ──────────────────
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _idx = 0;

  void switchTab(int idx) => setState(() => _idx = idx);

  final _pages = const [
    BerandaScreen(),
    KatalogScreen(),
    RiwayatScreen(),
    NotifikasiScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(child: _pages[_idx]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4))],
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
                _navItem(3, Icons.notifications_rounded, 'Notifikasi'),
                // Logout
                _navLogout(auth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int idx, IconData icon, String label) {
    final active = _idx == idx;
    return GestureDetector(
      onTap: () => setState(() => _idx = idx),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppConst.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: active ? AppConst.primary : AppConst.textSecondary),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w700 : FontWeight.w500, color: active ? AppConst.primary : AppConst.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _navLogout(AuthProvider auth) {
    return GestureDetector(
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Yakin ingin keluar?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
              TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Logout', style: TextStyle(color: AppConst.error))),
            ],
          ),
        );
        if (confirm == true) {
          await auth.logout();
          if (mounted) Navigator.pushReplacementNamed(context, '/login');
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.logout_rounded, size: 24, color: AppConst.error),
            SizedBox(height: 2),
            Text('Keluar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: AppConst.error)),
          ],
        ),
      ),
    );
  }
}
