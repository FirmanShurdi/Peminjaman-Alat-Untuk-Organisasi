import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants.dart';
import 'core/auth_provider.dart';
import 'core/cart_provider.dart';
import 'core/api_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/beranda/beranda_screen.dart';
import 'screens/katalog/katalog_screen.dart';
import 'screens/katalog/detail_screen.dart';
import 'screens/katalog/cart_screen.dart';
import 'screens/riwayat/riwayat_screen.dart';
import 'screens/admin/dashboard_screen.dart';
import 'screens/admin/peminjaman/peminjaman_screen.dart';
import 'screens/admin/peminjaman/edit_screen.dart';
import 'screens/admin/barang/barang_screen.dart';
import 'screens/admin/barang/tambah.dart';
import 'screens/admin/barang/edit.dart';
import 'screens/admin/users/user_screen.dart';
import 'screens/admin/users/tambah.dart';
import 'screens/admin/users/edit.dart';
import 'screens/admin/verif/verif_screen.dart';
import 'screens/book/book_screen.dart';
import 'partials/sidebar.dart';

final GlobalKey<HomeShellState> homeShellKey = GlobalKey<HomeShellState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const PinjamINApp(),
    ),
  );
}

class PinjamINApp extends StatefulWidget {
  const PinjamINApp({super.key});

  @override
  State<PinjamINApp> createState() => _PinjamINAppState();
}

class _PinjamINAppState extends State<PinjamINApp> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  Future<void> _initAuth() async {
    final auth = context.read<AuthProvider>();
    final cart = context.read<CartProvider>();
    
    await auth.loadFromStorage();
    await cart.loadCart();
    
    if (mounted) {
      setState(() => _loaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PinjamIN',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConst.primary,
        scaffoldBackgroundColor: AppConst.bg,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: AppConst.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: AppConst.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
          iconTheme: IconThemeData(color: AppConst.textPrimary),
        ),
      ),
      home: _loaded ? const _AuthGate() : const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/home': (_) => HomeShell(key: homeShellKey),
        '/detail': (_) => const DetailScreen(),
        '/cart': (_) => const CartScreen(),
        '/book': (_) => const BookScreen(),
        '/admin': (_) => const AdminGuard(child: AdminDashboardScreen()),
        '/admin_barang': (_) => const AdminGuard(child: AdminBarangScreen()),
        '/admin_barang_tambah': (_) => const AdminGuard(child: AdminBarangTambahScreen()),
        '/admin_barang_edit': (context) {
          final id = ModalRoute.of(context)?.settings.arguments?.toString() ?? '';
          return AdminGuard(child: AdminBarangEditScreen(idBarang: id));
        },
        '/admin_peminjaman': (_) => const AdminGuard(child: AdminPeminjamanScreen()),
        '/admin_verif': (_) => const AdminGuard(child: AdminVerifScreen()),
        '/admin_peminjaman_edit': (context) {
          final id = ModalRoute.of(context)?.settings.arguments?.toString() ?? '';
          return AdminGuard(child: AdminPeminjamanEditScreen(idPeminjaman: id));
        },
        '/admin_users': (_) => const AdminGuard(child: AdminUserScreen()),
        '/admin_users_tambah': (_) => const AdminGuard(child: AdminUserTambahScreen()),
        '/admin_users_edit': (context) {
          final id = ModalRoute.of(context)?.settings.arguments?.toString() ?? '';
          return AdminGuard(child: AdminUserEditScreen(idUser: id));
        },
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn && auth.user?['role'] == 'admin') {
      return const AdminDashboardScreen();
    }
    
    // For normal users or non-logged-in users, show the HomeShell
    return HomeShell(key: homeShellKey);
  }
}

class AdminGuard extends StatelessWidget {
  final Widget child;
  const AdminGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoggedIn && auth.user?['role'] == 'admin') {
      return child;
    }
    
    // User biasa mencoba mengakses rute admin, kita lempar UI akses ditolak
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akses Ditolak'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.security, size: 80, color: AppConst.error),
            const SizedBox(height: 16),
            const Text(
              'Akses Ditolak',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConst.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Halaman ini hanya dapat diakses oleh Admin.',
              style: TextStyle(color: AppConst.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              style: ElevatedButton.styleFrom(backgroundColor: AppConst.primary),
              child: const Text('Kembali ke Beranda', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => HomeShellState();
}

class HomeShellState extends State<HomeShell> {
  int _idx = 0;
  int _unreadNotifCount = 0;
  Timer? _notifTimer;

  final _pages = const [
    BerandaScreen(),
    KatalogScreen(),
    RiwayatScreen(),
    CartScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fetchUnread();
    _notifTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchUnread());
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
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

  void switchTab(int index) {
    if (index >= 0 && index < _pages.length) {
      setState(() => _idx = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    final cart = context.watch<CartProvider>();
    final cartItemCount = cart.itemCount;

    return Scaffold(
      body: SafeArea(child: _pages[_idx]),
      bottomNavigationBar: Sidebar(
        currentIndex: _idx,
        onTap: switchTab,
        cartItemCount: cartItemCount,
        auth: auth,
      ),
    );
  }
}