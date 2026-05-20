import React, { useState, useEffect } from 'react';
import ReactDOM from 'react-dom';
import { useNavigate } from 'react-router-dom';
import { authFetch } from '../../utils/authFetch';
import './verif.css';

const API = 'http://localhost:3000';

const genCode = (id) => ((id * 2654435761) >>> 0).toString(16).substring(0, 6).toUpperCase().padStart(6, '0');

function fmtDate(d) {
    if (!d) return '-';
    return new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
}

export default function VerifModal({ onClose }) {
    const [kode, setKode] = useState('');
    const [step, setStep] = useState(1);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [dataPem, setDataPem] = useState(null);
    const [fileBukti, setFileBukti] = useState(null);
    const [previewImg, setPreviewImg] = useState(null); // State untuk fullscreen image

    // Step 1: Cari Data
    const handleSearch = async (e) => {
        e.preventDefault();
        setError('');
        if (!kode) return setError('Masukkan kode verifikasi.');

        setLoading(true);
        try {
            const res = await authFetch(`${API}/peminjaman`);
            const json = await res.json();
            if (json.status !== 'success') throw new Error('Gagal memuat data.');

            const allData = json.data;
            const cleanedInput = kode.replace('PMJ-', '').toUpperCase().trim();

            const found = allData.find(p => genCode(p.id_peminjaman) === cleanedInput || String(p.id_peminjaman) === cleanedInput);

            if (!found) {
                throw new Error('Kode peminjaman tidak ditemukan.');
            }

            if (found.status !== 'disetujui' && found.status !== 'diambil') {
                throw new Error(`Status peminjaman saat ini adalah '${found.status}', tidak dapat diproses.`);
            }

            setDataPem(found);
            setStep(2);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    // Step 2: Proses Simpan
    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!fileBukti) return setError('Foto bukti serah/terima wajib diunggah.');

        setLoading(true);
        try {
            // Tentukan status berikutnya
            const nextStatus = dataPem.status === 'disetujui' ? 'diambil' : 'selesai';

            const fd = new FormData();
            fd.append('status', nextStatus);
            fd.append('bukti', fileBukti);

            const res = await authFetch(`${API}/peminjaman/${dataPem.id_peminjaman}/status`, {
                method: 'PATCH',
                body: fd
            });
            const data = await res.json();
            
            if (!res.ok) throw new Error(data.message || 'Gagal memperbarui status.');

            // Berhasil
            alert(`Berhasil! Status diperbarui menjadi ${nextStatus.toUpperCase()}`);
            window.location.reload(); // Reload halaman untuk update data di tabel/dashboard
        } catch (err) {
            setError(err.message);
            setLoading(false);
        }
    };

    if (!document.body) return null;

    return ReactDOM.createPortal(
        <div className="vm-overlay">
            {/* Fullscreen Image Preview */}
            {previewImg && (
                <div className="vm-img-preview-overlay" onClick={() => setPreviewImg(null)}>
                    <button className="vm-img-preview-close" onClick={() => setPreviewImg(null)}>&times;</button>
                    <img src={`${API}/${previewImg}`} alt="Preview Dokumen" className="vm-img-preview" />
                </div>
            )}

            <div className="vm-modal">
                <button className="vm-close" onClick={onClose}>&times;</button>
                <h2>Verifikasi Peminjaman</h2>

                {error && <div className="vm-error">{error}</div>}

                {step === 1 && (
                    <form onSubmit={handleSearch} className="vm-form">
                        <p className="vm-desc">Scan QR Code atau ketik kode peminjaman secara manual (contoh: PMJ-A60A2A).</p>
                        <input 
                            type="text" 
                            className="vm-input" 
                            placeholder="PMJ-XXXXXX"
                            value={kode}
                            onChange={e => setKode(e.target.value.toUpperCase())}
                            autoFocus
                        />
                        <button type="submit" className="vm-btn-primary" disabled={loading}>
                            {loading ? 'Mencari...' : 'Cari Data'}
                        </button>
                    </form>
                )}

                {step === 2 && dataPem && (
                    <form onSubmit={handleSubmit} className="vm-form">
                        <div className="vm-info-card">
                            <div className="vm-row"><span>Kode</span><strong>PMJ-{genCode(dataPem.id_peminjaman)}</strong></div>
                            <div className="vm-row"><span>Peminjam</span><strong>{dataPem.nama_user}</strong></div>
                            <div className="vm-row"><span>Barang</span><strong>{dataPem.nama_barang} ({dataPem.jumlah} unit)</strong></div>
                            <div className="vm-row"><span>Tgl Pinjam</span><strong>{fmtDate(dataPem.tanggal_pinjam)}</strong></div>
                            <div className="vm-row"><span>Tgl Kembali</span><strong>{fmtDate(dataPem.tanggal_kembali)}</strong></div>
                            
                            {/* Baris Dokumen */}
                            <div className="vm-row">
                                <span>Dokumen</span>
                                <strong style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                                    {dataPem.bukti_ktm && (
                                        <button 
                                            type="button" 
                                            className="vm-doc-icon" 
                                            title="Lihat KTM"
                                            onClick={() => setPreviewImg(dataPem.bukti_ktm)}
                                        >
                                            📄 <span style={{ fontSize: '12px', color: '#3b82f6' }}>KTM</span>
                                        </button>
                                    )}
                                    {dataPem.bukti_wajah && (
                                        <button 
                                            type="button" 
                                            className="vm-doc-icon" 
                                            title="Lihat Selfie"
                                            onClick={() => setPreviewImg(dataPem.bukti_wajah)}
                                        >
                                            📸 <span style={{ fontSize: '12px', color: '#3b82f6' }}>Selfie</span>
                                        </button>
                                    )}
                                </strong>
                            </div>

                            <div className="vm-row">
                                <span>Tindakan</span>
                                <strong style={{ color: '#2563eb' }}>
                                    {dataPem.status === 'disetujui' ? 'Menyerahkan Barang (Ubah ke Diambil)' : 'Menerima Barang (Ubah ke Selesai)'}
                                </strong>
                            </div>
                        </div>

                        <div className="vm-upload-group">
                            <label>Unggah Foto Bukti (Wajib)</label>
                            <input 
                                type="file" 
                                accept="image/*" 
                                capture="environment"
                                onChange={e => setFileBukti(e.target.files[0])}
                            />
                        </div>

                        <div className="vm-actions">
                            <button type="button" className="vm-btn-secondary" onClick={() => setStep(1)}>Kembali</button>
                            <button type="submit" className="vm-btn-primary" disabled={loading}>
                                {loading ? 'Menyimpan...' : 'Simpan & Perbarui Status'}
                            </button>
                        </div>
                    </form>
                )}
            </div>
        </div>,
        document.body
    );
}
