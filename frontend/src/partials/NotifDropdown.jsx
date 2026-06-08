import React, { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate } from 'react-router-dom';
import { authFetch } from '../utils/authFetch';
import './NotifDropdown.css';

const API = 'http://localhost:3000';

function timeAgo(dateStr) {
    if (!dateStr) return '';
    const diff = (Date.now() - new Date(dateStr)) / 1000;
    if (diff < 60)   return 'baru saja';
    if (diff < 3600) return `${Math.floor(diff / 60)} mnt lalu`;
    if (diff < 86400)return `${Math.floor(diff / 3600)} jam lalu`;
    return `${Math.floor(diff / 86400)} hari lalu`;
}

export default function NotifDropdown() {
    const navigate = useNavigate();
    const [open,    setOpen]    = useState(false);
    const [notifs,  setNotifs]  = useState([]);
    const [unread,  setUnread]  = useState(0);
    const [loading, setLoading] = useState(false);
    const dropRef = useRef(null);

    // ── Ambil data notifikasi ──────────────────────────────────────────────────
    const fetchNotifs = useCallback(async () => {
        setLoading(true);
        try {
            const res  = await authFetch(`${API}/notifikasi`);
            const json = await res.json();
            if (json.status === 'success') {
                setNotifs(json.data);
                setUnread(json.unread);
            }
        } catch { /* silent */ }
        finally { setLoading(false); }
    }, []);

    // Polling unread count setiap 30 detik
    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) return;

        const pollCount = async () => {
            try {
                const res  = await authFetch(`${API}/notifikasi/unread-count`);
                const json = await res.json();
                if (json.status === 'success') setUnread(json.unread);
            } catch { /* silent */ }
        };

        pollCount();
        const id = setInterval(pollCount, 30_000);
        return () => clearInterval(id);
    }, []);

    // Tutup dropdown jika klik di luar
    useEffect(() => {
        const handler = (e) => {
            if (dropRef.current && !dropRef.current.contains(e.target)) setOpen(false);
        };
        document.addEventListener('mousedown', handler);
        return () => document.removeEventListener('mousedown', handler);
    }, []);

    // ── Toggle dropdown ────────────────────────────────────────────────────────
    const handleToggle = () => {
        if (!open) fetchNotifs();
        setOpen(prev => !prev);
    };

    // ── Tandai satu sebagai dibaca ─────────────────────────────────────────────
    const markRead = async (id) => {
        setNotifs(prev => prev.map(n =>
            n.id_notifikasi === id ? { ...n, dibaca_at: new Date().toISOString() } : n
        ));
        setUnread(prev => Math.max(0, prev - 1));
        await authFetch(`${API}/notifikasi/${id}/baca`, { method: 'PATCH' }).catch(() => {});
    };

    // ── Tandai satu sebagai dibaca + navigasi ─────────────────────────────────
    const RIWAYAT_KEYWORDS = ['disetujui', 'ditolak', 'selesai', 'terlambat', 'diambil', 'dibatalkan', 'peminjaman', 'pengajuan'];

    const handleNotifClick = async (notif) => {
        // Tandai dibaca jika belum
        if (!notif.dibaca_at) {
            await markRead(notif.id_notifikasi);
        }
        setOpen(false);
        // Cek apakah pesan terkait peminjaman → arahkan ke riwayat
        const pesanLower = (notif.pesan || '').toLowerCase();
        const isRiwayat  = RIWAYAT_KEYWORDS.some(kw => pesanLower.includes(kw));
        if (isRiwayat) {
            const user = JSON.parse(localStorage.getItem('user') || '{}');
            if (user.role === 'admin') {
                navigate('/peminjaman');
            } else {
                navigate('/riwayat-peminjaman');
            }
        }
    };

    // ── Tandai semua dibaca ────────────────────────────────────────────────────
    const markAllRead = async () => {
        setNotifs(prev => prev.map(n => ({ ...n, dibaca_at: n.dibaca_at || new Date().toISOString() })));
        setUnread(0);
        await authFetch(`${API}/notifikasi/baca-semua`, { method: 'PATCH' }).catch(() => {});
    };

    return (
        <div className="nd-wrap" ref={dropRef}>
            {/* ── Bell Button ── */}
            <button
                className="nav-bell"
                aria-label="Notifikasi"
                onClick={handleToggle}
                data-count={unread > 0 ? (unread > 99 ? '99+' : unread) : undefined}
            >
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"
                     strokeLinecap="round" strokeLinejoin="round">
                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                </svg>
            </button>

            {/* ── Dropdown Panel ── */}
            {open && (
                <div className="nd-panel">
                    <div className="nd-header">
                        <span className="nd-title">
                            Notifikasi
                            {unread > 0 && <span className="nd-badge">{unread} baru</span>}
                        </span>
                        {unread > 0 && (
                            <button className="nd-read-all" onClick={markAllRead}>
                                Tandai semua dibaca
                            </button>
                        )}
                    </div>

                    <div className="nd-list">
                        {loading ? (
                            <div className="nd-empty">
                                <span className="nd-spin" />
                                <p>Memuat notifikasi...</p>
                            </div>
                        ) : notifs.length === 0 ? (
                            <div className="nd-empty">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                                    <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/>
                                    <path d="M13.73 21a2 2 0 0 1-3.46 0"/>
                                </svg>
                                <p>Belum ada notifikasi</p>
                            </div>
                        ) : notifs.map(n => (
                            <div
                                key={n.id_notifikasi}
                                className={`nd-item ${!n.dibaca_at ? 'nd-unread' : ''}`}
                                onClick={() => handleNotifClick(n)}
                                style={{ cursor: 'pointer' }}
                            >
                                <div className="nd-dot" />
                                <div className="nd-content">
                                    <p className="nd-msg">{n.pesan}</p>
                                    {n.nama_barang && (
                                        <span className="nd-sub">{n.nama_barang}</span>
                                    )}
                                    <span className="nd-time">{timeAgo(n.created_at)}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            )}
        </div>
    );
}
