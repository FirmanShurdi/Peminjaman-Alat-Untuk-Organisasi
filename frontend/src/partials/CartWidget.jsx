import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import Flash from './Flash';
import BookingModal from '../pages/form/BookingModal';
import './CartWidget.css';

const API = 'http://localhost:3000';

export default function CartWidget() {
    const navigate = useNavigate();
    const [isOpen, setIsOpen] = useState(false);
    const [showBooking, setShowBooking] = useState(false);
    const [cartBookedDates, setCartBookedDates] = useState([]);
    const [loading, setLoading] = useState(false);
    const loadCart = () => JSON.parse(localStorage.getItem('cart') || '[]');
    const [cartItems, setCartItems] = useState(loadCart());
    
    useEffect(() => {
        const handleCartChange = () => {
            setCartItems(loadCart());
        };
        window.addEventListener('cartUpdated', handleCartChange);
        return () => window.removeEventListener('cartUpdated', handleCartChange);
    }, []);
    
    // Mengecek user yang sedang login
    const userStr = localStorage.getItem('user');
    const user = userStr ? JSON.parse(userStr) : null;
    
    // Tampilkan widget HANYA jika user sudah login dan bukan admin (atau disesuaikan role)
    if (!user || user.role === 'admin') return null;

    const toggleCart = () => setIsOpen(!isOpen);

    const removeItem = (id_barang) => {
        const newCart = cartItems.filter(item => item.id_barang !== id_barang);
        setCartItems(newCart);
        localStorage.setItem('cart', JSON.stringify(newCart));
        window.dispatchEvent(new Event('cartUpdated'));
    };

    const handleProses = async () => {
        setLoading(true);
        let allBooked = [];
        try {
            // Ambil data booked dates dari semua barang di keranjang
            for(let item of cartItems) {
                const res = await fetch(`${API}/api/barang/${item.id_barang}/booked-dates`);
                if(res.ok) {
                    const data = await res.json();
                    if(data.status === 'success' && data.data) {
                        allBooked = [...allBooked, ...data.data];
                    }
                }
            }
        } catch(e) {
            console.error(e);
        }
        setCartBookedDates(allBooked);
        setLoading(false);
        setIsOpen(false);
        setShowBooking(true);
    };

    return (
        <>
            {/* Tombol Floating Action (FAB) di pojok kanan bawah */}
            <button className="cart-fab" onClick={toggleCart} title="Lihat Keranjang">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                    <circle cx="9" cy="21" r="1"></circle>
                    <circle cx="20" cy="21" r="1"></circle>
                    <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                </svg>
                {cartItems.length > 0 && <span className="cart-badge">{cartItems.length}</span>}
            </button>

            {/* Overlay background saat keranjang terbuka */}
            <div className={`cart-overlay ${isOpen ? 'open' : ''}`} onClick={toggleCart}></div>
            
            {/* Panel Sidebar Keranjang */}
            <div className={`cart-sidebar ${isOpen ? 'open' : ''}`}>
                <div className="cart-header">
                    <h3>Keranjang Peminjaman</h3>
                    <button className="cart-close" onClick={toggleCart} title="Tutup">&times;</button>
                </div>
                
                <div className="cart-body">
                    {cartItems.length === 0 ? (
                        <div className="cart-empty">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1" strokeLinecap="round" strokeLinejoin="round">
                                <circle cx="9" cy="21" r="1"></circle>
                                <circle cx="20" cy="21" r="1"></circle>
                                <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                            </svg>
                            <p>Keranjang kosong</p>
                            <span>Jelajahi katalog alat dan mulai pinjam!</span>
                        </div>
                    ) : (
                        <div className="cart-items-list">
                            {cartItems.map((item) => (
                                <div className="cart-item" key={item.id_barang}>
                                    <div className="cart-item-img">
                                        {item.gambar ? (
                                            <img src={item.gambar} alt={item.nama_barang} style={{ width: '100%', height: '100%', objectFit: 'cover', borderRadius: '8px' }} />
                                        ) : (
                                            <svg viewBox="0 0 24 24" fill="none" stroke="#94a3b8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" style={{width: '30px', margin: '15px'}}><rect x="3" y="3" width="18" height="18" rx="2" ry="2"></rect><circle cx="8.5" cy="8.5" r="1.5"></circle><polyline points="21 15 16 10 5 21"></polyline></svg>
                                        )}
                                    </div>
                                    <div className="cart-item-info">
                                        <h4>{item.nama_barang}</h4>
                                        <p>Jumlah dipinjam: {item.jumlah}</p>
                                    </div>
                                    <button className="cart-item-del" onClick={() => removeItem(item.id_barang)} title="Hapus">
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" style={{width: '18px'}}><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path></svg>
                                    </button>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
                
                {cartItems.length > 0 && (
                    <div className="cart-footer">
                        <button className="cart-checkout-btn" onClick={handleProses} disabled={loading}>
                            {loading ? 'Memuat...' : `Proses Peminjaman (${cartItems.length} Alat)`}
                        </button>
                    </div>
                )}
            </div>

            {showBooking && (
                <BookingModal
                    isCartMode={true}
                    cartItems={cartItems}
                    bookedDates={cartBookedDates}
                    onClose={() => setShowBooking(false)}
                    onSuccess={(msg) => {
                        setShowBooking(false);
                        localStorage.removeItem('cart');
                        window.dispatchEvent(new Event('cartUpdated'));
                        // Gunakan local flash sebelum navigasi
                        localStorage.setItem('_flash', JSON.stringify({ type: 'success', message: msg }));
                        navigate('/riwayat-peminjaman');
                    }}
                />
            )}
        </>
    );
}
