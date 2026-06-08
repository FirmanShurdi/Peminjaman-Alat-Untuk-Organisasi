import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../main.dart';

class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});
  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  List<dynamic> _data = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.get('/notifikasi', auth: true);
      final json = jsonDecode(res.body);
      setState(() => _data = json['data'] ?? []);
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService.patch('/notifikasi/$id/baca', {}, auth: true);
      _fetch();
    } catch (_) {}
  }

  Future<void> _markAllRead() async {
    try {
      await ApiService.patch('/notifikasi/baca-semua', {}, auth: true);
      _fetch();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final unread = _data.where((n) => n['dibaca_at'] == null).length;

    return Scaffold(
      backgroundColor: AppConst.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetch,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppConst.textPrimary),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Notifikasi', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppConst.textPrimary)),
                                  Text('$unread belum dibaca', style: const TextStyle(color: AppConst.textSecondary, fontSize: 14)),
                                ],
                              ),
                            ),
                          GestureDetector(
                            onTap: _markAllRead,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppConst.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.done_all_rounded, size: 16, color: AppConst.primary),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Baca Semua',
                                    style: TextStyle(
                                      color: AppConst.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                _data.isEmpty
                    ? const SliverFillRemaining(child: Center(child: Text('Belum ada notifikasi.', style: TextStyle(color: AppConst.textSecondary))))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) => _notifTile(_data[i]),
                            childCount: _data.length,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _notifTile(dynamic n) {
    final dibaca = n['dibaca_at'] != null;
    final waktu = n['created_at'] != null ? _timeAgo(DateTime.parse(n['created_at'])) : '';

    return GestureDetector(
      onTap: () async {
        if (!dibaca) await _markRead(n['id_notifikasi']);
        if (!mounted) return;
        Navigator.pop(context);
        homeShellKey.currentState?.switchTab(2);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: dibaca ? Colors.white : const Color(0xFFF0F7FF),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
          border: dibaca ? null : Border.all(color: AppConst.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: dibaca ? AppConst.bg : AppConst.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.notifications_outlined, size: 20, color: dibaca ? AppConst.textSecondary : AppConst.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n['pesan'] ?? '', style: TextStyle(fontSize: 13, fontWeight: dibaca ? FontWeight.normal : FontWeight.w600, color: AppConst.textPrimary, height: 1.4)),
                  const SizedBox(height: 4),
                  Text(waktu, style: const TextStyle(fontSize: 11, color: AppConst.textSecondary)),
                ],
              ),
            ),
            if (!dibaca)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: AppConst.primary, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
