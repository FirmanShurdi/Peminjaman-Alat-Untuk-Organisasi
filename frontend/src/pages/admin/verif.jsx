import React, { useState, useEffect } from 'react';
import ReactDOM from 'react-dom';
import { useNavigate } from 'react-router-dom';
import { Scanner } from '@yudiel/react-qr-scanner';
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
    const [dataItems, setDataItems] = useState([]);
    const [checkedItems, setCheckedItems] = useState(new Set());
    const [fileBukti, setFileBukti] = useState(null);
    const [previewImg, setPreviewImg] = useState(null); // State untuk fullscreen image
    const [catatanAdmin, setCatatanAdmin] = useState('');
    const [useScan, setUseScan] = useState(false); // State untuk toggle scanner
    const [masalahState, setMasalahState] = useState({}); // { id_peminjaman: { status: 'selesai'|'bermasalah', jenisDenda: 'penggantian'|'denda' } }

    // Helper function untuk pencarian
    const performSearch = async (targetKode) => {
        setError('');
        if (!targetKode) return setError('Masukkan kode verifikasi.');

        setLoading(true);
        try {
            const res = await authFetch(`${API}/peminjaman`);
            const json = await res.json();
            if (json.status !== 'success') throw new Error('Gagal memuat data.');

            const allData = json.data;
            const cleanedInput = targetKode.replace('PMJ-', '').toUpperCase().trim();

            const foundItems = allData.filter(p => {
                const dbCode = p.no_pesanan ? p.no_pesanan.toUpperCase() : genCode(p.id_peminjaman);
                return dbCode === cleanedInput || String(p.id_peminjaman) === cleanedInput;
            });

            if (foundItems.length === 0) {
                throw new Error('Kode peminjaman tidak ditemukan.');
            }

            const processableItems = foundItems.filter(p => ['menunggu', 'disetujui', 'diambil', 'terlambat', 'bermasalah'].includes(p.status));

            if (processableItems.length === 0) {
                throw new Error('Semua barang dengan kode ini tidak dapat diproses (peminjaman telah selesai/ditolak).');
            }

            setDataItems(processableItems);
            setCheckedItems(new Set(processableItems.map(p => p.id_peminjaman)));
            setStep(2);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    // Step 1: Cari Data (Form submit)
    const handleSearch = (e) => {
        e.preventDefault();
        performSearch(kode);
    };

    // Step 2: Proses Simpan
    const handleSubmit = async (e) => {
        e.preventDefault();

        // Validasi unggah bukti jika ada item yang disetujui untuk diambil/selesai
        const needsBukti = dataItems.some(item => {
            if (!checkedItems.has(item.id_peminjaman)) return false;
            let nextStatus;
            if (item.status === 'menunggu') nextStatus = 'disetujui';
            else if (item.status === 'disetujui') nextStatus = 'diambil';
            else if (item.status === 'bermasalah') nextStatus = 'selesai';
            else {
                const ms = masalahState[item.id_peminjaman];
                nextStatus = (ms && ms.status === 'bermasalah') ? 'bermasalah' : 'selesai';
            }
            return nextStatus === 'diambil' || nextStatus === 'selesai';
        });

        if (needsBukti && !fileBukti) {
            return setError('Foto bukti serah/terima wajib diunggah.');
        }

        setLoading(true);
        try {
            let processedCount = 0;
            for (const item of dataItems) {
                const isChecked = checkedItems.has(item.id_peminjaman);
                
                // Jika tidak dicentang dan statusnya bukan menunggu, berarti dilewati saja
                if (!isChecked && item.status !== 'menunggu') continue;

                let nextStatus;
                let jenisDenda = null;

                if (!isChecked) {
                    nextStatus = 'ditolak';
                } else {
                    if (item.status === 'menunggu') nextStatus = 'disetujui';
                    else if (item.status === 'disetujui') nextStatus = 'diambil';
                    else if (item.status === 'bermasalah') nextStatus = 'selesai';
                    else {
                        const ms = masalahState[item.id_peminjaman];
                        if (ms && ms.status === 'bermasalah') {
                            nextStatus = 'bermasalah';
                            jenisDenda = ms.jenisDenda || 'penggantian';
                            const fd = new FormData();
                            fd.append('status', nextStatus);
                            if (jenisDenda) fd.append('jenis_denda', jenisDenda);
                            if (jenisDenda === 'denda' && ms.nominalDenda) fd.append('nominal_denda', ms.nominalDenda);
                            if (jenisDenda === 'penggantian' && ms.jumlahGanti) fd.append('jumlah_ganti', ms.jumlahGanti);
                            
                            if (catatanAdmin.trim()) fd.append('catatan_admin', catatanAdmin.trim());
                            // no file_bukti appended yet since it will be appended below if applicable, actually fileBukti is not for bermasalah usually, but let's append anyway
                            if (fileBukti) fd.append('bukti', fileBukti);

                            const res = await authFetch(`${API}/peminjaman/${item.id_peminjaman}/status`, {
                                method: 'PATCH',
                                body: fd
                            });
                            if (!res.ok) {
                                const errData = await res.json();
                                setError(`Gagal update item ${item.id_peminjaman}: ${errData.message}`);
                                console.error(`Gagal update item ${item.id_peminjaman}`, errData);
                            }
                            else processedCount++;
                            continue; // Skip the standard form submission below
                        } else {
                            nextStatus = 'selesai';
                        }
                    }
                }

                const fd = new FormData();
                fd.append('status', nextStatus);
                if (jenisDenda) fd.append('jenis_denda', jenisDenda);
                if (catatanAdmin.trim()) fd.append('catatan_admin', catatanAdmin.trim());

                if (fileBukti && (nextStatus === 'diambil' || nextStatus === 'selesai')) {
                    fd.append('bukti', fileBukti);
                }

                const res = await authFetch(`${API}/peminjaman/${item.id_peminjaman}/status`, {
                    method: 'PATCH',
                    body: fd
                });

                if (!res.ok) {
                    const errData = await res.json().catch(() => ({}));
                    setError(`Gagal update item ${item.id_peminjaman}: ${errData.message || 'Error tidak diketahui'}`);
                    console.error(`Gagal update item ${item.id_peminjaman}:`, errData);
                } else {
                    processedCount++;
                }
            }

            localStorage.setItem('_flash', JSON.stringify({ type: 'success', message: `Berhasil memproses ${processedCount} barang.` }));
            window.location.reload(); // Reload halaman untuk update data di tabel/dashboard
        } catch (err) {
            setError(err.message);
            setLoading(false);
        }
    };

    if (!document.body) return null;

    return ReactDOM.createPortal(
        <div className="vm-overlay">
            {/* Fullscreen Image/PDF Preview */}
            {previewImg && (
                <div className="vm-img-preview-overlay" onClick={() => setPreviewImg(null)}>
                    <button className="vm-img-preview-close" onClick={() => setPreviewImg(null)}>&times;</button>
                    {previewImg.toLowerCase().endsWith('.pdf') ? (
                        <iframe 
                            src={previewImg.startsWith('blob:') || previewImg.startsWith('http') ? previewImg : `${API}/${previewImg}`} 
                            className="vm-img-preview" 
                            style={{ background: '#fff', width: '80%', height: '80%', border: 'none', borderRadius: '8px' }}
                            title="Preview Dokumen"
                            onClick={(e) => e.stopPropagation()}
                        />
                    ) : (
                        <img src={previewImg.startsWith('blob:') || previewImg.startsWith('http') ? previewImg : `${API}/${previewImg}`} alt="Preview Dokumen" className="vm-img-preview" onClick={(e) => e.stopPropagation()} />
                    )}
                </div>
            )}

            <div className="vm-modal">
                <button className="vm-close" onClick={onClose}>&times;</button>
                <h2>Verifikasi Peminjaman</h2>

                {error && <div className="vm-error">{error}</div>}

                {step === 1 && (
                    <div className="vm-form">
                        <p className="vm-desc">Scan QR Code atau ketik kode peminjaman secara manual (contoh: PMJ-A60A2A).</p>
                        
                        {useScan && (
                            <div style={{ width: '100%', maxWidth: '300px', margin: '0 auto 16px', borderRadius: '12px', overflow: 'hidden', border: '2px solid #cbd5e1' }}>
                                <Scanner 
                                    onScan={(result) => {
                                        if (result && result.length > 0) {
                                            const scannedCode = result[0].rawValue;
                                            setKode(scannedCode);
                                            setUseScan(false);
                                            performSearch(scannedCode);
                                        }
                                    }}
                                    onError={(e) => console.log(e)}
                                />
                                <p style={{ textAlign: 'center', fontSize: '12px', padding: '8px', background: '#f8fafc', margin: 0 }}>Arahkan kamera ke QR Code</p>
                            </div>
                        )}

                        <form onSubmit={handleSearch} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                            <div style={{ position: 'relative' }}>
                                <input
                                    type="text"
                                    className="vm-input"
                                    placeholder="PMJ-XXXXXX"
                                    value={kode}
                                    onChange={e => setKode(e.target.value.toUpperCase())}
                                    autoFocus
                                    style={{ paddingRight: '50px' }}
                                />
                                <button
                                    type="button"
                                    onClick={() => setUseScan(!useScan)}
                                    title="Gunakan Kamera Scanner"
                                    className="vm-btn-scan-inline"
                                >
                                    <svg viewBox="0 0 24 24" width="24" height="24" stroke="currentColor" strokeWidth="2" fill="none" strokeLinecap="round" strokeLinejoin="round">
                                        <path d="M3 7V5a2 2 0 0 1 2-2h2"></path>
                                        <path d="M17 3h2a2 2 0 0 1 2 2v2"></path>
                                        <path d="M21 17v2a2 2 0 0 1-2 2h-2"></path>
                                        <path d="M7 21H5a2 2 0 0 1-2-2v-2"></path>
                                        <circle cx="12" cy="12" r="3"></circle>
                                    </svg>
                                </button>
                            </div>
                            <button type="submit" className="vm-btn-primary" disabled={loading}>
                                {loading ? 'Mencari...' : 'Cari Data'}
                            </button>
                        </form>
                    </div>
                )}


                {step === 2 && dataItems.length > 0 && (
                    <form onSubmit={handleSubmit} className="vm-form">
                        <div className="vm-info-card">
                            <div className="vm-row"><span>Kode</span><strong>PMJ-{dataItems[0].no_pesanan || genCode(dataItems[0].id_peminjaman)}</strong></div>
                            <div className="vm-row"><span>Peminjam</span><strong>{dataItems[0].nama_user}</strong></div>

                            {/* Baris Dokumen */}
                            <div className="vm-row">
                                <span>Dokumen</span>
                                <strong style={{ display: 'flex', gap: '12px', justifyContent: 'flex-end' }}>
                                    {dataItems[0].bukti_ktm && (
                                        <button
                                            type="button"
                                            className="vm-doc-icon"
                                            title="Lihat KTM"
                                            onClick={() => setPreviewImg(dataItems[0].bukti_ktm)}
                                        >
                                            📄 <span style={{ fontSize: '12px', color: '#3b82f6' }}>KTM</span>
                                        </button>
                                    )}
                                    {dataItems[0].bukti_wajah && (
                                        <button
                                            type="button"
                                            className="vm-doc-icon"
                                            title="Lihat Selfie"
                                            onClick={() => setPreviewImg(dataItems[0].bukti_wajah)}
                                        >
                                            📸 <span style={{ fontSize: '12px', color: '#3b82f6' }}>Selfie</span>
                                        </button>
                                    )}
                                    {dataItems[0].surat_permohonan && (
                                        <button
                                            type="button"
                                            className="vm-doc-icon"
                                            title="Lihat Surat"
                                            onClick={() => setPreviewImg(dataItems[0].surat_permohonan)}
                                        >
                                            📑 <span style={{ fontSize: '12px', color: '#3b82f6' }}>Surat</span>
                                        </button>
                                    )}
                                </strong>
                            </div>

                            <div style={{ marginTop: '15px' }}>
                                <span style={{ fontSize: '13px', color: '#64748b' }}>Daftar Barang (Centang untuk memproses)</span>
                                {dataItems.map(item => {
                                    const isChecked = checkedItems.has(item.id_peminjaman);
                                    let isReturning = item.status === 'diambil' || item.status === 'terlambat';
                                    let ms = masalahState[item.id_peminjaman] || { status: 'selesai', jenisDenda: 'penggantian' };
                                    
                                    let textStatus;
                                    if (isChecked) {
                                        if (item.status === 'menunggu') textStatus = 'Disetujui';
                                        else if (item.status === 'disetujui') textStatus = 'Diambil';
                                        else if (item.status === 'bermasalah') textStatus = 'Selesai (Masalah Terselesaikan)';
                                        else textStatus = ms.status === 'bermasalah' ? 'Bermasalah' : 'Selesai';
                                    } else {
                                        if (item.status === 'menunggu') textStatus = 'Ditolak';
                                        else textStatus = 'Dilewati (Tetap)';
                                    }

                                    return (
                                        <div key={item.id_peminjaman} style={{ display: 'flex', flexDirection: 'column', marginTop: '10px', background: isChecked ? '#f8fafc' : '#fef2f2', borderRadius: '6px', border: `1px solid ${isChecked ? '#e2e8f0' : '#fecaca'}` }}>
                                            <label style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '10px', cursor: 'pointer' }}>
                                            <input
                                                type="checkbox"
                                                checked={isChecked}
                                                onChange={(e) => {
                                                    const newSet = new Set(checkedItems);
                                                    if (e.target.checked) newSet.add(item.id_peminjaman);
                                                    else newSet.delete(item.id_peminjaman);
                                                    setCheckedItems(newSet);
                                                }}
                                                style={{ width: '18px', height: '18px', cursor: 'pointer' }}
                                            />
                                            <div style={{ flex: 1, display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                                <div>
                                                    <strong style={{ display: 'block', color: '#334155', fontSize: '14px' }}>{item.nama_barang} ({item.jumlah} unit)</strong>
                                                    <span style={{ fontSize: '12px', color: isChecked ? '#3b82f6' : '#dc2626' }}>
                                                        Status akan menjadi: <strong>{textStatus}</strong>
                                                    </span>
                                                </div>
                                                {item.gambar && (
                                                    <img
                                                        src={item.gambar.startsWith('http') ? item.gambar : `${API}/barang/${item.gambar}`}
                                                        alt={item.nama_barang}
                                                        style={{ width: '40px', height: '40px', objectFit: 'cover', borderRadius: '6px', cursor: 'pointer', border: '1px solid #cbd5e1', marginLeft: '10px' }}
                                                        onClick={(e) => {
                                                            e.preventDefault();
                                                            setPreviewImg(item.gambar.startsWith('http') ? item.gambar : `barang/${item.gambar}`);
                                                        }}
                                                        title="Klik untuk perbesar"
                                                    />
                                                )}
                                            </div>
                                            </label>

                                            {isChecked && isReturning && (
                                                <div style={{ padding: '0 10px 10px 38px' }}>
                                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', background: '#fff', padding: '10px', border: '1px solid #e2e8f0', borderRadius: '6px' }} onClick={e => e.stopPropagation()}>
                                                        <select 
                                                            value={ms.status} 
                                                            onChange={e => setMasalahState({...masalahState, [item.id_peminjaman]: { ...ms, status: e.target.value }})}
                                                            style={{ padding: '6px', borderRadius: '4px', border: '1px solid #cbd5e1', fontSize: '13px', outline: 'none' }}
                                                        >
                                                            <option value="selesai">✅ Selesai Normal</option>
                                                            <option value="bermasalah">⚠️ Bermasalah (Rusak/Hilang)</option>
                                                        </select>
                                                        {ms.status === 'bermasalah' && (
                                                            <select
                                                                value={ms.jenisDenda}
                                                                onChange={e => setMasalahState({...masalahState, [item.id_peminjaman]: { ...ms, jenisDenda: e.target.value }})}
                                                                style={{ padding: '6px', borderRadius: '4px', border: '1px solid #fca5a5', fontSize: '13px', outline: 'none', color: '#be123c' }}
                                                            >
                                                                <option value="penggantian">Opsi: Penggantian Barang</option>
                                                                <option value="denda">Opsi: Denda (Kirim QRIS Otomatis)</option>
                                                            </select>
                                                        )}
                                                        {ms.status === 'bermasalah' && ms.jenisDenda === 'denda' && (
                                                            <input 
                                                                type="number"
                                                                placeholder="Nominal Denda (Rp)"
                                                                value={ms.nominalDenda || ''}
                                                                onChange={e => setMasalahState({...masalahState, [item.id_peminjaman]: { ...ms, nominalDenda: e.target.value }})}
                                                                style={{ padding: '6px', borderRadius: '4px', border: '1px solid #c4b5fd', fontSize: '13px', outline: 'none' }}
                                                            />
                                                        )}
                                                        {ms.status === 'bermasalah' && (!ms.jenisDenda || ms.jenisDenda === 'penggantian') && (
                                                            <input 
                                                                type="number"
                                                                placeholder={`Jumlah Ganti (Maks: ${item.jumlah})`}
                                                                value={ms.jumlahGanti || ''}
                                                                onChange={e => setMasalahState({...masalahState, [item.id_peminjaman]: { ...ms, jumlahGanti: e.target.value }})}
                                                                min="1"
                                                                max={item.jumlah}
                                                                style={{ padding: '6px', borderRadius: '4px', border: '1px solid #c4b5fd', fontSize: '13px', outline: 'none' }}
                                                            />
                                                        )}
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    );
                                })}
                            </div>
                        </div>

                        {dataItems.some(item => checkedItems.has(item.id_peminjaman) && item.status !== 'menunggu') && (
                            <div className="vm-upload-group">
                                <label>Unggah Foto Bukti (Wajib)</label>
                                {!fileBukti ? (
                                    <div style={{ display: 'flex', gap: '10px', marginTop: '8px' }}>
                                        <label style={{ flex: 1, textAlign: 'center', background: '#eff6ff', border: '1px solid #bfdbfe', color: '#2563eb', padding: '10px', borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: '600' }}>
                                            📷 Buka Kamera
                                            <input
                                                type="file"
                                                accept="image/*"
                                                capture="environment"
                                                onChange={e => e.target.files && setFileBukti(e.target.files[0])}
                                                style={{ display: 'none' }}
                                            />
                                        </label>
                                        <label style={{ flex: 1, textAlign: 'center', background: '#f8fafc', border: '1px solid #e2e8f0', color: '#475569', padding: '10px', borderRadius: '8px', cursor: 'pointer', fontSize: '13px', fontWeight: '600' }}>
                                            📁 Pilih File
                                            <input
                                                type="file"
                                                accept="image/*"
                                                onChange={e => e.target.files && setFileBukti(e.target.files[0])}
                                                style={{ display: 'none' }}
                                            />
                                        </label>
                                    </div>
                                ) : (
                                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', marginTop: '8px' }}>
                                        <div style={{ position: 'relative', cursor: 'pointer', borderRadius: '8px', overflow: 'hidden', border: '1px solid #cbd5e1' }} onClick={() => setPreviewImg(URL.createObjectURL(fileBukti))}>
                                            <img
                                                src={URL.createObjectURL(fileBukti)}
                                                alt="Preview Upload"
                                                style={{ width: '80px', height: '80px', objectFit: 'cover', display: 'block' }}
                                            />
                                            <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, background: 'rgba(0,0,0,0.6)', color: '#fff', fontSize: '10px', textAlign: 'center', padding: '4px 0' }}>Lihat Penuh</div>
                                        </div>
                                        <div>
                                            <p style={{ fontSize: '13px', fontWeight: '500', color: '#334155', margin: '0 0 6px 0', wordBreak: 'break-all' }}>{fileBukti.name}</p>
                                            <button
                                                type="button"
                                                onClick={() => setFileBukti(null)}
                                                style={{ background: '#fee2e2', color: '#ef4444', border: '1px solid #fca5a5', borderRadius: '4px', padding: '4px 8px', fontSize: '12px', fontWeight: 'bold', cursor: 'pointer' }}
                                            >
                                                Hapus / Ganti Foto
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                        )}

                        <div className="vm-upload-group" style={{ marginTop: '15px' }}>
                            <label>Catatan Admin (Opsional)</label>
                            <textarea
                                className="vm-input"
                                rows={2}
                                style={{ resize: 'vertical', width: '100%', minHeight: '60px' }}
                                placeholder="Tambahkan catatan jika diperlukan..."
                                value={catatanAdmin}
                                onChange={e => setCatatanAdmin(e.target.value)}
                            />
                        </div>

                        <div className="vm-actions">
                            <button type="button" className="vm-btn-secondary" onClick={() => setStep(1)}>Kembali</button>
                            <button type="submit" className="vm-btn-primary" disabled={loading}>
                                {loading ? 'Menyimpan...' : 'Setujui'}
                            </button>
                        </div>
                    </form>
                )}
            </div>
        </div>,
        document.body
    );
}
