import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Sidebar from '../../../partials/admin/Sidebar';
import Flash from '../../../partials/Flash';
import AdminNavbar from '../../../partials/admin/AdminNavbar';
import { authFetch } from '../../../utils/authFetch';
import './edit.css';

const API = 'http://localhost:3000';

const STATUS_OPTIONS = [
    { value: 'disetujui', label: 'Setujui', color: '#2563eb' },
    { value: 'ditolak', label: 'Tolak', color: '#dc2626' },
    { value: 'diambil', label: 'Tandai Diambil', color: '#16a34a' },
    { value: 'selesai', label: 'Selesai', color: '#166534' },
    { value: 'terlambat', label: 'Terlambat', color: '#be123c' },
    { value: 'dibatalkan', label: 'Batalkan', color: '#64748b' },
];

const STATUS_COLORS = {
    menunggu: '#92400e', disetujui: '#1d4ed8', diambil: '#15803d',
    terlambat: '#be123c', ditolak: '#dc2626', selesai: '#166534',
    dibatalkan: '#64748b',
};

function fmtDate(d) {
    if (!d) return '-';
    return new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'long', year: 'numeric' });
}
function fmtDT(d) {
    if (!d) return '-';
    return new Date(d).toLocaleString('id-ID', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export default function PeminjamanEdit() {
    const { id } = useParams();
    const navigate = useNavigate();

    const [p, setP] = useState(null);
    const [loading, setLoading] = useState(true);
    const [submitting, setSubmitting] = useState(false);
    const [newStatus, setNewStatus] = useState('');
    const [catatan, setCatatan] = useState('');
    const [buktiFile, setBuktiFile] = useState(null);
    const [toasts, setToasts] = useState([]);

    const addToast = (type, msg) => {
        const id = Date.now();
        setToasts(pr => [...pr, { id, type, message: msg }]);
        setTimeout(() => setToasts(pr => pr.filter(t => t.id !== id)), 4200);
    };
    const removeToast = id => setToasts(pr => pr.filter(t => t.id !== id));

    useEffect(() => {
        fetchDetail();
    }, [id]);

    const fetchDetail = async () => {
        setLoading(true);
        try {
            const res = await authFetch(`${API}/peminjaman/${id}`);
            const json = await res.json();
            if (json.status === 'success') {
                setP(json.data);
                setCatatan(json.data.catatan_admin || '');
            } else {
                addToast('error', json.message);
            }
        } catch {
            addToast('error', 'Gagal memuat detail peminjaman.');
        } finally { setLoading(false); }
    };

    const handleUpdateStatus = async () => {
        if (!newStatus) return addToast('error', 'Pilih status terlebih dahulu.');
        if ((newStatus === 'diambil' || newStatus === 'selesai') && !buktiFile) {
            return addToast('error', `Mohon unggah bukti foto untuk status ${newStatus}.`);
        }
        setSubmitting(true);
        try {
            const formData = new FormData();
            formData.append('status', newStatus);
            if (catatan) formData.append('catatan_admin', catatan);
            if (buktiFile) formData.append('bukti', buktiFile);

            const res = await authFetch(`${API}/peminjaman/${id}/status`, {
                method: 'PATCH',
                body: formData,
            });
            const json = await res.json();
            if (json.status === 'success') {
                // Simpan flash lalu redirect ke halaman daftar
                localStorage.setItem('_flash', JSON.stringify({ type: 'success', message: json.message }));
                navigate('/peminjaman');
            } else {
                addToast('error', json.message);
            }
        } catch {
            addToast('error', 'Terjadi kesalahan jaringan.');
        } finally { setSubmitting(false); }
    };

    if (loading) return (
        <div className="pe-layout">
            <Sidebar />
            <main className="pe-main"><div className="pe-loading">Memuat data...</div></main>
        </div>
    );

    if (!p) return (
        <div className="pe-layout">
            <Sidebar />
            <main className="pe-main"><div className="pe-loading">Data tidak ditemukan.</div></main>
        </div>
    );

    const statusColor = STATUS_COLORS[p.status] || '#64748b';

    return (
        <div className="pe-layout">
            <Flash toasts={toasts} removeToast={removeToast} />
            <Sidebar />
            <main className="pe-main">
                <AdminNavbar
                    title={`Detail Peminjaman #${p.id_peminjaman}`}
                    subtitle="Kelola dan perbarui status pengajuan."
                />

                <div className="pe-content">
                    {/* Baris atas: tombol kembali + badge status */}
                    <div className="pe-topbar">
                        <button className="pe-back" onClick={() => navigate('/peminjaman')}>
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6" /></svg>
                            Kembali ke Daftar
                        </button>
                        <span className="pe-status-badge" style={{ color: statusColor, borderColor: statusColor, background: statusColor + '15' }}>
                            {p.status}
                        </span>
                    </div>

                    {/* ── Info Grid ── */}
                    <div className="pe-grid">
            
                        {/* Kartu: Info Peminjam */}
                        <div className="pe-card">
                            <h3 className="pe-card-title">Informasi Peminjam</h3>
                            <div className="pe-rows">
                                <div className="pe-row"><span>Nama</span><strong>{p.nama_user}</strong></div>
                                <div className="pe-row"><span>Email</span><strong>{p.email}</strong></div>
                                <div className="pe-row"><span>Diajukan</span><strong>{fmtDT(p.created_at)}</strong></div>
                                <div className="pe-row"><span>Catatan User</span><strong>{p.catatan_user || '-'}</strong></div>
                            </div>
                        </div>

                        {/* Kartu: Info Barang */}
                        <div className="pe-card">
                            <h3 className="pe-card-title">Informasi Barang</h3>
                            <div className="pe-rows">
                                <div className="pe-row"><span>Barang</span><strong>{p.nama_barang}</strong></div>
                                <div className="pe-row"><span>Jumlah</span><strong>{p.jumlah} unit</strong></div>
                                <div className="pe-row"><span>Tgl Pinjam</span><strong>{fmtDate(p.tanggal_pinjam)}</strong></div>
                                <div className="pe-row"><span>Tgl Kembali</span><strong>{fmtDate(p.tanggal_kembali)}</strong></div>
                            </div>
                        </div>

                        {/* Kartu: QR Code Verifikasi */}
                        {(p.status === 'disetujui' || p.status === 'diambil') && (() => {
                            const genCode = (id) => ((id * 2654435761) >>> 0).toString(16).substring(0, 6).toUpperCase().padStart(6, '0');
                            const randomCode = `PMJ-${genCode(p.id_peminjaman)}`;
                            return (
                                <div className="pe-card" style={{ textAlign: 'center', background: '#f8fafc', border: '2px dashed #cbd5e1' }}>
                                    <h3 className="pe-card-title" style={{ marginBottom: '8px', textAlign: 'center' }}>QR Code Verifikasi</h3>
                                    <p style={{ fontSize: '13px', color: '#64748b', marginBottom: '16px' }}>
                                        Cocokkan QR Code ini dengan QR Code yang ditunjukkan oleh anggota.
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
                        
                        {/* Kartu: Timeline */}
                        <div className="pe-card">
                            <h3 className="pe-card-title">Timeline Proses</h3>
                            <div className="pe-rows">
                                <div className="pe-row"><span>Verifikasi</span><strong>{fmtDT(p.verified_at)}</strong></div>
                                <div className="pe-row"><span>Diambil</span><strong>{fmtDT(p.picked_at)}</strong></div>
                                <div className="pe-row"><span>Dikembalikan</span><strong>{fmtDT(p.returned_at)}</strong></div>
                                <div className="pe-row"><span>Catatan Admin</span><strong>{p.catatan_admin || '-'}</strong></div>
                            </div>
                        </div>

                        {/* Kartu: Dokumen Bukti */}
                        <div className="pe-card">
                            <h3 className="pe-card-title">Dokumen Bukti</h3>
                            <div className="pe-docs">
                                <a className="pe-doc-link" href={`/${p.bukti_ktm}`} target="_blank" rel="noreferrer">
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>
                                    Lihat KTM
                                </a>
                                <a className="pe-doc-link" href={`/${p.bukti_wajah}`} target="_blank" rel="noreferrer">
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" /></svg>
                                    Lihat Foto Wajah
                                </a>
                                {p.bukti && (
                                    <a className="pe-doc-link" href={`/${p.bukti}`} target="_blank" rel="noreferrer">
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>
                                        Bukti Serah/Terima
                                    </a>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* ── Panel Update Status ── */}
                    <div className="pe-update-card">
                        <h3 className="pe-card-title">Perbarui Status</h3>
                        <div className="pe-status-btns">
                            {STATUS_OPTIONS.map(opt => (
                                <button
                                    key={opt.value}
                                    className={`pe-status-opt ${newStatus === opt.value ? 'selected' : ''}`}
                                    style={newStatus === opt.value ? { background: opt.color, color: '#fff', borderColor: opt.color } : { borderColor: opt.color, color: opt.color }}
                                    onClick={() => setNewStatus(opt.value)}
                                >
                                    {opt.label}
                                </button>
                            ))}
                        </div>
                        <textarea
                            className="pe-catatan"
                            rows={3}
                            placeholder="Catatan admin (opsional)..."
                            value={catatan}
                            onChange={e => setCatatan(e.target.value)}
                        />
                        {(newStatus === 'diambil' || newStatus === 'selesai') && (
                            <div className="pe-bukti-upload" style={{ marginBottom: '16px', background: '#f8fafc', padding: '12px', borderRadius: '8px', border: '1px solid #e2e8f0' }}>
                                <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: '#475569', marginBottom: '8px' }}>
                                    Unggah Bukti Foto ({newStatus === 'diambil' ? 'Pengambilan' : 'Pengembalian'}) *
                                </label>
                                <input
                                    type="file"
                                    accept="image/png, image/jpeg, application/pdf"
                                    onChange={e => setBuktiFile(e.target.files[0])}
                                    style={{ fontSize: '13px', color: '#64748b' }}
                                />
                            </div>
                        )}
                        <button
                            className="pe-submit"
                            onClick={handleUpdateStatus}
                            disabled={!newStatus || submitting}
                        >
                            {submitting ? 'Menyimpan...' : 'Simpan Perubahan'}
                        </button>
                    </div>
                </div>
            </main>
        </div>
    );
}
