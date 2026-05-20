import React, { useState, useEffect, useMemo } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import Navbar from '../partials/Navbar';
import Flash from '../partials/Flash';
import { authFetch, redirectToLogin } from '../utils/authFetch';
import './RiwayatPeminjaman.css';

const API = 'http://localhost:3000';

const STATUS_CONFIG = {
  menunggu:   { label: 'Menunggu',   color: '#f59e0b', bg: '#fef3c7'},
  disetujui:  { label: 'Disetujui',  color: '#3b82f6', bg: '#dbeafe'},
  diambil:    { label: 'Diambil',    color: '#8b5cf6', bg: '#ede9fe'},
  terlambat:  { label: 'Terlambat',  color: '#ef4444', bg: '#fee2e2'},
  selesai:    { label: 'Selesai',    color: '#10b981', bg: '#d1fae5'},
  ditolak:    { label: 'Ditolak',    color: '#6b7280', bg: '#f3f4f6' },
  dibatalkan: { label: 'Dibatalkan', color: '#6b7280', bg: '#f3f4f6' },
};

function StatusBadge({ status }) {
  const cfg = STATUS_CONFIG[status] || { label: status, color: '#6b7280', bg: '#f3f4f6', icon: '•' };
  return (
    <span className="rp-status-badge" style={{ color: cfg.color, background: cfg.bg }}>
      {cfg.icon} {cfg.label}
    </span>
  );
}

