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
  selesai_terlambat: { label: 'Selesai (Terlambat)', color: '#b91c1c', bg: '#fee2e2' },
  ditolak:    { label: 'Ditolak',    color: '#6b7280', bg: '#f3f4f6' },
  dibatalkan: { label: 'Dibatalkan', color: '#6b7280', bg: '#f3f4f6' },
  bermasalah: { label: 'Bermasalah', color: '#be123c', bg: '#ffe4e6' },
};

function StatusBadge({ status }) {
  const cfg = STATUS_CONFIG[status] || { label: status, color: '#6b7280', bg: '#f3f4f6', icon: '•' };
  return (
    <span className="rp-status-badge" style={{ color: cfg.color, background: cfg.bg }}>
      {cfg.icon} {cfg.label}
    </span>
  );
}

function DetailModal({ item, user, onClose, onCancel, onUploadMasalah }) {
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
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.8)', zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }} onClick={() => setFullscreenImg(null)}>
            <div style={{ position: 'relative', width: '100%', maxWidth: '800px', maxHeight: '90vh', background: '#fff', borderRadius: '12px', overflow: 'hidden', display: 'flex', flexDirection: 'column', boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)' }} onClick={e => e.stopPropagation()}>
                <div style={{ padding: '12px 20px', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#f8fafc' }}>
                    <h3 style={{ margin: 0, fontSize: '16px', color: '#1e293b', fontWeight: '600' }}>Pratinjau Dokumen</h3>
                    <button onClick={() => setFullscreenImg(null)} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: '#64748b', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '4px', borderRadius: '4px' }} onMouseEnter={(e) => e.target.style.background = '#e2e8f0'} onMouseLeave={(e) => e.target.style.background = 'transparent'}>
                        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ pointerEvents: 'none' }}><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                    </button>
                </div>
                <div style={{ flex: 1, overflow: 'auto', padding: '20px', textAlign: 'center', background: '#e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    {fullscreenImg.toLowerCase().endsWith('.pdf') ? (
                        <iframe src={fullscreenImg} style={{ width: '100%', height: '70vh', border: 'none', borderRadius: '8px', background: '#fff' }} title="Pratinjau PDF" />
                    ) : (
                        <img src={fullscreenImg} alt="Pratinjau Dokumen" style={{ maxWidth: '100%', maxHeight: '70vh', objectFit: 'contain', borderRadius: '8px', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)' }} />
                    )}
                </div>
                <div style={{ padding: '12px 20px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', background: '#fff' }}>
                    <a href={fullscreenImg} target="_blank" rel="noreferrer" style={{ textDecoration: 'none', background: '#2563eb', color: '#fff', padding: '8px 16px', borderRadius: '6px', fontSize: '14px', fontWeight: '500', display: 'flex', alignItems: 'center', gap: '8px', transition: 'background 0.2s' }} onMouseEnter={(e) => e.target.style.background = '#1d4ed8'} onMouseLeave={(e) => e.target.style.background = '#2563eb'}>
                        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                        Buka di Tab Baru
                    </a>
                </div>
            </div>
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
          {(item.status === 'disetujui' || item.status === 'diambil' || item.status === 'terlambat') && (() => {
            const genCode = (id) => ((id * 2654435761) >>> 0).toString(16).substring(0, 6).toUpperCase().padStart(6, '0');
            const randomCode = item.no_pesanan ? `PMJ-${item.no_pesanan}` : `PMJ-${genCode(item.id_peminjaman)}`;
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
              {imgBase(item.surat_permohonan) ? (
                <div className="rp-bukti-item rp-bukti-clickable" onClick={() => setFullscreenImg(imgBase(item.surat_permohonan))}>
                  <p>📝 Surat Permohonan</p>
                  <div className="rp-bukti-icon-box">
                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#3b82f6" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
                    <span>Lihat Surat</span>
                  </div>
                </div>
              ) : (
                <div className="rp-bukti-empty">Belum ada surat permohonan</div>
              )}
            </div>
          </div>

          {/* ── Bukti Serah Terima Admin (diambil/selesai) ── */}
          {/* ── Bukti Serah Terima Admin (diambil/selesai) ── */}
          {imgBase(item.bukti) && (
            <div className="rp-modal-section">
              <h3>
                {item.status === 'selesai' ? '✅ Bukti Pengembalian' : (item.status === 'bermasalah' && item.bukti.includes('penyelesaian') ? '✅ Bukti Penyelesaian Anda' : '📦 Bukti Pengambilan')}
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

          {/* ── Action Penyelesaian Bermasalah ── */}
          {item.status === 'bermasalah' && (
            <div className="rp-modal-section" style={{ background: '#fff1f2', border: '1px solid #fecdd3', borderRadius: '12px', padding: '16px' }}>
              <h3 style={{ color: '#be123c', marginBottom: '12px' }}>Tindakan Diperlukan</h3>
              {item.jenis_denda === 'denda' ? (
                <>
                  <p style={{ fontSize: '13px', color: '#881337', marginBottom: '12px' }}>
                    Admin mengkonfirmasi denda sebesar <strong>Rp. {item.nominal_denda ? item.nominal_denda.toLocaleString('id-ID') : 0}</strong> untuk barang {item.nama_barang}. Harap menyelesaikan pembayaran ke QRIS berikut dan hubungi Admin untuk konfirmasi.
                  </p>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginBottom: '16px' }}>
                    <div 
                      onClick={() => setFullscreenImg(`${API}/QR/Qris.jpeg`)}
                      style={{ textAlign: 'center', background: '#fff', padding: '12px', borderRadius: '8px', border: '1px solid #fecaca', cursor: 'pointer', transition: 'transform 0.2s', boxShadow: '0 2px 4px rgba(0,0,0,0.05)' }}
                      onMouseEnter={(e) => e.currentTarget.style.transform = 'scale(1.02)'}
                      onMouseLeave={(e) => e.currentTarget.style.transform = 'scale(1)'}
                      title="Klik untuk melihat Qris layar penuh"
                    >
                      <img 
                        src={`${API}/QR/Qris.jpeg`} 
                        alt="QRIS Pembayaran" 
                        style={{ width: '150px', height: '150px', objectFit: 'contain' }}
                        onError={(e) => {
                          e.target.style.display = 'none';
                          e.target.parentElement.innerHTML = '<div style="width: 150px; height: 150px; display: flex; align-items: center; justify-content: center; color: #64748b; font-size: 12px; text-align: center;">[Gambar QRIS Admin]</div>';
                        }}
                      />
                    </div>
                    <div style={{ color: '#be123c', fontWeight: 'bold', fontSize: '14px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                      <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round" style={{ transform: 'translateX(-2px)' }}><path d="M19 12H5"/><path d="M12 19l-7-7 7-7"/></svg>
                      klik
                    </div>
                  </div>
                </>
              ) : (
                <p style={{ fontSize: '13px', color: '#881337', marginBottom: '16px' }}>
                  Admin mengkonfirmasi untuk mengganti barang {item.nama_barang} dengan jumlah {item.jumlah_ganti || 1} pcs. Harap menyerahkannya segera ke admin.
                </p>
              )}
              
              {item.catatan_admin && (
                <div style={{ background: '#fff1f2', borderLeft: '3px solid #e11d48', padding: '8px 12px', marginBottom: '16px', borderRadius: '4px' }}>
                  <p style={{ fontSize: '12px', margin: 0, color: '#9f1239' }}>
                    <strong>Note:</strong> {item.catatan_admin}
                  </p>
                </div>
              )}

              <a 
                href={`https://wa.me/6283119127384?text=${encodeURIComponent(`saya ${user?.nama || 'user'} ingin menyerahkan pengembalian barang ${item.nama_barang} berjumlah ${item.jenis_denda === 'denda' ? `Rp. ${item.nominal_denda ? item.nominal_denda.toLocaleString('id-ID') : 0}` : `${item.jumlah_ganti || 1} pcs`}, mohon konfirmasikan untuk tempat pengembaliannya`)}`}
                target="_blank"
                rel="noreferrer"
                style={{
                  display: 'inline-flex', alignItems: 'center', gap: '8px',
                  background: '#3383c0ff', color: '#fff', padding: '8px 16px', borderRadius: '6px',
                  textDecoration: 'none', fontSize: '14px', fontWeight: 'bold'
                }}
              >
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><path d="M21 11.5a8.38 8.38 0 0 1-.9 3.8 8.5 8.5 0 0 1-7.6 4.7 8.38 8.38 0 0 1-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 0 1-.9-3.8 8.5 8.5 0 0 1 4.7-7.6 8.38 8.38 0 0 1 3.8-.9h.5a8.48 8.48 0 0 1 8 8v.5z"/></svg>
                Hubungi Admin
              </a>
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

  // Pop global flash (e.g. from Cart/Detail redirect)
  useEffect(() => {
    try {
      const raw = localStorage.getItem('_flash');
      if (raw) {
        const flash = JSON.parse(raw);
        localStorage.removeItem('_flash');
        addToast(flash.type, flash.message);
      }
    } catch (_) {}
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

  const handleUploadBuktiMasalah = async (id_peminjaman, file) => {
    try {
      const fd = new FormData();
      fd.append('bukti', file);
      
      const res = await authFetch(`${API}/api/peminjaman/${id_peminjaman}/upload-bukti-masalah`, {
        method: 'PATCH',
        body: fd
      });
      const data = await res.json();
      if (res.ok) {
        addToast('success', data.message || 'Bukti berhasil diunggah.');
        setSelectedItem(null);
        fetchRiwayat();
      } else {
        addToast('error', data.message || 'Gagal mengunggah bukti.');
      }
    } catch (err) {
      addToast('error', 'Terjadi kesalahan koneksi.');
    }
  };

  return (
    <div className="rp-page">
      <Navbar user={user} currentSection={-1} goTo={() => {}} onFlash={addToast} />
      <Flash toasts={toasts} removeToast={removeToast} />
      {selectedItem && (
        <DetailModal 
          item={selectedItem}
          user={user} 
          onClose={() => setSelectedItem(null)} 
          onCancel={handleCancelPeminjaman}
          onUploadMasalah={handleUploadBuktiMasalah}
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
            {filtered.map((item, i) => {
              const cfg = STATUS_CONFIG[item.status] || STATUS_CONFIG.menunggu;
              
              const isGrouped = item.no_pesanan && filtered.filter(x => x.no_pesanan === item.no_pesanan).length > 1;
              const isFirstInGroup = isGrouped && (i === 0 || filtered[i - 1].no_pesanan !== item.no_pesanan);
              const isLastInGroup = isGrouped && (i === filtered.length - 1 || filtered[i + 1].no_pesanan !== item.no_pesanan);

              return (
                <div key={item.id_peminjaman} style={{ display: 'flex', alignItems: 'stretch' }}>
                  {isGrouped && (
                    <div style={{ width: '24px', position: 'relative', display: 'flex', justifyContent: 'center', flexShrink: 0, marginRight: '10px' }}>
                      {!isFirstInGroup && <div style={{ position: 'absolute', top: '-6px', bottom: '50%', width: '2.5px', background: 'rgba(59, 130, 246, 0.5)' }} />}
                      {!isLastInGroup && <div style={{ position: 'absolute', top: '50%', bottom: '-6px', width: '2.5px', background: 'rgba(59, 130, 246, 0.5)' }} />}
                      <div style={{ position: 'absolute', top: '50%', transform: 'translateY(-50%)', width: '10px', height: '10px', borderRadius: '50%', border: '2.5px solid #3b82f6', background: 'white', zIndex: 1 }} />
                    </div>
                  )}
                  <div className="rp-card" onClick={() => setSelectedItem(item)} style={{ flex: 1, minWidth: 0 }}>
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
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
    