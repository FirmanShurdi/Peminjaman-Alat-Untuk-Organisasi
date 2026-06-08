import React, { useState, useEffect, useMemo } from 'react';
import Sidebar from '../../../partials/admin/Sidebar';
import { useTheme } from '../../../App';
import AdminNavbar from '../../../partials/admin/AdminNavbar';
import BarangEditModal from './edit';
import Flash from '../../../partials/Flash';
import './Barang.css';

export default function Barang() {
  const { dark, toggleTheme } = useTheme();
  const [barang, setBarang] = useState([]);
  const [kategori, setKategori] = useState([]);
  const [loading, setLoading] = useState(true);
  const [toasts, setToasts] = useState([]);

  const addToast = (type, message) => {
    const id = Date.now();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => {
      setToasts(prev => prev.filter(t => t.id !== id));
    }, 4200);
  };

  const removeToast = (id) => {
    setToasts(prev => prev.filter(t => t.id !== id));
  };
  
  // States for search, sort, pagination
  const [search, setSearch] = useState('');
  const [filterKondisi, setFilterKondisi] = useState('');
  const [filterKategori, setFilterKategori] = useState('');
  const [sortConfig, setSortConfig] = useState({ key: 'nama_barang', direction: 'asc' });
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 8;

  // States for Modal Form
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [selectedItem, setSelectedItem] = useState(null);

  // Fetch Data
  useEffect(() => {
    // Check for incoming global flash (e.g. from login redirect)
    try {
      const raw = localStorage.getItem('_flash');
      if (raw) {
        const flash = JSON.parse(raw);
        localStorage.removeItem('_flash');
        setTimeout(() => addToast(flash.type, flash.message), 300);
      }
    } catch (_) {}

    fetchData();
    fetchKategori();
  }, []);

  const fetchData = async () => {
    setLoading(true);
    try {
      const token = localStorage.getItem('token');
      const res = await fetch('http://localhost:3000/admin/barang', {
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
        setBarang(data.data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  const fetchKategori = async () => {
    try {
      const token = localStorage.getItem('token');
      const res = await fetch('http://localhost:3000/admin/barang/kategori', {
        headers: { 'Authorization': `Bearer ${token}` }
      });
      const data = await res.json();
      if (data.status === 'success') setKategori(data.data);
    } catch (e) {
      console.error(e);
    }
  };

  // Data Processing: Search & Sort
  const processedData = useMemo(() => {
    let filtered = barang.filter(b => {
      const matchSearch = b.nama_barang.toLowerCase().includes(search.toLowerCase()) ||
        (b.nama_kategori && b.nama_kategori.toLowerCase().includes(search.toLowerCase())) ||
        (b.lokasi && b.lokasi.toLowerCase().includes(search.toLowerCase()));
      
      const matchKondisi = filterKondisi === '' || 
        (b.kondisi && b.kondisi.toLowerCase() === filterKondisi.toLowerCase());

      const matchKategori = filterKategori === '' || 
        (b.id_kategori && b.id_kategori.toString() === filterKategori);

      return matchSearch && matchKondisi && matchKategori;
    });

    filtered.sort((a, b) => {
      let aVal = a[sortConfig.key];
      let bVal = b[sortConfig.key];
      
      if (aVal === null || aVal === undefined) aVal = '';
      if (bVal === null || bVal === undefined) bVal = '';

      if (typeof aVal === 'string') aVal = aVal.toLowerCase();
      if (typeof bVal === 'string') bVal = bVal.toLowerCase();

      if (aVal < bVal) return sortConfig.direction === 'asc' ? -1 : 1;
      if (aVal > bVal) return sortConfig.direction === 'asc' ? 1 : -1;
      return 0;
    });

    return filtered;
  }, [barang, search, filterKondisi, filterKategori, sortConfig]);

  // Pagination
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

  const openModal = (item = null) => {
    setSelectedItem(item);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    setIsModalOpen(false);
    setSelectedItem(null);
  };

  const handleModalSuccess = () => {
    fetchData();
  };

  const handleDelete = async (id) => {
    if (!confirm('Apakah Anda yakin ingin menghapus barang ini?')) return;
    const token = localStorage.getItem('token');
    try {
      const res = await fetch(`http://localhost:3000/admin/barang/${id}`, {
        method: 'DELETE',
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
        addToast('success', data.message || 'Barang berhasil dihapus.');
        fetchData();
      } else {
        addToast('error', data.message);
      }
    } catch (e) {
      console.error(e);
      addToast('error', 'Terjadi kesalahan jaringan.');
    }
  };

  const user = JSON.parse(localStorage.getItem('user') || '{}');

  return (
    <div className="barang-layout">

      <Flash toasts={toasts} removeToast={removeToast} />
      <Sidebar />
      <main className="barang-main">
        <AdminNavbar title="Inventaris Barang" subtitle="Kelola data barang dan kategori dalam satu tempat." />

        <div className="barang-content">
          <div className="table-card">
            <div className="table-toolbar">
              <div className="toolbar-left" style={{ display: 'flex', gap: '12px' }}>
                <div className="search-box">
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>
                  <input 
                    type="text" 
                    placeholder="Cari barang, kategori, atau lokasi..." 
                    value={search}
                    onChange={(e) => { setSearch(e.target.value); setCurrentPage(1); }}
                  />
                </div>
                <select 
                  className="filter-select"
                  value={filterKategori}
                  onChange={(e) => { setFilterKategori(e.target.value); setCurrentPage(1); }}
                >
                  <option value="">Semua Kategori</option>
                  {kategori.map(k => (
                    <option key={k.id_kategori} value={k.id_kategori}>{k.nama_kategori}</option>
                  ))}
                </select>
                <select 
                  className="filter-select"
                  value={filterKondisi}
                  onChange={(e) => { setFilterKondisi(e.target.value); setCurrentPage(1); }}
                >
                  <option value="">Semua Kondisi</option>
                  <option value="baik">Baik</option>
                  <option value="cukup baik">Cukup Baik</option>
                  <option value="sedang">Sedang</option>
                  <option value="rusak">Rusak</option>
                </select>
              </div>
              <button className="btn-primary" onClick={() => openModal()}>
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
                Tambah Barang
              </button>
            </div>

            <div className="table-wrapper">
              <table className="barang-table">
                <thead>
                  <tr>
                    <th>No.</th>
                    <th onClick={() => requestSort('id_barang')}>ID {sortConfig.key === 'id_barang' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th>Gambar</th>
                    <th onClick={() => requestSort('nama_barang')}>Nama Barang {sortConfig.key === 'nama_barang' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th>Deskripsi</th>
                    <th onClick={() => requestSort('nama_kategori')}>Kategori {sortConfig.key === 'nama_kategori' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th onClick={() => requestSort('stok')}>Stok {sortConfig.key === 'stok' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th onClick={() => requestSort('kondisi')}>Kondisi {sortConfig.key === 'kondisi' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th onClick={() => requestSort('lokasi')}>Lokasi {sortConfig.key === 'lokasi' && (sortConfig.direction === 'asc' ? '↑' : '↓')}</th>
                    <th>Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                    <tr><td colSpan="9" style={{textAlign:'center', padding:'40px'}}>Memuat data...</td></tr>
                  ) : currentData.length === 0 ? (
                    <tr><td colSpan="9" style={{textAlign:'center', padding:'40px'}}>Data tidak ditemukan.</td></tr>
                  ) : (
                    currentData.map((item, index) => (
                      <tr key={item.id_barang}>
                        <td>{processedData.length - ((currentPage - 1) * itemsPerPage) - index}</td>
                        <td>ID: {item.id_barang}</td>
                        <td>
                          {item.gambar ? (
                            <img src={item.gambar.startsWith('http') ? item.gambar : `http://localhost:3000/barang/${item.gambar}`} alt={item.nama_barang} className="barang-img" />
                          ) : (
                            <div className="barang-img" style={{display:'flex',alignItems:'center',justifyContent:'center',fontSize:'10px',color:'#94a3b8'}}>No Img</div>
                          )}
                        </td>
                        <td className="nama-cell">{item.nama_barang}</td>
                        <td style={{ maxWidth: '150px', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }} title={item.deskripsi}>{item.deskripsi || '-'}</td>
                        <td>
                          {item.nama_kategori ? (
                            <span className="kategori-badge">{item.nama_kategori}</span>
                          ) : '-'}
                        </td>
                        <td className={`stok-cell ${item.stok > 5 ? 'ok' : 'low'}`}>{item.stok}</td>
                        <td>{item.kondisi || '-'}</td>
                        <td>{item.lokasi || '-'}</td>
                        <td>
                          <div className="action-btns">
                            <button className="btn-icon edit" onClick={() => openModal(item)} title="Edit">
                              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>
                            </button>
                            <button className="btn-icon delete" onClick={() => handleDelete(item.id_barang)} title="Hapus">
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
                <button 
                  className="page-btn" 
                  disabled={currentPage === 1}
                  onClick={() => setCurrentPage(p => p - 1)}
                >
                  Prev
                </button>
                {Array.from({ length: totalPages }, (_, i) => i + 1).map(page => (
                  <button 
                    key={page} 
                    className={`page-btn ${currentPage === page ? 'active' : ''}`}
                    onClick={() => setCurrentPage(page)}
                  >
                    {page}
                  </button>
                ))}
                <button 
                  className="page-btn" 
                  disabled={currentPage === totalPages || totalPages === 0}
                  onClick={() => setCurrentPage(p => p + 1)}
                >
                  Next
                </button>
              </div>
            </div>
          </div>
        </div>
      </main>

      <BarangEditModal 
        isOpen={isModalOpen} 
        onClose={closeModal} 
        initialData={selectedItem} 
        kategori={kategori}
        onSuccess={handleModalSuccess}
        addToast={addToast}
      />
    </div>
  );
}
