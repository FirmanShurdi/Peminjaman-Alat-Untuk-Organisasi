import React, { useState, useEffect, useRef } from 'react';
import Flash from '../../partials/Flash';
import { authFetch } from '../../utils/authFetch';
import './BookingModal.css';

const API = 'http://localhost:3000';
const MONTHS = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
const DAYS = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

function fmt(iso) {
  if (!iso) return '—';
  const d = new Date(iso);
  return d.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
}

function diffDays(a, b) {
  if (!a || !b) return 0;
  return Math.round((new Date(b) - new Date(a)) / 86400000) + 1;
}

/* ── File Upload ─────────────────────────────────────── */
function FileField({ id, label, file, onChange, onRemove }) {
  const ref = useRef();
  const [lb, setLb] = useState(false);
  const isImg = file?.type?.startsWith('image/');
  const url = file ? URL.createObjectURL(file) : null;

  return (
    <div className="bm-ff">
      <span className="bm-ff-label">{label}</span>
      {!file ? (
        <div className="bm-dz" role="button" tabIndex={0}
          onClick={() => ref.current.click()}
          onDragOver={e => e.preventDefault()}
          onDrop={e => { e.preventDefault(); const f = e.dataTransfer.files[0]; if (f) onChange(f); }}
          onKeyDown={e => e.key === 'Enter' && ref.current.click()}>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
            <polyline points="16 16 12 12 8 16" /><line x1="12" y1="12" x2="12" y2="21" />
            <path d="M20.39 18.39A5 5 0 0 0 18 9h-1.26A8 8 0 1 0 3 16.3" />
          </svg>
          <p>Klik atau drag file</p>
          <span>PNG · JPG · PDF — maks. 5MB</span>
        </div>
      ) : (
        <div className="bm-prev">
          {isImg
            ? <img src={url} alt={file.name} onClick={() => setLb(true)} title="Klik untuk lihat penuh" />
            : <div className="bm-prev-pdf">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z" />
                <polyline points="14 2 14 8 20 8" />
              </svg>
            </div>
          }
          <span title={file.name}>{file.name}</span>
          <div className="bm-prev-acts">
            {isImg && <button type="button" className="bm-pv" onClick={() => setLb(true)}>👁</button>}
            <button type="button" className="bm-pd" onClick={onRemove}>✕</button>
          </div>
        </div>
      )}
      <input ref={ref} id={id} type="file" accept="image/*,.pdf" style={{ display: 'none' }}
        onChange={e => { if (e.target.files[0]) onChange(e.target.files[0]); e.target.value = ''; }} />
      {lb && isImg && (
        <div className="bm-lb" onClick={() => setLb(false)}>
          <button className="bm-lb-x" onClick={() => setLb(false)}>✕</button>
          <img src={url} alt={file.name} onClick={e => e.stopPropagation()} />
        </div>
      )}
    </div>
  );
}