function DetailModal({ item, onClose, onCancel }) {
  const [fullscreenImg, setFullscreenImg] = useState(null);

  if (!item) return null;
  const formatDate     = (d) => d ? new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) : '-';
  const formatDateTime  = (d) => d ? new Date(d).toLocaleString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : null;
  
  // Gambar bukti (bukti_ktm, bukti_wajah, bukti)
  const imgBase   = (p) => p ? `${API}/${p}` : null;
  // Gambar barang
  const imgBarang = item.gambar
    ? (item.gambar.startsWith('http') ? item.gambar : `${API}/barang/${item.gambar}`)
    : null;

  return (
    <div className="rp-modal-backdrop" onClick={onClose}>
      {fullscreenImg && (
        <div className="rp-fs-overlay" onClick={(e) => { e.stopPropagation(); setFullscreenImg(null); }}>
          <button className="rp-fs-close" onClick={() => setFullscreenImg(null)}>✕</button>
          <img src={fullscreenImg} alt="Fullscreen Bukti" className="rp-fs-img" onClick={e => e.stopPropagation()} />
        </div>
      )}
      <div className="rp-modal-box" onClick={e => e.stopPropagation()}>

        {/* ── Header dengan foto barang ── */}
        <div className="rp-modal-header">
          <div className="rp-modal-hd-img">
            {imgBarang
              ? <img src={imgBarang} alt={item.nama_barang} onError={e => e.target.style.display = 'none'} />
              : <span>📦</span>
            }
          </div>
          <div className="rp-modal-hd-info">
            <h2 className="rp-modal-name">{item.nama_barang}</h2>
            <StatusBadge status={item.status} />
          </div>
          <button className="rp-modal-close" onClick={onClose}>✕</button>
        </div>

        <div className="rp-modal-body">

          {/* ── Catatan Admin ── */}
          {item.catatan_admin && (
            <div className="rp-catatan-admin">
              <span>📝 Catatan Admin:</span>
              <p>{item.catatan_admin}</p>
            </div>
          )}

          {/* ── Detail Peminjaman ── */}
          <div className="rp-modal-section">
            <h3>Detail Peminjaman</h3>
            <div className="rp-detail-grid">
              <div className="rp-detail-item">
                <span>Jumlah Dipinjam</span>
                <strong>{item.jumlah} unit</strong>
              </div>
              <div className="rp-detail-item">
                <span>📅 Tanggal Pinjam</span>
                <strong>{formatDate(item.tanggal_pinjam)}</strong>
              </div>
              <div className="rp-detail-item">
                <span>📅 Tanggal Kembali</span>
                <strong>{formatDate(item.tanggal_kembali)}</strong>
              </div>
              <div className="rp-detail-item">
                <span>Tanggal Pengajuan</span>
                <strong>{formatDate(item.created_at)}</strong>
              </div>
              {formatDateTime(item.verified_at) && (
                <div className="rp-detail-item">
                  <span>Disetujui Pada</span>
                  <strong>{formatDateTime(item.verified_at)}</strong>
                </div>
              )}
              {formatDateTime(item.picked_at) && (
                <div className="rp-detail-item rp-detail-highlight">
                  <span>📦 Diambil Pada</span>
                  <strong>{formatDateTime(item.picked_at)}</strong>
                </div>
              )}
              {formatDateTime(item.returned_at) && (
                <div className="rp-detail-item rp-detail-highlight-green">
                  <span>🎉 Dikembalikan Pada</span>
                  <strong>{formatDateTime(item.returned_at)}</strong>
                </div>
              )}
            </div>
            {item.catatan_user && (
              <div className="rp-catatan-user">
                <span>Catatan Keperluan:</span>
                <p>{item.catatan_user}</p>
              </div>
            )}
          </div>

          {/* ── Barcode Pengambilan/Pengembalian ── */}
          {(item.status === 'disetujui' || item.status === 'diambil') && (() => {
            const genCode = (id) => ((id * 2654435761) >>> 0).toString(16).substring(0, 6).toUpperCase().padStart(6, '0');
            const randomCode = `PMJ-${genCode(item.id_peminjaman)}`;
            return (
            <div className="rp-modal-section" style={{ textAlign: 'center', background: '#f8fafc', padding: '24px 20px', borderRadius: '12px', marginBottom: '24px', border: '2px dashed #cbd5e1' }}>
              <h3 style={{ marginBottom: '8px', color: '#0f172a', fontSize: '16px' }}>Kode Verifikasi Peminjaman</h3>
              <p style={{ fontSize: '13px', color: '#64748b', marginBottom: '16px' }}>
                Tunjukkan QR Code ini kepada admin saat mengambil atau mengembalikan barang.
              </p>
              <div style={{ background: '#fff', padding: '16px', borderRadius: '8px', display: 'inline-block', boxShadow: '0 2px 4px rgba(0,0,0,0.05)' }}>
                <img 
                  src={`https://api.qrserver.com/v1/create-qr-code/?size=160x160&data=${randomCode}&margin=0`} 
                  alt={`QR Code ${randomCode}`}
                  style={{ width: '140px', height: '140px', display: 'block', margin: '0 auto' }}
                />
              </div>
              <p style={{ marginTop: '12px', fontSize: '14px', fontWeight: 'bold', color: '#334155', letterSpacing: '1px' }}>
                {randomCode}
              </p>
            </div>
            );
          })()}

          {/* ── Bukti Dokumen Anggota ── */}
          <div className="rp-modal-section">
            <h3>Bukti Dokumen Anggota</h3>
            <div className="rp-bukti-row">
              {imgBase(item.bukti_ktm) ? (
                <div className="rp-bukti-item rp-bukti-clickable" onClick={() => setFullscreenImg(imgBase(item.bukti_ktm))}>
                  <p>📄 KTM / Identitas</p>
                  <div className="rp-bukti-icon-box">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/><path d="M8 14h.01"/><path d="M12 14h.01"/><path d="M16 14h.01"/><path d="M8 18h.01"/><path d="M12 18h.01"/><path d="M16 18h.01"/></svg>
                    <span>Lihat Foto KTM</span>
                  </div>
                </div>
              ) : (
                <div className="rp-bukti-empty">Belum ada foto KTM</div>
              )}
              {imgBase(item.bukti_wajah) ? (
                <div className="rp-bukti-item rp-bukti-clickable" onClick={() => setFullscreenImg(imgBase(item.bukti_wajah))}>
                  <p>📸 Foto Selfie</p>
                  <div className="rp-bukti-icon-box">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
                    <span>Lihat Foto Selfie</span>
                  </div>
                </div>
              ) : (
                <div className="rp-bukti-empty">Belum ada foto selfie</div>
              )}
            </div>
          </div>

          {/* ── Bukti Serah Terima Admin (diambil/selesai) ── */}
          {imgBase(item.bukti) && (
            <div className="rp-modal-section">
              <h3>
                {item.status === 'selesai' ? '✅ Bukti Pengembalian' : '📦 Bukti Pengambilan'}
              </h3>
              <div className="rp-bukti-row">
                <div className="rp-bukti-item rp-bukti-admin rp-bukti-clickable" onClick={() => setFullscreenImg(imgBase(item.bukti))}>
                  <p>Bukti dari Admin</p>
                  <div className="rp-bukti-icon-box" style={{ borderColor: '#8b5cf6', background: '#f5f3ff' }}>
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#8b5cf6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="12" y1="18" x2="12" y2="12"/><line x1="9" y1="15" x2="15" y2="15"/></svg>
                    <span style={{ color: '#6d28d9' }}>Lihat Bukti Admin</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ── Action Pembatalan ── */}
          {item.status === 'menunggu' && onCancel && (
            <div className="rp-modal-section" style={{ borderTop: '1px solid #e5e7eb', paddingTop: '16px', marginTop: '16px', display: 'flex', justifyContent: 'flex-end' }}>
              <button 
                onClick={() => onCancel(item.id_peminjaman)} 
                style={{ 
                  background: '#fee2e2', color: '#ef4444', border: '1px solid #fca5a5',
                  padding: '8px 16px', borderRadius: '6px', fontWeight: 'bold', cursor: 'pointer',
                  display: 'flex', alignItems: 'center', gap: '8px', transition: 'all 0.2s'
                }}
                onMouseEnter={e => { e.currentTarget.style.background = '#fecaca'; e.currentTarget.style.borderColor = '#ef4444'; }}
                onMouseLeave={e => { e.currentTarget.style.background = '#fee2e2'; e.currentTarget.style.borderColor = '#fca5a5'; }}
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>
                Batalkan Pengajuan
              </button>
            </div>
          )}

        </div>
      </div>
    </div>
  );
}

