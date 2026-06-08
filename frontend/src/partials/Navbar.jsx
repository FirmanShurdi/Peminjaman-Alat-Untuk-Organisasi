import React from 'react';
import { Link, useNavigate, useLocation } from 'react-router-dom';
import NotifDropdown from './NotifDropdown';
import './Navbar.css';

export default function Navbar({ user, currentSection, goTo, onFlash }) {
  const navigate = useNavigate();
  const location = useLocation();

  const handleLogout = () => {
    const nama = user?.nama || 'Anda';
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    if (onFlash) {
      onFlash('info', `Sampai jumpa, ${nama}! Anda telah keluar.`);
    }
    setTimeout(() => navigate('/login'), 800);
  };

  const handleNavClick = (sectionIndex, hash) => {
    if (location.pathname === '/' || location.pathname === '/beranda') {
      if (goTo && typeof goTo === 'function') {
        goTo(sectionIndex);
      }
    } else {
      sessionStorage.setItem('beranda_section', sectionIndex.toString());
      navigate('/');
    }
  };

  return (
    <nav className="nav">
      <div className="nav-in">
        <div className="nav-logo" onClick={() => handleNavClick(0, '')}>
          <div className="logo-mark">
            <img src="http://localhost:3000/intro/logo.png" alt="PinjamIN Logo" style={{ width: '28px', height: '28px', objectFit: 'contain' }} />
          </div>
          <span>PinjamIN</span>
        </div>
        <div className="nav-links">
          <button onClick={() => handleNavClick(0, '')} className={`nl ${currentSection === 0 ? 'active' : ''}`}>Beranda</button>
          <button onClick={() => handleNavClick(1, '#cara-kerja')} className={`nl ${currentSection === 1 ? 'active' : ''}`}>Cara Kerja</button>
          <button onClick={() => handleNavClick(2, '#katalog')} className={`nl ${currentSection === 2 ? 'active' : ''}`}>Katalog Alat</button>
          <button onClick={() => handleNavClick(3, '#lokasi')} className={`nl ${currentSection === 3 ? 'active' : ''}`}>Lokasi</button>
          {user?.role === 'admin' && <Link to="/dashboard" className="nl">Dashboard</Link>}
          {user && user.role !== 'admin' && <Link to="/riwayat-peminjaman" className={`nl ${location.pathname === '/riwayat-peminjaman' ? 'active' : ''}`}>Riwayat</Link>}
        </div>
        <div className="nav-end">
          {user ? (
          <>
              <NotifDropdown />
              <div className="nav-divider"></div>
              <div className="nav-user-info">
                  <div className="nav-avatar">{user.nama?.charAt(0).toUpperCase()}</div>
                  <span className="nav-uname">{user.nama}</span>
              </div>
              {user.role === 'admin' && <Link to="/dashboard" className="nav-dash">Dashboard</Link>}
              <button onClick={handleLogout} className="btn-logout">Keluar</button>
            </>
          ) : (
            <>
              <Link to="/login" className="btn-ghost">Masuk</Link>
              <Link to="/login" className="btn-solid">Daftar</Link>
            </>
          )}
        </div>
      </div>
    </nav>
  );
}
