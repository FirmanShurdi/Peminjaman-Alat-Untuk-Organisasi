import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';

class AdminNavbar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const AdminNavbar({super.key, required this.title});

  @override
  State<AdminNavbar> createState() => _AdminNavbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AdminNavbarState extends State<AdminNavbar> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUnread();
  }

  Future<void> _fetchUnread() async {
    try {
      final res = await ApiService.get('/notifikasi/unread-count', auth: true);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        if (mounted) setState(() => _unreadCount = data['unread'] ?? 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      centerTitle: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () => _showNotificationPopup(context),
            ),
            if (_unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    _unreadCount > 99 ? '99+' : _unreadCount.toString(),
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
        const SizedBox(width: 8),
      ],
    );
  }



  void _showNotificationPopup(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Stack(
          children: [
            BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
              child: Container(color: Colors.transparent),
            ),
            Align(
              alignment: Alignment.center,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))
                  ]
                ),
                child: const Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: _NotificationList(),
                ),
              ),
            ),
          ],
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return FadeTransition(
          opacity: anim1,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }
}

class _NotificationList extends StatefulWidget {
  const _NotificationList();
  @override
  State<_NotificationList> createState() => _NotificationListState();
}

class _NotificationListState extends State<_NotificationList> {
  List<dynamic> _notif = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final res = await ApiService.get('/notifikasi', auth: true);
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        if (mounted) setState(() => _notif = data['data'] ?? []);
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _markRead(int id) async {
    try {
      await ApiService.patch('/notifikasi/$id/baca', {}, auth: true);
      _fetch();
    } catch (_) {}
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Notifikasi Peminjaman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConst.textPrimary)),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: AppConst.textSecondary),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _notif.isEmpty
                  ? const Center(child: Text('Tidak ada notifikasi', style: TextStyle(color: AppConst.textSecondary)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _notif.length,
                      itemBuilder: (context, index) {
                        final item = _notif[index];
                        final dibaca = item['dibaca_at'] != null;
                        final waktu = item['created_at'] != null 
                            ? _timeAgo(DateTime.parse(item['created_at'])) 
                            : '';
                        
                        return InkWell(
                          onTap: () async {
                            if (!dibaca) await _markRead(item['id_notifikasi']);
                            if (!context.mounted) return;
                            Navigator.pop(context); // close popup
                            Navigator.pushNamed(context, '/admin_peminjaman');
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: dibaca ? Colors.transparent : Colors.blue.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: dibaca ? Border.all(color: AppConst.border) : Border.all(color: AppConst.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: dibaca ? Colors.grey.withValues(alpha: 0.1) : Colors.blue.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.notifications_outlined,
                                    color: dibaca ? Colors.grey : Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['pesan'] ?? '',
                                        style: TextStyle(fontWeight: dibaca ? FontWeight.normal : FontWeight.w600, fontSize: 13, color: AppConst.textPrimary, height: 1.4),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        waktu,
                                        style: const TextStyle(fontSize: 11, color: AppConst.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!dibaca)
                                  Container(
                                    margin: const EdgeInsets.only(top: 6),
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(color: AppConst.primary, shape: BoxShape.circle),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

