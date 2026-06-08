import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import Navbar from '../partials/Navbar';
import Flash from '../partials/Flash';
import './Beranda.css'; // Reuse card CSS
import './DaftarBarang.css';

const API = 'http://localhost:3000';

export default function DaftarBarang() {
  const user = JSON.parse(localStorage.getItem('user') || 'null');
  
  const [barangList, setBarangList] = useState([]);
  const [kategoriList, setKategoriList] = useState([]);
  const [activeKategori, setActiveKategori] = useState('Semua');
  const [loading, setLoading] = useState(true);
  const [toasts, setToasts] = useState([]);
  const [qtyModal, setQtyModal] = useState({ show: false, item: null, qty: 1 });

  const addToast = (type, message) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4500);
  };
  const removeToast = (id) => setToasts(prev => prev.filter(t => t.id !== id));

  useEffect(() => {
    window.scrollTo(0, 0);
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const [resBarang, resKategori] = await Promise.all([
        fetch(`${API}/api/barang`),
        fetch(`${API}/api/barang/kategori`)
      ]);
      const dataBarang = await resBarang.json();
      const dataKategori = await resKategori.json();

      if (dataBarang.status === 'success') {
        setBarangList(dataBarang.data);
      }
      if (dataKategori.status === 'success') {
        setKategoriList(dataKategori.data);
      }
    } catch (error) {
      console.error('Error fetching data:', error);
      addToast('error', 'Gagal memuat katalog barang');
    }
    setLoading(false);
  };

  const filteredBarang = activeKategori === 'Semua' 
    ? barangList 
    : barangList.filter(b => b.nama_kategori === activeKategori);

  return (
    <div className="daftar-barang-page">
      <Navbar user={user} currentSection={-1} goTo={() => {}} onFlash={addToast} />
      <Flash toasts={toasts} removeToast={removeToast} />

      <div className="db-container">
        <div className="db-header">
          <div className="db-badge">Katalog Lengkap</div>
          <h1 className="db-title">Eksplorasi <span>Inventaris Kami</span></h1>
          <p className="db-desc">Temukan berbagai alat operasional dan perlengkapan premium yang siap mendukung segala kebutuhan kegiatan organisasi Anda.</p>
        </div>

        {loading ? (
          <div className="db-loader">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><line x1="12" y1="2" x2="12" y2="6"></line><line x1="12" y1="18" x2="12" y2="22"></line><line x1="4.93" y1="4.93" x2="7.76" y2="7.76"></line><line x1="16.24" y1="16.24" x2="19.07" y2="19.07"></line><line x1="2" y1="12" x2="6" y2="12"></line><line x1="18" y1="12" x2="22" y2="12"></line><line x1="4.93" y1="19.07" x2="7.76" y2="16.24"></line><line x1="16.24" y1="7.76" x2="19.07" y2="4.93"></line></svg>
            Memuat Katalog...
          </div>
        ) : (
          <>
            <div className="db-tabs">
              <button 
                className={`db-tab ${activeKategori === 'Semua' ? 'active' : ''}`}
                onClick={() => setActiveKategori('Semua')}
              >
                Semua Kategori
              </button>
              {kategoriList.map(k => (
                <button 
                  key={k.id_kategori}
                  className={`db-tab ${activeKategori === k.nama_kategori ? 'active' : ''}`}
                  onClick={() => setActiveKategori(k.nama_kategori)}
                >
                  {k.nama_kategori}
                </button>
              ))}
            </div>

            {filteredBarang.length > 0 ? (
              <div className="db-grid">
                {filteredBarang.map((b, i) => (
                  <div key={b.id_barang || i} className="barang-card">
                    <div className="bc-img-wrap">
                      <img src={b.gambar ? `${API}/barang/${b.gambar}` : `${API}/intro/step1.png`} alt={b.nama_barang} onError={(e) => e.target.src = `${API}/intro/step1.png`} />
                      <span className="bc-kondisi">{b.kondisi}</span>
                    </div>
                    <div className="bc-body">
                      <div className="bc-kat">
                        <span>{b.nama_kategori || 'Alat Umum'}</span>
                        <span className="bc-kat-badge">Premium</span>
                      </div>
                      <h4 className="bc-nama">{b.nama_barang}</h4>
                      <div className="bc-stok">
                        <span className="bc-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg></span> 
                        Sisa Stok: <strong>{b.stok}</strong> Unit
                      </div>
                      <div className="bc-lokasi">
                        <span className="bc-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg></span> 
                        {b.lokasi || 'Gudang Utama'}
                      </div>
                    </div>
                    <div className="bc-foot" style={{ display: 'flex', flexDirection: 'row', gap: '10px' }}>
                      <Link to={`/detail/${b.id_barang}`} className="btn-pinjam-sm" style={{ flex: 1 }}>Lihat Detail & Pinjam</Link>
                      {user && user.role !== 'admin' && (
                          <button 
                              className="btn-add-cart-sm"
                              title="Tambahkan ke Keranjang"
                              disabled={b.stok <= 0}
                              onClick={(e) => {
                                  e.preventDefault();
                                  setQtyModal({ show: true, item: b, qty: 1 });
                              }}
                          >
                              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ width: '18px', height: '18px' }}>
                                  <circle cx="9" cy="21" r="1"></circle>
                                  <circle cx="20" cy="21" r="1"></circle>
                                  <path d="M1 1h4l2.68 13.39a2 2 0 0 0 2 1.61h9.72a2 2 0 0 0 2-1.61L23 6H6"></path>
                                  <line x1="11" y1="9" x2="17" y2="9"></line>
                                  <line x1="14" y1="6" x2="14" y2="12"></line>
                              </svg>
                          </button>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            ) : (
              <div className="db-empty">
                Belum ada barang di kategori ini.
              </div>
            )}
          </>
        )}
      </div>

      {/* Modal Kuantitas Keranjang */}
      {qtyModal.show && qtyModal.item && (
          <div className="qty-modal-overlay" onClick={() => setQtyModal({ show: false, item: null, qty: 1 })}>
              <div className="qty-modal-box" onClick={e => e.stopPropagation()}>
                  <div className="qty-modal-header">
                      <h3>Masukkan ke Keranjang</h3>
                      <button onClick={() => setQtyModal({ show: false, item: null, qty: 1 })}>&times;</button>
                  </div>
                  <div className="qty-modal-body">
                      <p>Berapa banyak <strong>{qtyModal.item.nama_barang}</strong> yang ingin dipinjam?</p>
                      <div className="qty-counter">
                          <button onClick={() => setQtyModal(p => ({ ...p, qty: Math.max(1, p.qty - 1) }))}>-</button>
                          <span>{qtyModal.qty}</span>
                          <button onClick={() => setQtyModal(p => ({ ...p, qty: Math.min(qtyModal.item.stok, p.qty + 1) }))}>+</button>
                      </div>
                      <span className="qty-stok">Sisa Stok: {qtyModal.item.stok}</span>
                  </div>
                  <div className="qty-modal-footer">
                      <button 
                          className="btn-tambah-keranjang"
                          onClick={() => {
                              const cart = JSON.parse(localStorage.getItem('cart') || '[]');
                              const existing = cart.find(x => x.id_barang === qtyModal.item.id_barang);
                              if(existing) {
                                  if(existing.jumlah + qtyModal.qty > qtyModal.item.stok) {
                                      addToast('error', `Stok tidak cukup. Anda sudah ada ${existing.jumlah} di keranjang.`);
                                      return;
                                  }
                                  existing.jumlah += qtyModal.qty;
                              } else {
                                  const imgPath = qtyModal.item.gambar ? (qtyModal.item.gambar.startsWith('http') ? qtyModal.item.gambar : `${API}/barang/${qtyModal.item.gambar}`) : null;
                                  cart.push({ id_barang: qtyModal.item.id_barang, nama_barang: qtyModal.item.nama_barang, gambar: imgPath, jumlah: qtyModal.qty, stok: qtyModal.item.stok });
                              }
                              localStorage.setItem('cart', JSON.stringify(cart));
                              window.dispatchEvent(new Event('cartUpdated'));
                              addToast('success', `${qtyModal.qty} ${qtyModal.item.nama_barang} masuk keranjang!`);
                              setQtyModal({ show: false, item: null, qty: 1 });
                          }}
                      >
                          Tambah ke Keranjang
                      </button>
                  </div>
              </div>
          </div>
      )}
    </div>
  );
}
