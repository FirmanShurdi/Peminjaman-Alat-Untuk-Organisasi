import React from 'react';
import { NavLink, useNavigate } from 'react-router-dom';
import './Sidebar.css';

const menuSections = [
  {
    label: 'OVERVIEW',
    items: [
      { name: 'Dashboard', icon: '📊', path: '/dashboard' },
    ]
  },
  {
    label: 'INVENTARIS',
    items: [
      { name: 'Barang', icon: '📦', path: '/barang' },
    ]
  },
  {
    label: 'PEMINJAMAN',
    items: [
      { name: 'Daftar Pinjam', icon: '📋', path: '/peminjaman' },
    ]
  },
  {
    label: 'SISTEM',
    items: [
      { name: 'Users', icon: '👥', path: '/users' },
      { name: 'Beranda', icon: '🏠︎', path: '/' },
    ]
  }
];

function Sidebar() {
  const navigate = useNavigate();
  const user = JSON.parse(localStorage.getItem('user') || '{}');

  const handleLogout = () => {
    const user = JSON.parse(localStorage.getItem('user') || '{}');
    const nama = user?.nama || 'Anda';
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.setItem('_flash', JSON.stringify({ type: 'info', message: `Sampai jumpa, ${nama}! Anda telah berhasil keluar.` }));
    navigate('/login');
  };

  return (
    <aside className="sidebar">
      <div className="sidebar-brand">
        <div className="brand-icon">
          <img src="http://localhost:3000/intro/logo.png" alt="PinjamIN Logo" style={{ width: '28px', height: '28px', objectFit: 'contain' }} />
        </div>
        <div className="brand-text">
          <span className="brand-name">PinjamIN</span>
          <span className="brand-sub">DASHBOARD</span>
        </div>
      </div>

      <div className="sidebar-search">
        <svg className="search-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
          <circle cx="11" cy="11" r="8"/>
          <path d="M21 21l-4.35-4.35"/>
        </svg>
        <input type="text" placeholder="Search anything..." />
      </div>

      <nav className="sidebar-nav">
        {menuSections.map((section) => (
          <div key={section.label} className="nav-section">
            <span className="nav-label">{section.label}</span>
            {section.items.map((item) => (
              <NavLink
                key={item.path}
                to={item.path}
                className={({ isActive }) => `nav-item ${isActive ? 'active' : ''}`}
              >
                <span className="nav-icon">{item.icon}</span>
                <span className="nav-text">{item.name}</span>
              </NavLink>
            ))}
          </div>
        ))}
      </nav>

      <div className="sidebar-footer">
        <div className="user-info">
          <div className="user-avatar">
            {(user.nama || 'A').charAt(0).toUpperCase()}
          </div>
          <div className="user-details">
            <span className="user-name">{user.nama || 'Admin'}</span>
            <span className="user-role">{user.role || 'admin'}</span>
          </div>
        </div>
        <button className="logout-btn" onClick={handleLogout} title="Logout">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4"/>
            <polyline points="16 17 21 12 16 7"/>
            <line x1="21" y1="12" x2="9" y2="12"/>
          </svg>
        </button>
      </div>
    </aside>
  );
}

export default Sidebar;
