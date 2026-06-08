import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/cart_provider.dart';
import '../../partials/flash_message.dart';
import '../../main.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final bool _loading = false;

  void _removeItem(dynamic idBarang) {
    context.read<CartProvider>().removeItem(idBarang);
  }

  void _checkout() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      FlashMessage.show(context, 'Keranjang kosong!', isSuccess: false);
      return;
    }

    // In the real app, we need to show the booking modal/screen. 
    // For now, we will notify the user that they should proceed to checkout.
    // Assuming you have a checkout screen, you would navigate to it.
    // If not, we can just show a dialog.
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildCheckoutSheet(ctx, cart),
    );
  }

  Widget _buildCheckoutSheet(BuildContext ctx, CartProvider cart) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Konfirmasi Peminjaman', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Anda akan meminjam ${cart.itemCount} barang sekaligus. Lanjutkan proses pengisian form peminjaman?', style: const TextStyle(fontSize: 14, color: AppConst.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final res = await Navigator.pushNamed(context, '/book', arguments: {
                'isCart': true,
                'cartItems': cart.items,
              });
              if (res == true && mounted) {
                cart.clearCart();
                homeShellKey.currentState?.switchTab(2);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppConst.primary, foregroundColor: Colors.white, padding: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Lanjut Isi Form', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: AppConst.textSecondary)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final items = cart.items;

    return Scaffold(
      backgroundColor: AppConst.bg,
      appBar: AppBar(
        title: const Text('Keranjang Peminjaman'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Keranjang masih kosong', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConst.textPrimary)),
                  const SizedBox(height: 8),
                  const Text('Silakan pilih alat terlebih dahulu di Katalog', style: TextStyle(color: AppConst.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (ctx, i) {
                final item = items[i];
                final imgUrl = (item['gambar'] != null && item['gambar'] != '')
                    ? '${AppConst.imageBaseUrl}/barang/${item['gambar']}'
                    : null;
                
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/detail', arguments: item['id_barang']),
                  child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConst.border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 70,
                          height: 70,
                          color: AppConst.bg,
                          child: imgUrl != null 
                              ? Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.inventory_2))
                              : const Icon(Icons.inventory_2, color: AppConst.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['nama_barang'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 4),
                            Text('Kategori: ${item['nama_kategori'] ?? 'Umum'}', style: const TextStyle(fontSize: 12, color: AppConst.primary)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppConst.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Jumlah: ${item['jumlah'] ?? 1} Unit', 
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppConst.primaryDark),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _removeItem(item['id_barang']),
                        icon: const Icon(Icons.delete_outline, color: AppConst.error),
                      )
                    ],
                  ),
                ),
              );
              },
            ),
      bottomNavigationBar: items.isEmpty ? null : Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: _loading ? null : _checkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConst.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _loading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Proses ${items.length} Barang', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
