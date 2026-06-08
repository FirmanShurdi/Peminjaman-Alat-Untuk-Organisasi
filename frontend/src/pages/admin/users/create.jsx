import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import Sidebar from '../../../partials/admin/Sidebar';
import AdminNavbar from '../../../partials/admin/AdminNavbar';
import Flash from '../../../partials/Flash';

export default function UserCreate() {
  const navigate = useNavigate();
  const [toasts, setToasts] = useState([]);
  
  const [formData, setFormData] = useState({
    nim: '',
    nama: '',
    email: '',
    password: '',
    role: 'anggota'
  });

  const addToast = (type, message) => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4200);
  };
  const removeToast = (id) => setToasts(prev => prev.filter(t => t.id !== id));

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.nama || !formData.email || !formData.password || !formData.nim) {
      addToast('error', 'Harap isi semua kolom.');
      return;
    }
    if (!formData.email.endsWith('@kampus.ac.id')) {
      addToast('error', 'Email harus menggunakan domain @kampus.ac.id');
      return;
    }

    try {
      const token = localStorage.getItem('token');
      const res = await fetch('http://localhost:3000/admin/users', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}` 
        },
        body: JSON.stringify(formData)
      });
      const data = await res.json();
      if (data.status === 'success') {
        localStorage.setItem('_flash', JSON.stringify({ type: 'success', message: 'Pengguna berhasil ditambahkan.' }));
        navigate('/users');
      } else {
        addToast('error', data.message);
      }
    } catch (e) {
      console.error(e);
      addToast('error', 'Gagal menyimpan data pengguna.');
    }
  };

  return (
    <div className="barang-layout">
      <Flash toasts={toasts} removeToast={removeToast} />
      <Sidebar />
      <main className="barang-main">
        <AdminNavbar title="Tambah Pengguna" subtitle="Buat akun admin atau anggota baru." />

        <div className="barang-content" style={{ maxWidth: '600px', margin: '0 auto', marginTop: '20px' }}>
          <div className="table-card" style={{ padding: '24px' }}>
            <form onSubmit={handleSubmit}>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#334155' }}>NIM</label>
                <input 
                  type="text" 
                  name="nim" 
                  value={formData.nim} 
                  onChange={handleChange} 
                  required
                  style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' }}
                />
              </div>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#334155' }}>Nama Lengkap</label>
                <input 
                  type="text" 
                  name="nama" 
                  value={formData.nama} 
                  onChange={handleChange} 
                  required
                  style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' }}
                />
              </div>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#334155' }}>Email Kampus</label>
                <input 
                  type="email" 
                  name="email" 
                  value={formData.email} 
                  onChange={handleChange} 
                  required
                  style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' }}
                />
              </div>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#334155' }}>Password</label>
                <input 
                  type="password" 
                  name="password" 
                  value={formData.password} 
                  onChange={handleChange} 
                  required
                  style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' }}
                />
              </div>
              <div style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#334155' }}>Role</label>
                <select 
                  name="role" 
                  value={formData.role} 
                  onChange={handleChange} 
                  style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px', backgroundColor: '#fff' }}
                >
                  <option value="anggota">Anggota</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              
              <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button type="button" onClick={() => navigate('/users')} style={{ padding: '10px 20px', background: '#e2e8f0', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '600', color: '#475569' }}>Batal</button>
                <button type="submit" style={{ padding: '10px 20px', background: '#3b82f6', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '600' }}>Simpan Pengguna</button>
              </div>
            </form>
          </div>
        </div>
      </main>
    </div>
  );
}
