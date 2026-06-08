import React, { useState, useEffect, useMemo } from 'react';
import Sidebar from '../../../partials/admin/Sidebar';
import { useTheme } from '../../../App';
import AdminNavbar from '../../../partials/admin/AdminNavbar';
import Flash from '../../../partials/Flash';

export default function Users() {
  const { dark } = useTheme();
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toasts, setToasts] = useState([]);

  const addToast = (type, message) => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4200);
  };
  const removeToast = (id) => setToasts(prev => prev.filter(t => t.id !== id));

  const [search, setSearch] = useState('');
  const [filterRole, setFilterRole] = useState('');
  const [sortConfig, setSortConfig] = useState({ key: 'id_user', direction: 'desc' });
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;

  // Modal State
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState('create'); // 'create' | 'edit'
  const [currentId, setCurrentId] = useState(null);
  const [formData, setFormData] = useState({ nim: '', nama: '', email: '', password: '', role: 'anggota' });
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    try {
      const raw = localStorage.getItem('_flash');
      if (raw) {
        const flash = JSON.parse(raw);
        localStorage.removeItem('_flash');
        setTimeout(() => addToast(flash.type, flash.message), 300);
      }
    } catch (_) {}
    fetchData();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('token');
      const res = await fetch('http://localhost:3000/admin/users', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      if (res.status === 401 || res.status === 403) {
        localStorage.setItem('_flash', JSON.stringify({ type: 'error', message: 'Sesi Anda telah habis. Silakan login kembali.' }));
        localStorage.removeItem('token');
        localStorage.removeItem('user');
        window.location.href = '/login';
        return;
      }
      const data = await res.json();
      if (data.status === 'success') {
        setUsers(data.data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const processedData = useMemo(() => {
    let filtered = users.filter(u => {
      const matchSearch = u.nama.toLowerCase().includes(search.toLowerCase()) ||
                          u.email.toLowerCase().includes(search.toLowerCase()) ||
                          (u.nim && u.nim.includes(search));
      const matchRole = filterRole === '' || u.role === filterRole;
      return matchSearch && matchRole;
    });

    filtered.sort((a, b) => {
      let aVal = a[sortConfig.key] || '';
      let bVal = b[sortConfig.key] || '';
      if (typeof aVal === 'string') aVal = aVal.toLowerCase();
      if (typeof bVal === 'string') bVal = bVal.toLowerCase();
      if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });
    return filtered;
  }, [users, search, filterRole, sortConfig]);

  const totalPages = Math.ceil(processedData.length / itemsPerPage);
  const currentData = useMemo(() => {
    const start = (currentPage - 1) * itemsPerPage;
    return processedData.slice(start, start + itemsPerPage);
  }, [processedData, currentPage]);

  useEffect(() => {
    if (currentPage > totalPages && totalPages > 0) setCurrentPage(totalPages);
  }, [totalPages, currentPage]);

  const requestSort = (key) => {
    let direction = 'asc';
    if (sortConfig.key === key && sortConfig.direction === 'asc') direction = 'desc';
    setSortConfig({ key, direction });
  };

  const handleDelete = async (id) => {
    if (!confirm('Apakah Anda yakin ingin menghapus pengguna ini?')) return;
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`http://localhost:3000/admin/users/${id}`, {
        method: 'DELETE',
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.status === 'success') {
        addToast('success', data.message || 'Pengguna berhasil dihapus.');
        fetchData();
      } else {
        addToast('error', data.message);
      }
    } catch (e) {
      console.error(e);
      addToast('error', 'Terjadi kesalahan jaringan.');
    }
  };

  const openCreateModal = () => {
    setModalMode('create');
    setFormData({ nim: '', nama: '', email: '', password: '', role: 'anggota' });
    setIsModalOpen(true);
  };

  const openEditModal = (item) => {
    setModalMode('edit');
    setCurrentId(item.id_user);
    setFormData({
      nim: item.nim || '',
      nama: item.nama || '',
      email: item.email || '',
      password: '',
      role: item.role || 'anggota'
    });
    setIsModalOpen(true);
  };

  const handleModalSubmit = async (e) => {
    e.preventDefault();
    if (!formData.nama || !formData.email || !formData.nim) {
      addToast('error', 'NIM, Nama, dan Email wajib diisi.');
      return;
    }
    if (!formData.email.endsWith('@kampus.ac.id')) {
      addToast('error', 'Email harus menggunakan domain @kampus.ac.id');
      return;
    }
    if (modalMode === 'create' && !formData.password) {
      addToast('error', 'Password wajib diisi untuk pengguna baru.');
      return;
    }

    setSubmitting(true);
    try {
      const token = localStorage.getItem('token');
      const url = modalMode === 'create' ? 'http://localhost:3000/admin/users' : `http://localhost:3000/admin/users/${currentId}`;
      const method = modalMode === 'create' ? 'POST' : 'PUT';

      const res = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`
        },
        body: JSON.stringify(formData)
      });
      const data = await res.json();
      
      if (data.status === 'success') {
        addToast('success', modalMode === 'create' ? 'Pengguna berhasil ditambahkan.' : 'Perubahan berhasil disimpan.');
        setIsModalOpen(false);
        fetchData();
      } else {
        addToast('error', data.message);
      }
    } catch (err) {
      console.error(err);
      addToast('error', 'Gagal menyimpan data pengguna.');
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="barang-layout">
      <Flash toasts={toasts} removeToast={removeToast} />
      <Sidebar />
      <main className="barang-main">
        <AdminNavbar title="Manajemen Pengguna" subtitle="Kelola data akun mahasiswa dan admin." />

        <div className="barang-content">
          <div className="table-card">
            <div className="table-toolbar">
              <div className="toolbar-left" style={{ display: 'flex', gap: '12px' }}>
                <div className="search-box">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                  <input 
                    type="text" 
                    placeholder="Cari nama, nim, email..." 
                    value={search}
                    onChange={(e) => { setSearch(e.target.value); setCurrentPage(1); }}
                  />
                </div>
                <select 
                  className="filter-select"
                  value={filterRole}
                  onChange={(e) => { setFilterRole(e.target.value); setCurrentPage(1); }}
                >
                  <option value="">Semua Role</option>
                  <option value="anggota">Anggota</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <button className="btn-primary" onClick={openCreateModal}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Tambah Pengguna
              </button>
            </div>

            <div className="table-wrapper">
              <table className="barang-table">
                <thead>
                  <tr>
                    <th>No.</th>
                    <th onClick={() => requestSort('id_user')}>ID {sortConfig.key === 'id_user' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th onClick={() => requestSort('nim')}>NIM {sortConfig.key === 'nim' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th onClick={() => requestSort('nama')}>Nama {sortConfig.key === 'nama' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th onClick={() => requestSort('email')}>Email {sortConfig.key === 'email' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th onClick={() => requestSort('role')}>Role {sortConfig.key === 'role' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr><td colSpan="7" style={{textAlign:'center', padding:'40px'}}>Memuat data...</td></tr>
                  ) : currentData.length === 0 ? (
                    <tr><td colSpan="7" style={{textAlign:'center', padding:'40px'}}>Data tidak ditemukan.</td></tr>
                  ) : (
                    currentData.map((item, index) => (
                      <tr key={item.id_user}>
                        <td>{processedData.length - ((currentPage - 1) * itemsPerPage) - index}</td>
                        <td style={{ fontWeight: '600', color: '#64748b' }}>Id:{item.id_user}</td>
                        <td>{item.nim || '-'}</td>
                        <td className="nama-cell">{item.nama}</td>
                        <td>{item.email}</td>
                        <td>
                          <span className="kategori-badge" style={{background: item.role === 'admin' ? '#fef08a' : '#e2e8f0', color: item.role === 'admin' ? '#854d0e' : '#475569'}}>{item.role}</span>
                        </td>
                        <td>
                          <div className="action-btns">
                            <button className="btn-icon edit" onClick={() => openEditModal(item)} title="Edit">
                              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                            </button>
                            <button className="btn-icon delete" onClick={() => handleDelete(item.id_user)} title="Hapus">
                              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/><line x1="10" y1="11" x2="10" y2="17"/><line x1="14" y1="11" x2="14" y2="17"/></svg>
                            </button>
                          </div>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            <div className="pagination">
              <div className="page-info">
                Menampilkan {currentData.length > 0 ? ((currentPage - 1) * itemsPerPage) + 1 : 0} hingga {Math.min(currentPage * itemsPerPage, processedData.length)} dari {processedData.length} entri
              </div>
              <div className="page-controls">
                <button className="page-btn" disabled={currentPage === 1} onClick={() => setCurrentPage(p => p - 1)}>Prev</button>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
                  <button key={page} className={`page-btn ${currentPage === page ? 'active' : ''}`} onClick={() => setCurrentPage(page)}>{page}</button>
                ))}
                <button className="page-btn" disabled={currentPage === totalPages || totalPages === 0} onClick={() => setCurrentPage(p => p + 1)}>Next</button>
              </div>
            </div>
          </div>
        </div>
      </main>

      {/* Modal Popup */}
      {isModalOpen && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.5)', zIndex: 9999, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div className="table-card" style={{ width: '90%', maxWidth: '500px', padding: '24px', background: '#fff', borderRadius: '12px', boxShadow: '0 20px 25px -5px rgba(0, 0, 0, 0.1)' }}>
            <h2 style={{ marginTop: 0, marginBottom: '20px', fontSize: '20px', fontWeight: '700', color: '#1e293b' }}>
              {modalMode === 'create' ? 'Tambah Pengguna Baru' : 'Edit Data Pengguna'}
            </h2>
            <form onSubmit={handleModalSubmit}>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '6px', fontWeight: '500', color: '#475569', fontSize: '14px' }}>NIM</label>
                <input type="text" name="nim" value={formData.nim} onChange={(e) => setFormData({...formData, nim: e.target.value})} required style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
              </div>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '6px', fontWeight: '500', color: '#475569', fontSize: '14px' }}>Nama Lengkap</label>
                <input type="text" name="nama" value={formData.nama} onChange={(e) => setFormData({...formData, nama: e.target.value})} required style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
              </div>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '6px', fontWeight: '500', color: '#475569', fontSize: '14px' }}>Email Kampus (@kampus.ac.id)</label>
                <input type="email" name="email" value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value})} required style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
              </div>
              <div style={{ marginBottom: '16px' }}>
                <label style={{ display: 'block', marginBottom: '6px', fontWeight: '500', color: '#475569', fontSize: '14px' }}>
                  Password {modalMode === 'edit' && <span style={{fontSize: '12px', color: '#94a3b8'}}>(Kosongkan jika tidak diubah)</span>}
                </label>
                <input type="password" name="password" value={formData.password} onChange={(e) => setFormData({...formData, password: e.target.value})} required={modalMode === 'create'} style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px' }} />
              </div>
              <div style={{ marginBottom: '24px' }}>
                <label style={{ display: 'block', marginBottom: '6px', fontWeight: '500', color: '#475569', fontSize: '14px' }}>Role</label>
                <select name="role" value={formData.role} onChange={(e) => setFormData({...formData, role: e.target.value})} style={{ width: '100%', padding: '10px', border: '1px solid #cbd5e1', borderRadius: '6px', backgroundColor: '#fff' }}>
                  <option value="anggota">Anggota</option>
                  <option value="admin">Admin</option>
                </select>
              </div>
              <div style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                <button type="button" onClick={() => setIsModalOpen(false)} style={{ padding: '10px 20px', background: '#f1f5f9', border: '1px solid #cbd5e1', borderRadius: '6px', cursor: 'pointer', fontWeight: '600', color: '#475569' }}>Batal</button>
                <button type="submit" disabled={submitting} style={{ padding: '10px 20px', background: '#3b82f6', color: '#fff', border: 'none', borderRadius: '6px', cursor: submitting ? 'not-allowed' : 'pointer', fontWeight: '600', opacity: submitting ? 0.7 : 1 }}>
                  {submitting ? 'Menyimpan...' : 'Simpan'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
