import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;

import '../../core/api_service.dart';
import '../../core/auth_provider.dart';
import '../../core/constants.dart';
import '../../partials/admin/navbar.dart';
import '../../partials/admin/sidebar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic> _stat = {};
  bool _loading = true;
  String _chartTab = 'Peminjaman';

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/api/beranda/statistik');
      final data = jsonDecode(res.body);
      setState(() => _stat = data['data'] ?? data);
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final nama = auth.user?['nama'] ?? 'Admin';

    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: const AdminNavbar(
        title: 'Dashboard',
      ),
      drawer: const AdminSidebar(activeRoute: 'Dashboard'),
      body: RefreshIndicator(
        onRefresh: _fetch,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                children: [
                  Text('Selamat datang, $nama!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                  const SizedBox(height: 20),
                  
                  // Stat Cards
                  Row(
                    children: [
                      _statCard('Total Barang', '${_stat['total_barang'] ?? 0}', '+12.5%', true, Icons.inventory_2_outlined, const Color(0xFF3B82F6)),
                      const SizedBox(width: 14),
                      _statCard('Tersedia', '${_stat['tersedia'] ?? 0}', '+8.2%', true, Icons.check_circle_outline, const Color(0xFF06B6D4)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _statCard('Dipinjam', '${_stat['dipinjam'] ?? 0}', '-3.1%', false, Icons.swap_horiz_rounded, const Color(0xFFF59E0B)),
                      const SizedBox(width: 14),
                      _statCard('Total Anggota', '2.8K', '+24.7%', true, Icons.people_outline, const Color(0xFF8B5CF6)),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Chart Area
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Overview', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                        const Text('Performa bulanan tahun ini', style: TextStyle(fontSize: 12, color: AppConst.textSecondary)),
                        const SizedBox(height: 16),
                        
                        // Tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: ['Peminjaman', 'Pengembalian', 'Barang'].map((t) {
                              final active = _chartTab == t;
                              return GestureDetector(
                                onTap: () => setState(() => _chartTab = t),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: active ? AppConst.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? Colors.white : AppConst.textSecondary)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Chart
                        SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: CustomPaint(painter: _ChartPainter()),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent Orders
                  const Text('Recent Orders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _recentOrderItem('Ahmad R.', 'PMJ-001', 'Proyektor Epson', 'Disetujui', const Color(0xFF3B82F6), const Color(0xFFDBEAFE)),
                  _recentOrderItem('Siti N.', 'PMJ-002', 'Laptop Asus', 'Menunggu', const Color(0xFFF59E0B), const Color(0xFFFEF3C7)),
                  _recentOrderItem('Budi S.', 'PMJ-003', 'Speaker JBL', 'Diambil', const Color(0xFF8B5CF6), const Color(0xFFEDE9FE)),
                ],
              ),
      ),
    );
  }

  Widget _statCard(String title, String value, String change, bool up, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: AppConst.textSecondary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(up ? Icons.arrow_upward : Icons.arrow_downward, size: 12, color: up ? AppConst.success : AppConst.error),
                const SizedBox(width: 4),
                Text(change, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: up ? AppConst.success : AppConst.error)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _recentOrderItem(String name, String id, String item, String status, Color stColor, Color stBg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppConst.primary.withValues(alpha: 0.1),
            child: Text(name[0], style: const TextStyle(color: AppConst.primary, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppConst.textPrimary)),
                Text('$id • $item', style: const TextStyle(fontSize: 12, color: AppConst.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: stBg, borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: stColor)),
          ),
        ],
      ),
    );
  }

}

// Simple chart painter replicating the web version
class _ChartPainter extends CustomPainter {
  final List<double> data = [8, 12, 10, 18, 24, 22, 28, 34, 30, 38, 42, 48];
  
  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = 50.0;
    
    final paintLine = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
      
    final path = Path();
    final stepX = size.width / (data.length - 1);
    
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final y = size.height - (data[i] / maxVal) * size.height;
      points.add(Offset(x, y));
    }
    
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1];
      final curr = points[i];
      final cpx1 = prev.dx + (curr.dx - prev.dx) * 0.4;
      final cpx2 = prev.dx + (curr.dx - prev.dx) * 0.6;
      path.cubicTo(cpx1, prev.dy, cpx2, curr.dy, curr.dx, curr.dy);
    }
    
    // Fill gradient
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();
    
    final paintFill = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, size.height),
        [const Color(0xFF38BDF8).withValues(alpha: 0.25), const Color(0xFF38BDF8).withValues(alpha: 0.01)],
      );
      
    canvas.drawPath(fillPath, paintFill);
    canvas.drawPath(path, paintLine);
    
    // Draw dots
    final dotPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final dotStroke = Paint()..color = const Color(0xFF38BDF8)..strokeWidth = 2..style = PaintingStyle.stroke;
    for (final p in points) {
      canvas.drawCircle(p, 3, dotPaint);
      canvas.drawCircle(p, 3, dotStroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
