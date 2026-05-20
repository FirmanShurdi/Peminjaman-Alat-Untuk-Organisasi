import React from 'react';
import Sidebar from '../partials/admin/Sidebar';
import './ComingSoon.css';

function ComingSoon({ isPublic }) {
  const path = window.location.pathname.replace('/', '').replace(/-/g, ' ');
  const title = path.charAt(0).toUpperCase() + path.slice(1) || 'Halaman';

  if (isPublic) {
    return (
      <div style={{ display: 'flex', flexDirection: 'column', minHeight: '100vh', background: '#f8fafc', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ textAlign: 'center' }}>
          <div style={{ fontSize: '80px', marginBottom: '16px' }}>🚧</div>
          <h1 style={{ fontSize: '32px', color: '#0f172a', marginBottom: '8px', fontWeight: '800' }}>Segera Hadir</h1>
          <p style={{ color: '#64748b', fontSize: '16px', marginBottom: '24px' }}>Halaman Detail Barang ini sedang dalam tahap pengembangan.</p>
          <button onClick={() => window.history.back()} style={{ padding: '12px 24px', background: '#3b82f6', color: '#fff', borderRadius: '12px', border: 'none', fontWeight: 'bold', cursor: 'pointer', fontSize: '15px' }}>Kembali</button>
        </div>
      </div>
    );
  }

  return (
    <div className="dashboard-layout">
      <Sidebar />
      <main className="coming-soon-main">
        <div className="coming-soon-wrapper">
          <div className="coming-soon-icon">🚧</div>
          <h1 className="coming-soon-title">Segera Hadir</h1>
          <p className="coming-soon-sub">
            Fitur <strong>{title}</strong> masih dalam tahap pengembangan.
          </p>
          <p className="coming-soon-desc">
            Kami sedang bekerja keras untuk menyelesaikan fitur ini. Silakan kembali lagi nanti!
          </p>
          <a href="/dashboard" className="coming-soon-btn">← Kembali ke Dashboard</a>
        </div>
      </main>
    </div>
  );
}

export default ComingSoon;
