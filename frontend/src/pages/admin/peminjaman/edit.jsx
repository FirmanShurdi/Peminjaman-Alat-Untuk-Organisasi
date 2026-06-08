import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Sidebar from '../../../partials/admin/Sidebar';
import Flash from '../../../partials/Flash';
import AdminNavbar from '../../../partials/admin/AdminNavbar';
import { authFetch } from '../../../utils/authFetch';
import './edit.css';

const API = 'http://localhost:3000';

const STATUS_OPTIONS = [
    { value: 'menunggu', label: 'Kembalikan ke Menunggu', color: '#92400e' },
    { value: 'disetujui', label: 'Setujui', color: '#2563eb' },
    { value: 'ditolak', label: 'Tolak', color: '#dc2626' },
    { value: 'diambil', label: 'Tandai Diambil', color: '#16a34a' },
    { value: 'bermasalah', label: 'Bermasalah', color: '#7c3aed' },
    { value: 'selesai', label: 'Selesai', color: '#166534' },
    { value: 'terlambat', label: 'Terlambat', color: '#be123c' },
    { value: 'dibatalkan', label: 'Batalkan', color: '#64748b' },
];

const STATUS_COLORS = {
    menunggu: '#92400e', disetujui: '#1d4ed8', diambil: '#15803d',
    terlambat: '#be123c', ditolak: '#dc2626', selesai: '#166534',
    selesai_terlambat: '#b91c1c', dibatalkan: '#64748b', bermasalah: '#7c3aed',
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
    const [jenisDenda, setJenisDenda] = useState('');
    const [nominalDenda, setNominalDenda] = useState('');
    const [jumlahGanti, setJumlahGanti] = useState('');
    const [buktiFile, setBuktiFile] = useState(null);
    const [previewImage, setPreviewImage] = useState(null);
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
        if (newStatus === 'bermasalah' && !jenisDenda) {
            return addToast('error', 'Silakan pilih jenis penyelesaian untuk barang bermasalah.');
        }
        if (newStatus === 'bermasalah' && jenisDenda === 'denda' && !nominalDenda) {
            return addToast('error', 'Masukkan nominal denda.');
        }
        if (newStatus === 'bermasalah' && jenisDenda === 'penggantian' && !jumlahGanti) {
            return addToast('error', 'Masukkan jumlah barang pengganti.');
        }

        setSubmitting(true);
        try {
            const formData = new FormData();
            formData.append('status', newStatus);
            if (catatan) formData.append('catatan_admin', catatan);
            if (newStatus === 'bermasalah' && jenisDenda) {
                formData.append('jenis_denda', jenisDenda);
                if (jenisDenda === 'denda') formData.append('nominal_denda', nominalDenda);
                if (jenisDenda === 'penggantian') formData.append('jumlah_ganti', jumlahGanti);
            }
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
                        <span className="pe-status-badge" style={{ color: statusColor, borderColor: statusColor, background: statusColor + '15', textTransform: 'capitalize' }}>
                            {p.status === 'selesai_terlambat' ? 'Selesai (Terlambat)' : p.status}
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
                            const randomCode = p.no_pesanan ? `PMJ-${p.no_pesanan}` : `PMJ-${genCode(p.id_peminjaman)}`;
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
                                <button className="pe-doc-link" onClick={() => setPreviewImage(`${API}/${p.bukti_ktm}`)} style={{ border: 'none', background: 'transparent', cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left' }}>
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>
                                    Lihat KTM
                                </button>
                                <button className="pe-doc-link" onClick={() => setPreviewImage(`${API}/${p.bukti_wajah}`)} style={{ border: 'none', background: 'transparent', cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left' }}>
                                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="3" width="18" height="18" rx="2" /><circle cx="8.5" cy="8.5" r="1.5" /><polyline points="21 15 16 10 5 21" /></svg>
                                    Lihat Foto Wajah
                                </button>
                                {p.surat_permohonan && (
                                    <button className="pe-doc-link" onClick={() => setPreviewImage(`${API}/${p.surat_permohonan}`)} style={{ border: 'none', background: 'transparent', cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left' }}>
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>
                                        Lihat Surat Permohonan
                                    </button>
                                )}
                                {p.bukti && (
                                    <button className="pe-doc-link" onClick={() => setPreviewImage(`${API}/${p.bukti}`)} style={{ border: 'none', background: 'transparent', cursor: 'pointer', fontFamily: 'inherit', textAlign: 'left' }}>
                                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" /><polyline points="14 2 14 8 20 8" /></svg>
                                        Bukti Serah/Terima
                                    </button>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* ── Panel Update Status ── */}
                    <div className="pe-update-card">
                        <h3 className="pe-card-title">Perbarui Status</h3>
                        <div className="pe-status-btns">
                            {STATUS_OPTIONS.filter(opt => {
                                const ALLOWED_TRANSITIONS = {
                                    'menunggu': ['disetujui', 'ditolak'],
                                    'disetujui': ['diambil', 'menunggu', 'dibatalkan'], 
                                    'diambil': ['selesai', 'terlambat', 'disetujui', 'bermasalah'],
                                    'terlambat': ['selesai', 'diambil', 'bermasalah'],
                                    'bermasalah': ['selesai'],
                                    'selesai': ['diambil', 'bermasalah'],
                                    'selesai_terlambat': ['diambil'],
                                    'ditolak': ['menunggu'],
                                    'dibatalkan': ['menunggu']
                                };
                                
                                if (opt.value !== p.status && (!ALLOWED_TRANSITIONS[p.status] || !ALLOWED_TRANSITIONS[p.status].includes(opt.value))) {
                                    return false;
                                }

                                return true;
                            }).map(opt => (
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
                        {newStatus === 'bermasalah' && (
                            <div style={{ marginBottom: '16px', background: '#f5f3ff', padding: '12px', borderRadius: '8px', border: '1px solid #ddd6fe' }}>
                                <label style={{ display: 'block', fontSize: '13px', fontWeight: '600', color: '#4c1d95', marginBottom: '8px' }}>
                                    Pilih Jenis Penyelesaian *
                                </label>
                                <select 
                                    value={jenisDenda} 
                                    onChange={(e) => setJenisDenda(e.target.value)}
                                    style={{ width: '100%', padding: '10px', borderRadius: '6px', border: '1px solid #c4b5fd', background: '#fff', color: '#475569', fontSize: '14px', outline: 'none' }}
                                >
                                    <option value="" disabled>-- Pilih Opsi Penyelesaian --</option>
                                    <option value="penggantian">Penggantian Barang</option>
                                    <option value="denda">Denda (QRIS)</option>
                                </select>
                                {jenisDenda === 'denda' && (
                                    <div style={{ marginTop: '12px' }}>
                                        <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#4c1d95', marginBottom: '4px' }}>Nominal Denda (Rp)</label>
                                        <input 
                                            type="number" 
                                            value={nominalDenda} 
                                            onChange={e => setNominalDenda(e.target.value)}
                                            style={{ width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #c4b5fd', background: '#fff', color: '#475569', fontSize: '13px', outline: 'none' }}
                                            placeholder="Contoh: 50000"
                                        />
                                        <p style={{ fontSize: '12px', color: '#6d28d9', marginTop: '8px', fontStyle: 'italic' }}>
                                            * Anggota akan diminta membayar denda melalui kode QRIS yang tersedia pada sistem.
                                        </p>
                                    </div>
                                )}
                                {jenisDenda === 'penggantian' && (
                                    <div style={{ marginTop: '12px' }}>
                                        <label style={{ display: 'block', fontSize: '12px', fontWeight: '600', color: '#4c1d95', marginBottom: '4px' }}>Jumlah Barang yang Diganti (Unit)</label>
                                        <input 
                                            type="number" 
                                            value={jumlahGanti} 
                                            onChange={e => setJumlahGanti(e.target.value)}
                                            style={{ width: '100%', padding: '8px', borderRadius: '6px', border: '1px solid #c4b5fd', background: '#fff', color: '#475569', fontSize: '13px', outline: 'none' }}
                                            placeholder="Contoh: 1"
                                            min="1"
                                            max={p.jumlah}
                                        />
                                    </div>
                                )}
                            </div>
                        )}
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
                                {!buktiFile ? (
                                    <div style={{ display: 'flex', gap: '10px', marginTop: '8px' }}>
                                        <label style={{ flex: 1, textAlign: 'center', background: '#eff6ff', border: '1px solid #bfdbfe', color: '#2563eb', padding: '10px', borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: '600' }}>
                                            📷 Buka Kamera
                                            <input
                                                type="file"
                                                accept="image/*"
                                                capture="environment"
                                                onChange={e => e.target.files && setBuktiFile(e.target.files[0])}
                                                style={{ display: 'none' }}
                                            />
                                        </label>
                                        <label style={{ flex: 1, textAlign: 'center', background: '#f8fafc', border: '1px solid #e2e8f0', color: '#475569', padding: '10px', borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: '600' }}>
                                            📁 Pilih File
                                            <input
                                                type="file"
                                                accept="image/*"
                                                onChange={e => e.target.files && setBuktiFile(e.target.files[0])}
                                                style={{ display: 'none' }}
                                            />
                                        </label>
                                    </div>
                                ) : (
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                                        <div style={{ position: 'relative', cursor: 'pointer', borderRadius: '8px', overflow: 'hidden', border: '1px solid #cbd5e1' }} onClick={() => setPreviewImage(URL.createObjectURL(buktiFile))}>
                                            <img 
                                                src={URL.createObjectURL(buktiFile)} 
                                                alt="Preview Upload" 
                                                style={{ width: '80px', height: '80px', objectFit: 'cover', display: 'block' }} 
                                            />
                                            <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: 'rgba(0,0,0,0.6)', color: '#fff', fontSize: '10px', textAlign: 'center', padding: '4px 0' }}>Lihat Penuh</div>
                                        </div>
                                        <div>
                                            <p style={{ fontSize: '13px', fontWeight: '500', color: '#334155', margin: '0 0 6px 0', wordBreak: 'break-all' }}>{buktiFile.name}</p>
                                            <button 
                                                type="button" 
                                                onClick={() => setBuktiFile(null)} 
                                                style={{ background: '#fee2e2', color: '#ef4444', border: '1px solid #fca5a5', borderRadius: '4px', padding: '4px 8px', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer' }}
                                            >
                                                Hapus / Ganti Foto
                                            </button>
                                        </div>
                                    </div>
                                )}
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

            {/* Modal Pratinjau Dokumen */}
            {previewImage && (
                <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.8)', zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '20px' }}>
                    <div style={{ position: 'relative', width: '100%', maxWidth: '800px', maxHeight: '90vh', background: '#fff', borderRadius: '12px', overflow: 'hidden', display: 'flex', flexDirection: 'column', boxShadow: '0 25px 50px -12px rgba(0, 0, 0, 0.25)' }}>
                        <div style={{ padding: '12px 20px', borderBottom: '1px solid #e2e8f0', display: 'flex', justifyContent: 'space-between', alignItems: 'center', background: '#f8fafc' }}>
                            <h3 style={{ margin: 0, fontSize: '16px', color: '#1e293b', fontWeight: '600' }}>Pratinjau Dokumen</h3>
                            <button onClick={() => setPreviewImage(null)} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: '#64748b', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: '4px', borderRadius: '4px' }} onMouseEnter={(e) => e.target.style.background = '#e2e8f0'} onMouseLeave={(e) => e.target.style.background = 'transparent'}>
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" style={{ pointerEvents: 'none' }}><line x1="18" y1="6" x2="6" y2="18"></line><line x1="6" y1="6" x2="18" y2="18"></line></svg>
                            </button>
                        </div>
                        <div style={{ flex: 1, overflow: 'auto', padding: '20px', textAlign: 'center', background: '#e2e8f0', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                            {previewImage.toLowerCase().endsWith('.pdf') ? (
                                <iframe src={previewImage} style={{ width: '100%', height: '70vh', border: 'none', borderRadius: '8px', background: '#fff' }} title="Pratinjau PDF" />
                            ) : (
                                <img src={previewImage} alt="Pratinjau Dokumen" style={{ maxWidth: '100%', maxHeight: '70vh', objectFit: 'contain', borderRadius: '8px', boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1)' }} />
                            )}
                        </div>
                        <div style={{ padding: '12px 20px', borderTop: '1px solid #e2e8f0', display: 'flex', justifyContent: 'flex-end', background: '#fff' }}>
                            <a href={previewImage} target="_blank" rel="noreferrer" style={{ textDecoration: 'none', background: '#2563eb', color: '#fff', padding: '8px 16px', borderRadius: '6px', fontSize: '14px', fontWeight: '500', display: 'flex', alignItems: 'center', gap: '8px', transition: 'background 0.2s' }} onMouseEnter={(e) => e.target.style.background = '#1d4ed8'} onMouseLeave={(e) => e.target.style.background = '#2563eb'}>
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path><polyline points="7 10 12 15 17 10"></polyline><line x1="12" y1="15" x2="12" y2="3"></line></svg>
                                Buka di Tab Baru
                            </a>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
