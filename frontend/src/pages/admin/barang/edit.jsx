import React, { useState, useEffect } from 'react';
import './edit.css';

export default function BarangEditModal({ isOpen, onClose, initialData, kategori, onSuccess, addToast }) {
  const [formData, setFormData] = useState({ 
    id_barang: null, 
    nama_barang: '', 
    deskripsi: '',
    id_kategori: '', 
    kondisi: '', 
    stok: 0, 
    lokasi: '', 
    gambar: '' 
  });

  useEffect(() => {
    if (isOpen) {
      if (initialData) {
        setFormData({
          id_barang: initialData.id_barang,
          nama_barang: initialData.nama_barang,
          deskripsi: initialData.deskripsi || '',
          id_kategori: initialData.id_kategori || '',
          kondisi: initialData.kondisi || '',
          stok: initialData.stok || 0,
          lokasi: initialData.lokasi || '',
          gambar: initialData.gambar || ''
        });
      } else {
        setFormData({ id_barang: null, nama_barang: '', deskripsi: '', id_kategori: '', kondisi: '', stok: 0, lokasi: '', gambar: '' });
      }
    }
  }, [isOpen, initialData]);

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    const token = localStorage.getItem('token');
    const url = formData.id_barang 
      ? `http://localhost:3000/admin/barang/${formData.id_barang}`
      : `http://localhost:3000/admin/barang`;
    const method = formData.id_barang ? 'PUT' : 'POST';

    try {
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
        addToast('success', data.message || 'Data berhasil disimpan.');
        onSuccess();
        onClose();
      } else {
        if (res.status === 401 || res.status === 403) {
          localStorage.setItem('_flash', JSON.stringify({ type: 'error', message: 'Sesi Anda telah habis. Silakan login kembali.' }));
          localStorage.removeItem('token');
          localStorage.removeItem('user');
          window.location.href = '/login';
        } else {
          addToast('error', data.message);
        }
      }
    } catch (e) {
      console.error(e);
      addToast('error', 'Terjadi kesalahan jaringan.');
    }
  };

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal-content" onClick={e => e.stopPropagation()}>
        <div className="modal-header">
          <h2>{formData.id_barang ? 'Edit Barang' : 'Tambah Barang Baru'}</h2>
          <button className="modal-close" onClick={onClose}>
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="18" y1="6" x2="6" y2="18"/>
              <line x1="6" y1="6" x2="18" y2="18"/>
            </svg>
          </button>
        </div>
        <form onSubmit={handleSubmit}>
          <div className="modal-body">
            <div className="form-group">
              <label>Nama Barang *</label>
              <input type="text" className="form-control" required value={formData.nama_barang} onChange={e => setFormData({...formData, nama_barang: e.target.value})} placeholder="Contoh: Proyektor Epson" />
            </div>

            <div className="form-group">
              <label>Deskripsi</label>
              <textarea className="form-control" rows="3" value={formData.deskripsi} onChange={e => setFormData({...formData, deskripsi: e.target.value})} placeholder="Deskripsi singkat barang..." style={{ resize: 'vertical' }}></textarea>
            </div>
            
            <div className="form-row">
              <div className="form-group">
                <label>Kategori</label>
                <select className="form-control" value={formData.id_kategori} onChange={e => setFormData({...formData, id_kategori: e.target.value})}>
                  <option value="">Pilih Kategori</option>
                  {kategori.map(k => (
                    <option key={k.id_kategori} value={k.id_kategori}>{k.nama_kategori}</option>
                  ))}
                </select>
              </div>
              <div className="form-group">
                <label>Stok *</label>
                <input type="number" min="0" className="form-control" required value={formData.stok} onChange={e => setFormData({...formData, stok: parseInt(e.target.value) || 0})} />
              </div>
            </div>

            <div className="form-row">
              <div className="form-group">
                <label>Kondisi</label>
                <input type="text" className="form-control" value={formData.kondisi} onChange={e => setFormData({...formData, kondisi: e.target.value})} placeholder="Contoh: Baik" />
              </div>
              <div className="form-group">
                <label>Lokasi</label>
                <input type="text" className="form-control" value={formData.lokasi} onChange={e => setFormData({...formData, lokasi: e.target.value})} placeholder="Contoh: Lemari A" />
              </div>
            </div>

            <div className="form-group">
              <label>URL Gambar</label>
              <input type="text" className="form-control" value={formData.gambar} onChange={e => setFormData({...formData, gambar: e.target.value})} placeholder="https://..." />
            </div>
          </div>
          <div className="modal-footer">
            <button type="button" className="btn-secondary" onClick={onClose}>Batal</button>
            <button type="submit" className="btn-primary">Simpan Data</button>
          </div>
        </form>
      </div>
    </div>
  );
}