/* ── Main Modal ──────────────────────────────────────── */
export default function BookingModal({ barang, bookedDates = [], onClose, onSuccess }) {
  const todayStr = new Date().toISOString().split('T')[0];

  // Calendar state
  const [view, setView] = useState(() => { const d = new Date(); return new Date(d.getFullYear(), d.getMonth(), 1); });
  const [pickStep, setPick] = useState('start'); // 'start' | 'end'
  const [hovered, setHovered] = useState(null);

  // Form state
  const [tPinjam, setTPinjam] = useState('');
  const [tKembali, setTKembali] = useState('');
  const [jumlah, setJumlah] = useState(1);
  const [catatan, setCatatan] = useState('');
  const [fileKtm, setFileKtm] = useState(null);
  const [fileWajah, setFileWajah] = useState(null);
  const [step, setStep] = useState(1);
  const [loading, setLoading] = useState(false);
  const [toasts, setToasts] = useState([]);

  const addToast = (type, message) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4500);
  };
  const removeToast = (id) => setToasts(prev => prev.filter(t => t.id !== id));

  // Lock scroll + Escape
  useEffect(() => { document.body.style.overflow = 'hidden'; return () => { document.body.style.overflow = ''; }; }, []);
  useEffect(() => {
    const h = e => { if (e.key === 'Escape') onClose(); };
    window.addEventListener('keydown', h);
    return () => window.removeEventListener('keydown', h);
  }, [onClose]);

  const year = view.getFullYear(), month = view.getMonth();
  const firstDay = new Date(year, month, 1).getDay();
  const daysInMonth = new Date(year, month + 1, 0).getDate();

  const toISO = (d) => {
    const dd = new Date(year, month, d);
    return dd.toISOString().split('T')[0];
  };

  const isBooked = (d) => {
    const iso = toISO(d);
    return bookedDates.some(r => iso >= r.tanggal_pinjam && iso <= r.tanggal_kembali);
  };

  const isPast = (d) => toISO(d) < todayStr;

  const isInRange = (d) => {
    const iso = toISO(d);
    const end = pickStep === 'end' && hovered ? hovered : tKembali;
    if (!tPinjam || !end) return false;
    const s = tPinjam < end ? tPinjam : end;
    const e = tPinjam < end ? end : tPinjam;
    return iso > s && iso < e;
  };

  const handleDayClick = (d) => {
    if (isPast(d) || isBooked(d)) return;
    const iso = toISO(d);
    if (pickStep === 'start') {
      setTPinjam(iso); setTKembali(''); setPick('end');
    } else {
      if (iso < tPinjam) { 
        setTPinjam(iso); setTKembali(''); setPick('end'); 
      }
      else { 
        let hasConflict = false;
        if (bookedDates && bookedDates.length > 0) {
          for (const b of bookedDates) {
            if (b.tanggal_pinjam <= iso && b.tanggal_kembali >= tPinjam) {
              hasConflict = true;
              break;
            }
          }
        }
        if (hasConflict) {
          addToast('error', 'Rentang tanggal bertabrakan dengan jadwal yang sudah dibooking.');
          return;
        }
        setTKembali(iso); setPick('start'); 
      }
    }
  };

  const cells = [];
  for (let i = 0; i < firstDay; i++) cells.push(null);
  for (let d = 1; d <= daysInMonth; d++) cells.push(d);

  const goNext = () => {
    if (!tPinjam || !tKembali) { addToast('error', 'Pilih tanggal pinjam dan kembali dari kalender.'); return; }
    if (!catatan.trim()) { addToast('error', 'Catatan / keperluan wajib diisi.'); return; }
    setStep(2);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!tPinjam || !tKembali) { addToast('error', 'Tanggal belum dipilih.'); setStep(1); return; }
    if (!catatan.trim()) { addToast('error', 'Catatan / keperluan wajib diisi.'); setStep(1); return; }
    if (!fileKtm) { addToast('error', 'Foto / Scan KTM wajib diunggah.'); return; }
    if (!fileWajah) { addToast('error', 'Foto selfie / wajah wajib diunggah.'); return; }
    setLoading(true);
    try {
      const fd = new FormData();
      fd.append('id_barang', barang.id_barang);
      fd.append('jumlah', jumlah);
      fd.append('tanggal_pinjam', tPinjam);
      fd.append('tanggal_kembali', tKembali);
      fd.append('catatan_user', catatan);
      fd.append('bukti_ktm', fileKtm);
      fd.append('bukti_wajah', fileWajah);

      const res = await authFetch(`${API}/peminjaman`, { method: 'POST', body: fd });
      const data = await res.json();
      if (!res.ok) throw new Error(data.message || 'Gagal mengajukan peminjaman.');
      onSuccess && onSuccess(data.message || 'Pengajuan berhasil dikirim!');
      onClose();
    } catch (err) { addToast('error', err.message); }
    finally { setLoading(false); }
  };

  // imgSrc dihapus — gambar tidak ditampilkan di form

  const durasi = diffDays(tPinjam, tKembali);

  return (
    <>
      <Flash toasts={toasts} removeToast={removeToast} />
      <div className="bm-backdrop" onClick={onClose} />
      <div className="bm-panel" role="dialog" aria-modal="true">

        {/* Header */}
        <div className="bm-header">
          <div className="bm-hd-left">
            <div>
              <p className="bm-hd-cat">{barang?.nama_kategori || 'Umum'}</p>
              <h2 className="bm-hd-name">{barang?.nama_barang}</h2>
              <div className="bm-hd-chips">
                {barang?.lokasi && <span className="bm-chip">📍 {barang.lokasi}</span>}
                {barang?.kondisi && <span className="bm-chip">🔧 {barang.kondisi}</span>}
                <span className={`bm-chip ${barang?.stok > 0 ? 'bm-chip-green' : 'bm-chip-red'}`}>
                  {barang?.stok > 0 ? `✓ ${barang.stok} unit tersedia` : '✗ Stok habis'}
                </span>
              </div>
            </div>
          </div>
          <button className="bm-close" onClick={onClose} aria-label="Tutup">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" />
            </svg>
          </button>
        </div>

        {/* Steps */}
        <div className="bm-steps">
          <div className={`bm-step ${step >= 1 ? 'active' : ''}`}>
            <div className="bm-step-dot">{step > 1 ? '✓' : '1'}</div>
            <span>Pilih Jadwal</span>
          </div>
          <div className="bm-step-line" />
          <div className={`bm-step ${step >= 2 ? 'active' : ''}`}>
            <div className="bm-step-dot">2</div>
            <span>Dokumen</span>
          </div>
        </div>

        <form className="bm-form" onSubmit={handleSubmit}>

          {/* ── STEP 1: Kalender + Panel kanan ── */}
          {step === 1 && (
            <div className="bm-s1">
              {/* Kiri: Kalender */}
              <div className="bm-cal-wrap">
                <div className="bm-cal-hint">
                  {pickStep === 'start' ? 'Pilih tanggal mulai pinjam' : 'Pilih tanggal selesai / kembali'}
                </div>
                <div className="bm-cal-nav">
                  <button type="button" onClick={() => setView(new Date(year, month - 1, 1))}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6" /></svg>
                  </button>
                  <span>{MONTHS[month]} {year}</span>
                  <button type="button" onClick={() => setView(new Date(year, month + 1, 1))}>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="9 18 15 12 9 6" /></svg>
                  </button>
                </div>
                <div className="bm-cal-grid">
                  {DAYS.map(w => <div key={w} className="bm-cal-wd">{w}</div>)}
                  {cells.map((d, i) => {
                    if (!d) return <div key={`e${i}`} />;
                    const iso = toISO(d);
                    const past = isPast(d);
                    const booked = isBooked(d);
                    const inRange = isInRange(d);
                    const isStart = iso === tPinjam;
                    const isEnd = iso === tKembali;
                    const isHov = hovered === iso && pickStep === 'end';
                    return (
                      <div key={d}
                        className={[
                          'bm-cal-d',
                          past || booked ? 'bm-d-off' : 'bm-d-on',
                          booked ? 'bm-d-booked' : '',
                          isStart ? 'bm-d-start' : '',
                          isEnd ? 'bm-d-end' : '',
                          inRange ? 'bm-d-range' : '',
                          isHov ? 'bm-d-hover' : '',
                        ].join(' ').trim()}
                        onClick={() => handleDayClick(d)}
                        onMouseEnter={() => pickStep === 'end' && setHovered(iso)}
                        onMouseLeave={() => setHovered(null)}
                        role="button" tabIndex={past || booked ? -1 : 0}
                        onKeyDown={e => e.key === 'Enter' && handleDayClick(d)}
                        aria-label={`${d} ${MONTHS[month]} ${year}`}
                        aria-disabled={past || booked}
                      >{d}</div>
                    );
                  })}
                </div>
                <div className="bm-cal-leg">
                  <span><span className="bm-leg bm-leg-av" />Tersedia</span>
                  <span><span className="bm-leg bm-leg-bk" />Dibooking</span>
                  <span><span className="bm-leg bm-leg-sel" />Dipilih</span>
                </div>
              </div>

              {/* Kanan: Ringkasan & field */}
              <div className="bm-s1-right">
                <div className="bm-date-cards">
                  <div className={`bm-date-card ${pickStep === 'start' ? 'bm-dc-active' : ''}`}
                    onClick={() => { setPick('start'); setTKembali(''); }}>
                    <span className="bm-dc-label">Tanggal Pinjam</span>
                    <span className="bm-dc-val">{tPinjam ? fmt(tPinjam) : <em>Belum dipilih</em>}</span>
                  </div>
                  <div className="bm-dc-arrow">→</div>
                  <div className={`bm-date-card ${pickStep === 'end' && tPinjam ? 'bm-dc-active' : ''}`}>
                    <span className="bm-dc-label">Tanggal Kembali</span>
                    <span className="bm-dc-val">{tKembali ? fmt(tKembali) : <em>Belum dipilih</em>}</span>
                  </div>
                </div>

                {tPinjam && tKembali && (
                  <div className="bm-durasi">
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" />
                    </svg>
                    Durasi: <strong>{durasi} hari</strong>
                  </div>
                )}

                <div className="bm-field">
                  <label className="bm-lbl">Jumlah Unit</label>
                  <div className="bm-qty">
                    <button type="button" onClick={() => setJumlah(j => Math.max(1, j - 1))}>−</button>
                    <span>{jumlah}</span>
                    <button type="button" onClick={() => setJumlah(j => Math.min(barang?.stok || 99, j + 1))}>+</button>
                  </div>
                </div>

                <div className="bm-field" style={{ flex: 1 }}>
                  <label className="bm-lbl" htmlFor="catatan">
                    Catatan / Keperluan <span className="bm-req">*</span>
                  </label>
                  <textarea id="catatan" className="bm-ta" rows={4}
                    placeholder="Jelaskan tujuan peminjaman..."
                    value={catatan} onChange={e => setCatatan(e.target.value)}
                    required />
                </div>
              </div>
            </div>
          )}

          {/* ── STEP 2: Dokumen ── */}
          {step === 2 && (
            <div className="bm-s2">

              <div className="bm-uploads">
                <FileField id="ktm" label="📄 KTM (Wajib)"
                  file={fileKtm} onChange={setFileKtm} onRemove={() => setFileKtm(null)} />
                <FileField id="wajah" label="📸 Foto Selfie / Wajah (Wajib)"
                  file={fileWajah} onChange={setFileWajah} onRemove={() => setFileWajah(null)} />
              </div>

              {/* Ringkasan */}
              <div className="bm-summary">
                <h4>Ringkasan Pengajuan</h4>
                <div className="bm-sum-row"><span>Barang</span><strong>{barang?.nama_barang}</strong></div>
                <div className="bm-sum-row"><span>Tanggal Pinjam</span><strong>{fmt(tPinjam)}</strong></div>
                <div className="bm-sum-row"><span>Tanggal Kembali</span><strong>{fmt(tKembali)}</strong></div>
                <div className="bm-sum-row"><span>Durasi</span><strong>{durasi} hari</strong></div>
                <div className="bm-sum-row"><span>Jumlah</span><strong>{jumlah} unit</strong></div>
                {catatan && <div className="bm-sum-row"><span>Catatan</span><strong>{catatan}</strong></div>}
              </div>
            </div>
          )}

          <div className="bm-footer">
            {step === 1 ? (
              <>
                <button type="button" className="bm-btn-sec" onClick={onClose}>Batal</button>
                <button type="button" className="bm-btn-pri" onClick={goNext}>
                  Lanjut Upload Dokumen
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="9 18 15 12 9 6" /></svg>
                </button>
              </>
            ) : (
              <>
                <button type="button" className="bm-btn-sec" onClick={() => setStep(1)}>
                  <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polyline points="15 18 9 12 15 6" /></svg>
                  Kembali
                </button>
                <button type="submit" className="bm-btn-pri" disabled={loading}>
                  {loading ? <span className="bm-spin" /> : <>
                    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="22" y1="2" x2="11" y2="13" /><polygon points="22 2 15 22 11 13 2 9 22 2" /></svg>
                    Kirim Pengajuan
                  </>}
                </button>
              </>
            )}
          </div>
        </form>
      </div>
    </>
  );
}
