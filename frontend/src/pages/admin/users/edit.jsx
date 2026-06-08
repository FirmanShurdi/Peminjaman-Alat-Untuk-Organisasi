import React, { useState, useEffect } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import Sidebar from '../../../partials/admin/Sidebar';
import AdminNavbar from '../../../partials/admin/AdminNavbar';
import Flash from '../../../partials/Flash';

export default function UserEdit() {
  const navigate = useNavigate();
  const { id } = useParams();
  const [toasts, setToasts] = useState([]);
  const [loading, setLoading] = useState(true);
  
  const [formData, setFormData] = useState({
    nim: '',
    nama: '',
    email: '',
    password: '',
    role: 'anggota'
  });

  const addToast = (type, message) => {
    const toastId = Date.now();
    setToasts(prev => [...prev, { id: toastId, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== toastId)), 4200);
  };
  const removeToast = (toastId) => setToasts(prev => prev.filter(t => t.id !== toastId));

  useEffect(() => {
    fetchUser();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const fetchUser = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await fetch(`http://localhost:3000/admin/users/${id}`, {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.status === 'success') {
        setFormData({
          nim: data.data.nim || '',
          nama: data.data.nama || '',
          email: data.data.email || '',
          password: '', // Jangan tampilkan password asli
          role: data.data.role || 'anggota'
        });
      } else {
        localStorage.setItem('_flash', JSON.stringify({ type: 'error', message: data.message || 'Pengguna tidak ditemukan.' }));
        navigate('/users');
      }
    } catch (e) {
      console.error(e);
      addToast('error', 'Gagal memuat data pengguna.');
    } finally {
      setLoading(false);
    }
  };

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!formData.nama || !formData.email || !formData.nim) {
      addToast('error', 'NIM, Nama, dan Email wajib diisi.');
      return;
    }
    if (!formData.email.endsWith('@kampus.ac.id')) {
      addToast('error', 'Email harus menggunakan domain @kampus.ac.id');
      return;
    }

    try {
      const token = localStorage.getItem('token');
      const res = await fetch(`http://localhost:3000/admin/users/${id}`, {
        method: 'PUT',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}` 
        },
        body: JSON.stringify(formData)
      });
      const data = await res.json();
      if (data.status === 'success') {
        localStorage.setItem('_flash', JSON.stringify({ type: 'success', message: 'Perubahan berhasil disimpan.' }));
        navigate('/users');
      } else {
        addToast('error', data.message);
      }
    } catch (e) {
      console.error(e);
      addToast('error', 'Gagal menyimpan perubahan.');
    }
  };

  if (loading) {
    return <div style={{textAlign: 'center', padding: '50px'}}>Memuat...</div>;
  }

  return (
    <div className="barang-layout">
      <Flash toasts={toasts} removeToast={removeToast} />
      <Sidebar />
      <main className="barang-main">
        <AdminNavbar title="Edit Pengguna" subtitle="Ubah detail akun anggota atau admin." />

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
                <label style={{ display: 'block', marginBottom: '8px', fontWeight: '500', color: '#334155' }}>Password (Kosongkan jika tidak ingin diubah)</label>
                <input 
                  type="password" 
                  name="password" 
                  value={formData.password} 
                  onChange={handleChange} 
                  placeholder="Ketik password baru..."
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
                <button type="submit" style={{ padding: '10px 20px', background: '#3b82f6', color: '#fff', border: 'none', borderRadius: '6px', cursor: 'pointer', fontWeight: '600' }}>Simpan Perubahan</button>
              </div>
            </form>
          </div>
        </div>
      </main>
    </div>
  );
}
