import React, { useState, useEffect, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../../../partials/admin/Sidebar';
import Flash from '../../../partials/Flash';
import AdminNavbar from '../../../partials/admin/AdminNavbar';
import { authFetch } from '../../../utils/authFetch';
import './Peminjaman.css';

const API = 'http://localhost:3000';

const STATUS_COLORS = {
    menunggu:   { bg: '#fffbeb', text: '#92400e', border: '#fde68a' },
    disetujui:  { bg: '#eff6ff', text: '#1d4ed8', border: '#bfdbfe' },
    diambil:    { bg: '#f0fdf4', text: '#15803d', border: '#bbf7d0' },
    terlambat:  { bg: '#fff1f2', text: '#be123c', border: '#fecdd3' },
    ditolak:    { bg: '#fef2f2', text: '#dc2626', border: '#fecaca' },
    selesai:    { bg: '#f0fdf4', text: '#166534', border: '#86efac' },
    selesai_terlambat: { bg: '#fee2e2', text: '#b91c1c', border: '#fecaca' },
    dibatalkan: { bg: '#f8fafc', text: '#64748b', border: '#e2e8f0' },
};

function StatusBadge({ status }) {
    const c = STATUS_COLORS[status] || STATUS_COLORS.menunggu;
    const label = status === 'selesai_terlambat' ? 'selesai (terlambat)' : status;
    return (
        <span style={{
            display: 'inline-block',
            padding: '3px 10px',
            borderRadius: '999px',
            fontSize: '11px',
            fontWeight: 700,
            background: c.bg,
            color: c.text,
            border: `1px solid ${c.border}`,
            textTransform: 'capitalize',
        }}>{label}</span>
    );
}

function fmtDate(d) {
    if (!d) return '-';
    return new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
}

export default function Peminjaman() {
    const navigate = useNavigate();

    const [data,        setData]        = useState([]);
    const [loading,     setLoading]     = useState(true);
    const [search,      setSearch]      = useState('');
    const [filterStatus,setFilterStatus]= useState('');
    const [currentPage, setCurrentPage] = useState(1);
    const [toasts,      setToasts]      = useState([]);
    const ITEMS = 10;

    const addToast = (type, msg) => {
        const id = Date.now();
        setToasts(p => [...p, { id, type, message: msg }]);
        setTimeout(() => setToasts(p => p.filter(t => t.id !== id)), 4200);
    };
    const removeToast = id => setToasts(p => p.filter(t => t.id !== id));

    // Baca flash dari redirect (misal setelah update status di edit.jsx)
    useEffect(() => {
        try {
            const raw = localStorage.getItem('_flash');
            if (raw) {
                const flash = JSON.parse(raw);
                localStorage.removeItem('_flash');
                setTimeout(() => addToast(flash.type, flash.message), 200);
            }
        } catch (_) {}
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    useEffect(() => { fetchData(); }, []);

    const fetchData = async () => {
        setLoading(true);
        try {
            const res  = await authFetch(`${API}/peminjaman`);
            const json = await res.json();
            if (json.status === 'success') setData(json.data);
        } catch (e) {
            addToast('error', 'Gagal memuat data peminjaman.');
        } finally { setLoading(false); }
    };

    const handleDelete = async (id) => {
        if (!window.confirm('Apakah Anda yakin ingin menghapus data peminjaman ini secara permanen?')) return;
        
        try {
            const res = await authFetch(`${API}/peminjaman/${id}`, { method: 'DELETE' });
            const json = await res.json();
            if (json.status === 'success') {
                addToast('success', json.message);
                fetchData();
            } else {
                addToast('error', json.message || 'Gagal menghapus data.');
            }
        } catch (e) {
            addToast('error', 'Terjadi kesalahan jaringan.');
        }
    };

    const processed = useMemo(() => {
        return data.filter(p => {
            const q = search.toLowerCase();
            const matchSearch = !q ||
                p.nama_user?.toLowerCase().includes(q) ||
                p.nama_barang?.toLowerCase().includes(q) ||
                String(p.id_peminjaman).includes(q);
            const matchStatus = !filterStatus || p.status === filterStatus;
            return matchSearch && matchStatus;
        });
    }, [data, search, filterStatus]);

    const totalPages  = Math.ceil(processed.length / ITEMS);
    const currentData = useMemo(() => {
        const s = (currentPage - 1) * ITEMS;
        return processed.slice(s, s + ITEMS);
    }, [processed, currentPage]);


    return (
        <div className="pm-layout">
            <Flash toasts={toasts} removeToast={removeToast} />
            <Sidebar />
            <main className="pm-main">
                <AdminNavbar title="Daftar Peminjaman" subtitle="Kelola semua pengajuan peminjaman barang." />

                <div className="pm-content">
                    {/* Stats bar */}
                    <div className="pm-stats">
                        {['menunggu','disetujui','diambil','terlambat','selesai', 'selesai_terlambat'].map(s => (
                            <div
                                key={s}
                                className={`pm-stat-card ${filterStatus === s ? 'active' : ''}`}
                                onClick={() => { setFilterStatus(filterStatus === s ? '' : s); setCurrentPage(1); }}
                            >
                                <span className="pm-stat-num">{data.filter(p => p.status === s).length}</span>
                                <span className="pm-stat-label">{s === 'selesai_terlambat' ? 'Selesai (Terlambat)' : s.charAt(0).toUpperCase() + s.slice(1)}</span>
                            </div>
                        ))}
                    </div>

                    <div className="pm-card">
                        {/* Toolbar */}
                        <div className="pm-toolbar">
                            <div className="pm-search-wrap">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                                <input
                                    type="text"
                                    placeholder="Cari peminjam, barang, atau ID..."
                                    value={search}
                                    onChange={e => { setSearch(e.target.value); setCurrentPage(1); }}
                                />
                            </div>
                            <select
                                className="pm-select"
                                value={filterStatus}
                                onChange={e => { setFilterStatus(e.target.value); setCurrentPage(1); }}
                            >
                                <option value="">Semua Status</option>
                                {Object.keys(STATUS_COLORS).map(s => (
                                    <option key={s} value={s}>{s === 'selesai_terlambat' ? 'Selesai (Terlambat)' : s.charAt(0).toUpperCase() + s.slice(1)}</option>
                                ))}
                            </select>
                        </div>

                        {/* Table */}
                        <div className="pm-table-wrap">
                            <table className="pm-table">
                                <thead>
                                    <tr>
                                        <th>No.</th>
                                        <th>ID</th>
                                        <th>Kode</th>
                                        <th>Peminjam</th>
                                        <th>Barang</th>
                                        <th>Jml</th>
                                        <th>Tgl Pinjam</th>
                                        <th>Tgl Kembali</th>
                                        <th>Status</th>
                                        <th>Verifikator</th>
                                        <th>Diajukan</th>
                                        <th>Aksi</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    {loading ? (
                                        <tr><td colSpan="12" className="pm-empty">Memuat data...</td></tr>
                                    ) : currentData.length === 0 ? (
                                        <tr><td colSpan="12" className="pm-empty">Tidak ada data peminjaman.</td></tr>
                                    ) : currentData.map((p, i) => {
                                        const genCode = (id) => ((id * 2654435761) >>> 0).toString(16).substring(0, 6).toUpperCase().padStart(6, '0');
                                        const randomCode = p.no_pesanan ? `PMJ-${p.no_pesanan}` : `PMJ-${genCode(p.id_peminjaman)}`;
                                        
                                        // Pengecekan apakah data ini termasuk dalam satu keranjang yang sama
                                        const isGrouped = p.no_pesanan && currentData.filter(x => x.no_pesanan === p.no_pesanan).length > 1;
                                        const isFirstInGroup = isGrouped && (i === 0 || currentData[i - 1].no_pesanan !== p.no_pesanan);
                                        const isLastInGroup = isGrouped && (i === currentData.length - 1 || currentData[i + 1].no_pesanan !== p.no_pesanan);
                                        
                                        let trClass = '';
                                        if (isGrouped) {
                                            trClass = 'pm-row-grouped';
                                            if (isFirstInGroup) trClass += ' pm-group-first';
                                            if (isLastInGroup) trClass += ' pm-group-last';
                                        }
                                        
                                        return (
                                        <tr key={p.id_peminjaman} className={trClass}>
                                            <td>{processed.length - ((currentPage - 1) * ITEMS) - i}</td>
                                            <td className="pm-id">ID: {p.id_peminjaman}</td>
                                            <td style={{ fontWeight: 'bold', color: '#475569', letterSpacing: '0.5px' }}>{randomCode}</td>
                                            <td className="pm-bold">{p.nama_user}</td>
                                            <td>{p.nama_barang}</td>
                                            <td style={{ textAlign: 'center' }}>{p.jumlah}</td>
                                            <td>{fmtDate(p.tanggal_pinjam)}</td>
                                            <td>{fmtDate(p.tanggal_kembali)}</td>
                                            <td><StatusBadge status={p.status} /></td>
                                            <td style={{ fontSize: '13px', fontWeight: '500', color: p.nama_verifikator ? '#0f172a' : '#94a3b8' }}>
                                                {p.nama_verifikator ? `${p.nama_verifikator} ID${p.id_verifikasi}` : '-'}
                                            </td>
                                            <td>{fmtDate(p.created_at)}</td>
                                            <td>
                                                <div style={{ display: 'flex', gap: '8px' }}>
                                                    <button
                                                        className="pm-btn-detail"
                                                        style={{ background: '#3b82f6', color: '#fff', border: 'none' }}
                                                        onClick={() => navigate(`/peminjaman/${p.id_peminjaman}`)}
                                                    >
                                                        Detail
                                                    </button>
                                                    <button
                                                        className="pm-btn-detail"
                                                        style={{ background: '#ef4444', color: '#fff', border: 'none' }}
                                                        onClick={() => handleDelete(p.id_peminjaman)}
                                                    >
                                                        Hapus
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                        );
                                    })}
                                </tbody>
                            </table>
                        </div>

                        {/* Pagination */}
                        <div className="pm-pagination">
                            <span className="pm-page-info">
                                {currentData.length > 0
                                    ? `${(currentPage - 1) * ITEMS + 1}–${Math.min(currentPage * ITEMS, processed.length)} dari ${processed.length} entri`
                                    : '0 entri'}
                            </span>
                            <div className="pm-page-controls">
                                <button className="page-btn" disabled={currentPage === 1} onClick={() => setCurrentPage(p => p - 1)}>Prev</button>
                                {Array.from({ length: totalPages }, (_, i) => i + 1).map(pg => (
                                    <button key={pg} className={`page-btn ${currentPage === pg ? 'active' : ''}`} onClick={() => setCurrentPage(pg)}>{pg}</button>
                                ))}
                                <button className="page-btn" disabled={currentPage === totalPages || totalPages === 0} onClick={() => setCurrentPage(p => p + 1)}>Next</button>
                            </div>
                        </div>
                    </div>
                </div>
            </main>
        </div>
    );
}
