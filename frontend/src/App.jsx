import React, { useEffect, useState, createContext, useContext } from 'react'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom'
import { redirectToLogin } from './utils/authFetch'
import Auth from './pages/Auth'
import Beranda from './pages/Beranda'
import Dashboard from './pages/Dashboard'
import Barang from './pages/admin/barang/Barang'
import Peminjaman from './pages/admin/peminjaman/Peminjaman'
import PeminjamanEdit from './pages/admin/peminjaman/edit'
import ComingSoon from './pages/ComingSoon'
import Detail from './pages/Detail'
import DaftarBarang from './pages/DaftarBarang'
import RiwayatPeminjaman from './pages/RiwayatPeminjaman'
import CartWidget from './partials/CartWidget'
import Users from './pages/admin/users/users'

export const ThemeContext = createContext();

export function useTheme() {
  return useContext(ThemeContext);
}

function ProtectedRoute({ children, adminOnly }) {
  // Cukup cek keberadaan data user — validasi token dilakukan backend via cookie
  const user = (() => {
    try { return JSON.parse(localStorage.getItem('user')); } catch { return null; }
  })();

  if (!user) return <Navigate to="/login" replace />;

  if (adminOnly && user.role !== 'admin') {
    return <Navigate to="/unauthorized" replace />;
  }

  return children;
}

function Unauthorized() {
  return (
    <div style={{ display: 'flex', height: '100vh', alignItems: 'center', justifyContent: 'center', flexDirection: 'column', fontFamily: 'Inter, sans-serif' }}>
      <h1 style={{ fontSize: '48px', margin: '0 0 16px', color: '#dc2626' }}>403</h1>
      <h2 style={{ fontSize: '24px', margin: '0 0 8px', color: '#1e293b' }}>Akses Ditolak</h2>
      <p style={{ color: '#64748b', marginBottom: '24px' }}>Halaman ini khusus untuk Administrator.</p>
      <button onClick={() => { localStorage.clear(); window.location.href = '/login'; }} style={{ padding: '10px 20px', background: '#3b82f6', color: 'white', border: 'none', borderRadius: '8px', cursor: 'pointer' }}>
        Kembali ke Login
      </button>
    </div>
  );
}

function App() {
  const [dark, setDark] = useState(() => localStorage.getItem('theme') === 'dark');

  useEffect(() => {
    document.documentElement.classList.toggle('dark', dark);
    localStorage.setItem('theme', dark ? 'dark' : 'light');
  }, [dark]);

  const toggleTheme = () => setDark(prev => !prev);

  // Logout di tab lain → semua tab ikut redirect
  useEffect(() => {
    const onStorage = (e) => {
      if (e.key === 'user' && !e.newValue) redirectToLogin('Anda telah logout.');
    };
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, []);

  return (
    <ThemeContext.Provider value={{ dark, toggleTheme }}>
      <BrowserRouter>
        <CartWidget />
        <Routes>
          <Route path="/" element={<Beranda />} />
          <Route path="/beranda" element={<Beranda />} />
          <Route path="/login" element={<Auth />} />
          <Route path="/detail/:id" element={<Detail />} />
          <Route path="/daftarbarang" element={<DaftarBarang />} />
          <Route path="/riwayat-peminjaman" element={<RiwayatPeminjaman />} />
          <Route path="/unauthorized" element={<Unauthorized />} />
          <Route path="/dashboard" element={
            <ProtectedRoute adminOnly={true}><Dashboard /></ProtectedRoute>
          } />
          <Route path="/analytics" element={<ProtectedRoute adminOnly={true}><ComingSoon /></ProtectedRoute>} />
          <Route path="/barang"      element={<ProtectedRoute adminOnly={true}><Barang /></ProtectedRoute>} />
          <Route path="/peminjaman"  element={<ProtectedRoute adminOnly={true}><Peminjaman /></ProtectedRoute>} />
          <Route path="/peminjaman/:id" element={<ProtectedRoute adminOnly={true}><PeminjamanEdit /></ProtectedRoute>} />
          <Route path="/kategori" element={<ProtectedRoute adminOnly={true}><ComingSoon /></ProtectedRoute>} />
          <Route path="/riwayat" element={<ProtectedRoute adminOnly={true}><ComingSoon /></ProtectedRoute>} />
          <Route path="/users" element={<ProtectedRoute adminOnly={true}><Users /></ProtectedRoute>} />
          <Route path="/notifikasi" element={<ProtectedRoute adminOnly={true}><ComingSoon /></ProtectedRoute>} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </BrowserRouter>
    </ThemeContext.Provider>
  )
}

export default App