export default function RiwayatPeminjaman() {
  const navigate = useNavigate();
  const user = useMemo(() => {
    try { return JSON.parse(localStorage.getItem('user') || 'null'); } catch { return null; }
  }, []);

  const [list, setList] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filterStatus, setFilterStatus] = useState('semua');
  const [selectedItem, setSelectedItem] = useState(null);
  const [toasts, setToasts] = useState([]);

  const addToast = (type, message) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4500);
  };
  const removeToast = (id) => setToasts(prev => prev.filter(t => t.id !== id));

  useEffect(() => {
    if (!user) {
      redirectToLogin('Silakan login untuk melihat riwayat peminjaman.');
      return;
    }
    window.scrollTo(0, 0);
    fetchRiwayat();
  }, []);

  const fetchRiwayat = async () => {
    setLoading(true);
    try {
      const res = await authFetch(`${API}/api/peminjaman/milik-saya`);
      const data = await res.json();
      if (data.status === 'success') {
        setList(data.data);
      } else {
        addToast('error', data.message || 'Gagal memuat riwayat.');
      }
    } catch (err) {
      addToast('error', 'Gagal terhubung ke server.');
    }
    setLoading(false);
  };

  const filtered = filterStatus === 'semua' ? list : list.filter(p => p.status === filterStatus);

  const formatDate = (d) => d ? new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) : '-';

  const counts = useMemo(() => {
    const c = { semua: list.length };
    Object.keys(STATUS_CONFIG).forEach(s => { c[s] = list.filter(p => p.status === s).length; });
    return c;
  }, [list]);

  const handleCancelPeminjaman = async (id_peminjaman) => {
    if (!window.confirm('Apakah Anda yakin ingin membatalkan pengajuan ini? Tindakan ini tidak dapat diurungkan.')) return;

    try {
      const res = await authFetch(`${API}/api/peminjaman/${id_peminjaman}/batal`, { method: 'PATCH' });
      const data = await res.json();
      if (res.ok) {
        addToast('success', data.message || 'Pengajuan berhasil dibatalkan.');
        setSelectedItem(null);
        fetchRiwayat();
      } else {
        addToast('error', data.message || 'Gagal membatalkan pengajuan.');
      }
    } catch (err) {
      addToast('error', 'Terjadi kesalahan koneksi saat membatalkan.');
    }
  };

  return (
    <div className="rp-page">
      <Navbar user={user} currentSection={-1} goTo={() => {}} onFlash={addToast} />
      <Flash toasts={toasts} removeToast={removeToast} />
      {selectedItem && (
        <DetailModal 
          item={selectedItem} 
          onClose={() => setSelectedItem(null)} 
          onCancel={handleCancelPeminjaman}
        />
      )}

      <div className="rp-container">
        {/* Header */}
        <div className="rp-header">
          <button className="rp-back-btn" onClick={() => navigate(-1)}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="19" y1="12" x2="5" y2="12"/><polyline points="12 19 5 12 12 5"/></svg>
            Kembali
          </button>
          <div className="rp-title-group">
            <h1>Riwayat Peminjaman</h1>
            <p>Total <strong>{counts.semua}</strong> pengajuan</p>
          </div>
          <div className="rp-header-actions">
            <div className="rp-select-wrap">
              <select
                id="filter-status"
                className="rp-select"
                value={filterStatus}
                onChange={e => setFilterStatus(e.target.value)}
              >
                <option value="semua">Semua Status ({counts.semua})</option>
                {Object.entries(STATUS_CONFIG).map(([key, cfg]) => (
                  <option key={key} value={key}>
                    {cfg.icon} {cfg.label} ({counts[key] || 0})
                  </option>
                ))}
              </select>
              <svg className="rp-select-arrow" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="6 9 12 15 18 9"/></svg>
            </div>
            <button className="rp-refresh-btn" onClick={fetchRiwayat} title="Refresh">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="23 4 23 10 17 10"/><polyline points="1 20 1 14 7 14"/><path d="M3.51 9a9 9 0 0 1 14.85-3.36L23 10M1 14l4.64 4.36A9 9 0 0 0 20.49 15"/></svg>
            </button>
          </div>
        </div>


        {/* Content */}
        {loading ? (
          <div className="rp-loader">
            <div className="rp-spinner" />
            <p>Memuat riwayat peminjaman...</p>
          </div>
        ) : filtered.length === 0 ? (
          <div className="rp-empty">
            <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="#cbd5e1" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>
            <h3>{filterStatus === 'semua' ? 'Belum ada pengajuan' : `Tidak ada peminjaman dengan status "${STATUS_CONFIG[filterStatus]?.label}"`}</h3>
            <p>{filterStatus === 'semua' ? 'Mulai pinjam alat dari halaman katalog.' : 'Coba filter status lain.'}</p>
            {filterStatus === 'semua' && (
              <Link to="/daftarbarang" className="rp-btn-catalog">Lihat Katalog Barang</Link>
            )}
          </div>
        ) : (
          <div className="rp-list">
            {filtered.map(item => {
              const cfg = STATUS_CONFIG[item.status] || STATUS_CONFIG.menunggu;
              return (
                <div key={item.id_peminjaman} className="rp-card" onClick={() => setSelectedItem(item)}>
                  <div className="rp-card-img">
                    {item.gambar ? (
                      <img src={item.gambar.startsWith('http') ? item.gambar : `${API}/barang/${item.gambar}`} alt={item.nama_barang} />
                    ) : (
                      <div className="rp-card-no-img"></div>
                    )}
                  </div>
                  <div className="rp-card-body">
                    <div className="rp-card-top">
                      <h3 className="rp-card-name">{item.nama_barang}</h3>
                      <StatusBadge status={item.status} />
                    </div>
                    <div className="rp-card-meta">
                      <span>📅 {formatDate(item.tanggal_pinjam)} – {formatDate(item.tanggal_kembali)}</span>
                      <span><strong> {item.jumlah} unit </strong></span>
                      <span>🕐 Diajukan {formatDate(item.created_at)}</span>
                    </div>
                    {item.catatan_admin && (
                      <p className="rp-card-catatan">💬 {item.catatan_admin}</p>
                    )}
                  </div>
                  <div className="rp-card-arrow">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><polyline points="9 18 15 12 9 6"/></svg>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
