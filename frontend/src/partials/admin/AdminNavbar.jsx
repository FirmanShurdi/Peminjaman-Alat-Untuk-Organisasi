import React, { useState } from 'react';
import { useTheme } from '../../App';
import NotifDropdown from '../NotifDropdown';
import VerifModal from '../../pages/admin/verif';
import './AdminNavbar.css';

/**
 * AdminNavbar — header reusable untuk semua halaman dashboard admin.
 *
 * Props:
 *  - title    {string}  judul halaman (contoh: "Dashboard")
 *  - subtitle {string}  subjudul/deskripsi (opsional)
 */
export default function AdminNavbar({ title, subtitle }) {
    const { dark, toggleTheme } = useTheme();
    const [showVerif, setShowVerif] = useState(false);
    
    const user = JSON.parse(localStorage.getItem('user') || '{}');
    const initial = (user.nama || 'A').charAt(0).toUpperCase();

    return (
        <header className="an-header">
            <div className="an-left">
                <h1 className="an-title">{title}</h1>
                {subtitle && <p className="an-sub">{subtitle}</p>}
            </div>

            <div className="an-right" style={{ display: 'flex', alignItems: 'center', gap: '12px' }}>
                {/* Tombol Scan QR Code */}
                <button
                    className="an-btn-scan"
                    onClick={() => setShowVerif(true)}
                    title="Scan QR Code Peminjaman"
                    style={{ background: '#3b82f6', color: '#fff', border: 'none', padding: '8px 16px', borderRadius: '8px', cursor: 'pointer', fontWeight: 'bold', display: 'flex', alignItems: 'center', gap: '8px', transition: 'background 0.2s' }}
                    onMouseOver={e => e.currentTarget.style.background = '#2563eb'}
                    onMouseOut={e => e.currentTarget.style.background = '#3b82f6'}
                >
                    <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                        <rect x="3" y="3" width="18" height="18" rx="2" ry="2"/>
                        <rect x="7" y="7" width="3" height="3"/>
                        <rect x="14" y="7" width="3" height="3"/>
                        <rect x="7" y="14" width="3" height="3"/>
                        <rect x="14" y="14" width="3" height="3"/>
                    </svg>
                    <span style={{ fontSize: '14px' }}>Verifikasi QR</span>
                </button>

                {/* Notifikasi dengan dropdown */}
                <NotifDropdown />
                
                {/* Toggle dark mode */}
                <button
                    className="an-btn"
                    onClick={toggleTheme}
                    title={dark ? 'Mode Terang' : 'Mode Gelap'}
                >
                    {dark ? (
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <circle cx="12" cy="12" r="5"/>
                            <line x1="12" y1="1" x2="12" y2="3"/>
                            <line x1="12" y1="21" x2="12" y2="23"/>
                            <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"/>
                            <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"/>
                            <line x1="1" y1="12" x2="3" y2="12"/>
                            <line x1="21" y1="12" x2="23" y2="12"/>
                            <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"/>
                            <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"/>
                        </svg>
                    ) : (
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z"/>
                        </svg>
                    )}
                </button>

                {/* Avatar */}
                <div className="an-avatar" title={user.nama}>{initial}</div>
            </div>

            {/* Modal Verifikasi */}
            {showVerif && <VerifModal onClose={() => setShowVerif(false)} />}
        </header>
    );
}
