import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import Navbar from '../partials/Navbar';
import Flash from '../partials/Flash';
import './Beranda.css';

const API = 'http://localhost:3000';
const TOTAL_SECTIONS = 4;

export default function Beranda() {
  const navigate = useNavigate();
  const user = useMemo(() => {
    try { return JSON.parse(localStorage.getItem('user') || 'null'); } catch { return null; }
  }, []);

  const [stat, setStat] = useState({ total_barang: 0, tersedia: 0, stok_habis: 0, dipinjam: 0, menunggu: 0 });
  const [barangList, setBarangList] = useState([]);
  const [lokasiList, setLokasiList] = useState(['Gudang Utama PENS']);
  const [currentLokasiIdx, setCurrentLokasiIdx] = useState(0);
  const [loaded, setLoaded] = useState(false);
  const [activeStep, setActiveStep] = useState(null);
  const [toasts, setToasts] = useState([]);
  const [currentSection, setCurrentSection] = useState(() => {
    return parseInt(sessionStorage.getItem('beranda_section') || '0', 10);
  });

  useEffect(() => {
    sessionStorage.setItem('beranda_section', currentSection.toString());
  }, [currentSection]);

  // Flash helpers
  const addToast = (type, message) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4500);
  };
  const removeToast = (id) => setToasts(prev => prev.filter(t => t.id !== id));

  // Pop global flash (e.g. from login redirect)
  useEffect(() => {
    try {
      const raw = localStorage.getItem('_flash');
      if (raw) {
        const flash = JSON.parse(raw);
        localStorage.removeItem('_flash');
        addToast(flash.type, flash.message);
      }
    } catch (_) {}
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  const [isTransitioning, setIsTransitioning] = useState(false);
  const [revealed, setRevealed] = useState([false, false, false, false]);
  const rootRef = useRef(null);

  useEffect(() => {
    (async () => {
      try {
        const [rStat, rBarang] = await Promise.all([
          fetch(`${API}/api/beranda/statistik`),
          fetch(`${API}/api/barang`)
        ]);
        const dStat = await rStat.json();
        const dBarang = await rBarang.json();

        if (dStat.status === 'success') setStat(dStat.data);
        if (dBarang.status === 'success') {
          setBarangList(dBarang.data.slice(0, 4));
          const uniqueLocs = [...new Set(dBarang.data.map(b => b.lokasi).filter(Boolean))];
          if (uniqueLocs.length > 0) setLokasiList(uniqueLocs);
        }
      } catch (e) { console.error(e); }
      setLoaded(true);
    })();
  }, []);

  useEffect(() => {
    if (lokasiList.length <= 1) return;
    const timer = setInterval(() => {
      setCurrentLokasiIdx(prev => (prev + 1) % lokasiList.length);
    }, 3000);
    return () => clearInterval(timer);
  }, [lokasiList]);

  // ── Cinematic scroll controller ──
  const goTo = useCallback((index) => {
    if (index < 0 || index >= TOTAL_SECTIONS || isTransitioning) return;
    setIsTransitioning(true);
    setCurrentSection(index);
    // Allow transition to complete before accepting new input
    setTimeout(() => setIsTransitioning(false), 1200);
  }, [isTransitioning]);

  useEffect(() => {
    const root = rootRef.current;
    if (!root) return;

    let touchStartY = 0;
    let initialScrollTop = 0;

    const checkBoundary = (delta) => {
      const activeCard = document.querySelector('.sec-active .card');
      if (!activeCard) return true;
      const isScrollable = activeCard.scrollHeight > activeCard.clientHeight;
      if (!isScrollable) return true;
      
      if (delta > 0) return Math.ceil(activeCard.scrollTop + activeCard.clientHeight) >= activeCard.scrollHeight - 5;
      if (delta < 0) return activeCard.scrollTop <= 5;
      return true;
    };

    const onWheel = (e) => {
      if (isTransitioning) { e.preventDefault(); return; }
      if (!checkBoundary(e.deltaY)) return; // Allow normal scroll inside card
      
      e.preventDefault();
      if (e.deltaY > 30) goTo(currentSection + 1);
      else if (e.deltaY < -30) goTo(currentSection - 1);
    };

    const onTouchStart = (e) => { 
      touchStartY = e.touches[0].clientY; 
      const activeCard = document.querySelector('.sec-active .card');
      initialScrollTop = activeCard ? activeCard.scrollTop : 0;
    };

    const onTouchEnd = (e) => {
      if (isTransitioning) return;
      const diff = touchStartY - e.changedTouches[0].clientY;
      
      const activeCard = document.querySelector('.sec-active .card');
      if (activeCard && activeCard.scrollHeight > activeCard.clientHeight) {
        if (diff > 0 && Math.ceil(initialScrollTop + activeCard.clientHeight) < activeCard.scrollHeight - 5) return;
        if (diff < 0 && initialScrollTop > 5) return;
      }

      if (diff > 50) goTo(currentSection + 1);
      else if (diff < -50) goTo(currentSection - 1);
    };

    const onKeyDown = (e) => {
      if (isTransitioning) return;
      if (e.key === 'ArrowDown' || e.key === 'PageDown') { e.preventDefault(); goTo(currentSection + 1); }
      if (e.key === 'ArrowUp' || e.key === 'PageUp') { e.preventDefault(); goTo(currentSection - 1); }
    };

    root.addEventListener('wheel', onWheel, { passive: false });
    root.addEventListener('touchstart', onTouchStart, { passive: true });
    root.addEventListener('touchend', onTouchEnd, { passive: true });
    window.addEventListener('keydown', onKeyDown);
    return () => {
      root.removeEventListener('wheel', onWheel);
      root.removeEventListener('touchstart', onTouchStart);
      root.removeEventListener('touchend', onTouchEnd);
      window.removeEventListener('keydown', onKeyDown);
    };
  }, [currentSection, isTransitioning, goTo]);

  // Reveal elements when section becomes active using React state
  useEffect(() => {
    if (!loaded) return;
    const timer = setTimeout(() => {
      setRevealed(prev => {
        if (prev[currentSection]) return prev;
        const next = [...prev];
        next[currentSection] = true;
        return next;
      });
    }, 300);
    return () => clearTimeout(timer);
  }, [currentSection, loaded]);

  // Section class helper
  const secClass = (index) => {
    if (index === currentSection) return 'sec-active';
    if (index < currentSection) return 'sec-above';
    return 'sec-below';
  };

  return (
    <div className="lp" ref={rootRef}>

      <Flash toasts={toasts} removeToast={removeToast} />
      <Navbar user={user} currentSection={currentSection} goTo={goTo} onFlash={addToast} />

      {/* ══════ CARD 1 — HERO ══════ */}
      <section className={`sec sec-hero ${secClass(0)}`} id="hero">
        <div className="deco-circle dc1" /><div className="deco-circle dc2" /><div className="deco-dots dd1" /><div className="deco-dots dd2" />

        <div className="container">
          <div className="card card-hero">
            <div className="hero-grid">
              {/* LEFT */}
              <div className="hero-left">
                <div className={`badge rv ${revealed[0] ? 'vis' : ''}`}>Platform Manajemen Eksklusif</div>
                <h1 className={`hero-h1 rv ${revealed[0] ? 'vis' : ''}`}>
                  Infrastruktur<br/>Inventaris<br/><span className="accent">Profesional</span>
                </h1>
                <p className={`hero-p rv ${revealed[0] ? 'vis' : ''}`}>
                  Kelola dan optimalkan peminjaman alat organisasi Anda dengan sistem cerdas yang aman, cepat, dan transparan.
                </p>
                <div className={`feats rv ${revealed[0] ? 'vis' : ''}`}>
                  <div className="feat">
                    <div className="feat-ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><path d="M9 12l2 2 4-4"/></svg></div>
                    <div><strong>Keamanan Data</strong><span>Verifikasi multi-lapis</span></div>
                  </div>
                  <div className="feat">
                    <div className="feat-ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg></div>
                    <div><strong>Akses Instan</strong><span>Persetujuan kilat</span></div>
                  </div>
                  <div className="feat">
                    <div className="feat-ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg></div>
                    <div><strong>Katalog Sentral</strong><span>100+ alat tersedia</span></div>
                  </div>
                  <div className="feat">
                    <div className="feat-ic"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><circle cx="12" cy="12" r="10"/><path d="M12 16v-4"/><path d="M12 8h.01"/></svg></div>
                    <div><strong>Sistem Intuitif</strong><span>Booking anti-ribet</span></div>
                  </div>
                </div>
                <div className={`hero-btns rv ${revealed[0] ? 'vis' : ''}`}>
                  <button onClick={() => goTo(2)} className="btn-pri" style={{fontFamily:'inherit'}}>Pinjam Sekarang <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg></button>
                  <button onClick={() => goTo(2)} className="btn-sec" style={{fontFamily:'inherit'}}>Lihat Katalog</button>
                </div>
                <div className={`trust rv ${revealed[0] ? 'vis' : ''}`}>
                  <div className="trust-avatars">
                    {['A','B','C','D','E'].map((c,i) => <div key={i} className="ta" style={{zIndex:5-i}}>{c}</div>)}
                  </div>
                  <span>Dipercaya <strong>500+</strong> organisasi</span>
                </div>
              </div>

              {/* RIGHT */}
              <div className={`hero-right rv ${revealed[0] ? 'vis' : ''}`}>
                <div className="hero-img-wrap">
                  <img src="/intro/intro.png" alt="Alat Organisasi" className="hero-img" />
                  
                  {/* Floating Badges with elegant design */}
                  <div className="fb fb1">
                    <div className="fb-ic" style={{background: '#dcfce7', color: '#16a34a'}}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg></div>
                    <div><b>Status Real-time</b><small>Tersedia 24/7</small></div>
                  </div>
                  
                  <div className="fb fb2">
                    <div className="fb-ic" style={{background: '#eff6ff', color: '#2563eb'}}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></svg></div>
                    <div><b>Persetujuan</b><small>Sistem Cepat</small></div>
                  </div>
                  
                  <div className="fb fb3">
                    <div className="fb-ic" style={{background: '#fef3c7', color: '#d97706'}}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><polygon points="12 2 2 7 12 12 22 7 12 2"/><polyline points="2 17 12 22 22 17"/><polyline points="2 12 12 17 22 12"/></svg></div>
                    <div><b>Alat Premium</b><small>Perawatan Rutin</small></div>
                  </div>
                </div>
              </div>
            </div>
            <div className="card-dots">
              <span className={`dot ${currentSection === 0 ? 'dot-active' : ''}`} onClick={() => goTo(0)} />
              <span className={`dot ${currentSection === 1 ? 'dot-active' : ''}`} onClick={() => goTo(1)} />
              <span className={`dot ${currentSection === 2 ? 'dot-active' : ''}`} onClick={() => goTo(2)} />
              <span className={`dot ${currentSection === 3 ? 'dot-active' : ''}`} onClick={() => goTo(3)} />
            </div>
          </div>
        </div>

        {/* Scroll indicator */}
        <div className="scroll-ind" onClick={() => goTo(1)}>
          <span>SCROLL</span>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="6 9 12 15 18 9"/></svg>
        </div>
      </section>

      {/* ══════ CARD 2 — CARA KERJA ══════ */}
      <section className={`sec sec-steps ${secClass(1)}`} id="cara">
        <div className="deco-circle dc3" /><div className="deco-circle dc4" />

        <div className="container">
          <div className="card card-steps">
            <div className={`steps-head rv ${revealed[1] ? 'vis' : ''}`}>
              <div className="badge badge-sm">Cara Kerja</div>
              <h2 className="steps-h2">Pinjam Alat dalam <span className="accent">4 Langkah Mudah</span></h2>
              <p className="steps-p">Proses sederhana untuk meminjam alat organisasi dari awal hingga selesai.</p>
            </div>

            <div className="steps-row">
              {[
                { n: '1', icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><line x1="21" y1="21" x2="16.65" y2="16.65"/></svg>, t: 'Pilih Alat', d: 'Jelajahi katalog dan pilih alat yang kamu butuhkan untuk kegiatanmu.' },
                { n: '2', icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>, t: 'Pilih Tanggal', d: 'Tentukan tanggal pinjam dan kembali sesuai kebutuhan kegiatan.' },
                { n: '3', icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>, t: 'Isi Data', d: 'Lengkapi data peminjam dan keperluan peminjaman dengan benar.' },
                { n: '4', icon: <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>, t: 'Konfirmasi & Pinjam', d: 'Konfirmasi peminjaman, ambil alat, dan gunakan dengan bertanggung jawab.' },
              ].map((s, i) => (
                <React.Fragment key={i}>
                  <div
                    className={`step rv ${revealed[1] ? 'vis' : ''} ${activeStep === i ? 'step-on' : ''}`}
                    onMouseEnter={() => setActiveStep(i)}
                    onMouseLeave={() => setActiveStep(null)}
                  >
                    <div className="step-top-area">
                      <div className="step-num">{s.n}</div>
                      <div className="step-morph-wrap">
                        <span className="step-ic">{s.icon}</span>
                        <img src={`/intro/step${i + 1}.png`} alt={s.t} className="step-preview-img" />
                      </div>
                    </div>
                    <div className="step-text-area">
                      <h4 className="step-t">{s.t}</h4>
                      <p className="step-d">{s.d}</p>
                    </div>
                  </div>
                  {i < 3 && <div className={`step-arrow rv ${revealed[1] ? 'vis' : ''}`}><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg></div>}
                </React.Fragment>
              ))}
            </div>

            {/* Bottom CTA */}
            <div className={`steps-cta rv ${revealed[1] ? 'vis' : ''}`}>
              <div className="cta-inner">
                <div className="cta-left">
                  <h4>Butuh Bantuan?</h4>
                  <p>Tim kami siap membantu proses peminjamanmu.</p>
                </div>
                {(() => {
                  if (user && user.role === 'admin') {
                    return <Link to="/dashboard" className="btn-pri">Buka Dashboard <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg></Link>;
                  }
                  
                  const waNumber = '6283119127384';
                  const waMessageRaw = user 
                    ? `Assalamualaikum, salam sejahtera bagi Bapak/Ibu admin.\n\nSaya ${user.nama} (NIM: ${user.nim || 'Mohon Logout & Login kembali agar NIM terbaca'}), butuh bantuan terkait peminjaman alat di PinjamIN.\n\n[Tuliskan pesan Anda di sini...]`
                    : `Assalamualaikum, salam sejahtera bagi Bapak/Ibu admin.\n\nSaya [Isi Nama Anda] (NIM: [Isi NIM Anda]), butuh bantuan terkait peminjaman alat di PinjamIN.\n\n[Tuliskan pesan Anda di sini...]`;
                  const waUrl = `https://wa.me/${waNumber}?text=${encodeURIComponent(waMessageRaw)}`;
                  
                  return (
                    <a href={waUrl} target="_blank" rel="noreferrer" className="btn-pri">
                      Hubungi Kami <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>
                    </a>
                  );
                })()}
              </div>
            </div>

            <div className="card-dots">
              <span className={`dot ${currentSection === 0 ? 'dot-active' : ''}`} onClick={() => goTo(0)} />
              <span className={`dot ${currentSection === 1 ? 'dot-active' : ''}`} onClick={() => goTo(1)} />
              <span className={`dot ${currentSection === 2 ? 'dot-active' : ''}`} onClick={() => goTo(2)} />
              <span className={`dot ${currentSection === 3 ? 'dot-active' : ''}`} onClick={() => goTo(3)} />
            </div>
          </div>
        </div>

        {/* Scroll indicator for next section */}
        <div className="scroll-ind" onClick={() => goTo(2)}>
          <span>SCROLL</span>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="6 9 12 15 18 9"/></svg>
        </div>
      </section>

      {/* ══════ CARD 3 — KATALOG SINGKAT ══════ */}
      <section className={`sec sec-catalog ${secClass(2)}`} id="katalog">
        <div className="deco-circle dc5" /><div className="deco-circle dc6" />

        <div className="container">
          <div className="card card-catalog">
            <div className={`catalog-head rv ${revealed[2] ? 'vis' : ''}`}>
              <div className="badge badge-sm">Koleksi Inventaris</div>
              <h2 className="steps-h2">Alat Operasional <span className="accent">Unggulan</span></h2>
              <p className="steps-p">Daftar inventaris premium dengan tingkat ketersediaan tinggi untuk mendukung kegiatan Anda.</p>
            </div>

            <div className={`catalog-grid rv ${revealed[2] ? 'vis' : ''}`}>
              {barangList.map((b, i) => (
                <div key={b.id_barang || i} className="barang-card">
                  <div className="bc-img-wrap">
                    <img src={b.gambar ? `/barang/${b.gambar}` : '/intro/step1.png'} alt={b.nama_barang} onError={(e) => e.target.src = '/intro/step1.png'} />
                    <span className="bc-kondisi">{b.kondisi}</span>
                  </div>
                  <div className="bc-body">
                    <div className="bc-kat">
                      <span>{b.nama_kategori || 'Alat Umum'}</span>
                      <span className="bc-kat-stars">
                        {[1,2,3,4,5].map(star => <svg key={star} viewBox="0 0 24 24" fill="#fbbf24" stroke="#f59e0b" strokeWidth="1"><polygon points="12 2 15.09 8.26 22 9.27 17 14.14 18.18 21.02 12 17.77 5.82 21.02 7 14.14 2 9.27 8.91 8.26 12 2"/></svg>)}
                      </span>
                      <span className="bc-kat-badge">Premium</span>
                    </div>
                    <h4 className="bc-nama">{b.nama_barang}</h4>
                    <div className="bc-stok">
                      <span className="bc-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><rect x="2" y="7" width="20" height="14" rx="2" ry="2"/><path d="M16 21V5a2 2 0 0 0-2-2h-4a2 2 0 0 0-2 2v16"/></svg></span> 
                      Sisa Stok: <strong>{b.stok}</strong> Unit
                    </div>
                    <div className="bc-lokasi">
                      <span className="bc-icon"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><path d="M20 10c0 6-8 12-8 12s-8-6-8-12a8 8 0 0 1 16 0Z"/><circle cx="12" cy="10" r="3"/></svg></span> 
                      {b.lokasi || 'Gudang Utama'}
                    </div>
                  </div>
                  <div className="bc-foot">
                    <Link to={`/detail/${b.id_barang}`} className="btn-pinjam-sm">Lihat Detail & Pinjam</Link>
                  </div>
                </div>
              ))}
            </div>

            <div className={`catalog-cta rv ${revealed[2] ? 'vis' : ''}`}>
               <Link to="/daftarbarang" className="btn-sec" style={{fontFamily:'inherit'}}>Lihat Semua Katalog</Link>
            </div>

            <div className="card-dots">
              <span className={`dot ${currentSection === 0 ? 'dot-active' : ''}`} onClick={() => goTo(0)} />
              <span className={`dot ${currentSection === 1 ? 'dot-active' : ''}`} onClick={() => goTo(1)} />
              <span className={`dot ${currentSection === 2 ? 'dot-active' : ''}`} onClick={() => goTo(2)} />
              <span className={`dot ${currentSection === 3 ? 'dot-active' : ''}`} onClick={() => goTo(3)} />
            </div>
          </div>
        </div>

        <div className="scroll-ind" onClick={() => goTo(3)}>
          <span>SCROLL</span>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="6 9 12 15 18 9"/></svg>
        </div>
      </section>

      {/* ══════ CARD 4 — LOKASI KAMI ══════ */}
      <section className={`sec sec-location ${secClass(3)}`} id="lokasi">
        <div className="container">
          <div className={`card card-loc rv ${revealed[3] ? 'vis' : ''}`}>
            
            <div className="loc-left">
              <h2 className="loc-h2">Kunjungi Pusat<br/>Gudang Kami</h2>
              <p className="loc-p">Pengambilan dan pengembalian barang dilakukan di gudang utama Politeknik Elektronika Negeri Surabaya. Cek estimasi jarak Anda ke lokasi kami.</p>
              
              <div className="loc-form">
                <div className="loc-fg">
                  <label>Jam Operasional</label>
                  <div style={{ borderBottom: '1px solid #e2e8f0', padding: '8px 0', fontSize: '16px', color: '#0f172a', fontWeight: '500', display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                    <span>Senin - Jumat, 08:00 - 16:00 WIB</span>
                    <div className="loc-tooltip-wrap">
                      <span className="loc-info-icon">!</span>
                      <div className="loc-tooltip">Pada hari libur nasional atau akhir pekan barang tidak bisa diambil. Silakan hubungi admin jika mendesak.</div>
                    </div>
                  </div>
                </div>
                <div className="loc-fg">
                  <label>Titik Pengambilan / Pengembalian</label>
                  <div style={{ borderBottom: '1px solid #e2e8f0', padding: '8px 0', fontSize: '16px', color: '#0f172a', fontWeight: '500' }}>
                    <span className="loc-ticker" key={currentLokasiIdx}>
                      {lokasiList[currentLokasiIdx]}
                    </span>
                  </div>
                </div>
                {(() => {
                  const waNumber = '6283119127384';
                  const waMessageRaw = user 
                    ? `Assalamualaikum, salam sejahtera bagi Bapak/Ibu admin.\n\nSaya ${user.nama} (NIM: ${user.nim || 'Mohon Logout & Login kembali agar NIM terbaca'}), ingin menyampaikan terkait peminjaman alat di PinjamIN.\n\n[Tuliskan pesan Anda di sini...]`
                    : `Assalamualaikum, salam sejahtera bagi Bapak/Ibu admin.\n\nSaya [Isi Nama Anda] (NIM: [Isi NIM Anda]), ingin menyampaikan terkait peminjaman alat di PinjamIN.\n\n[Tuliskan pesan Anda di sini...]`;
                  const waUrl = `https://wa.me/${waNumber}?text=${encodeURIComponent(waMessageRaw)}`;
                  
                  return (
                    <a href={waUrl} target="_blank" rel="noreferrer" className="loc-btn" style={{ textDecoration: 'none', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: '8px' }}>
                      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z"></path></svg>
                      Hubungi Admin
                    </a>
                  );
                })()}
              </div>
            </div>

            <div className="loc-right">
              <div className="loc-overlay-text">P E N S</div>
              <iframe 
                src="https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d3957.6921781667456!2d112.79118257381491!3d-7.275824292731309!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x2dd7fa10ea2ae883%3A0xbe22c55d60ef09c7!2sPoliteknik%20Elektronika%20Negeri%20Surabaya!5e0!3m2!1sid!2sid!4v1778837802114!5m2!1sid!2sid" 
                className="loc-map"
                allowFullScreen="" 
                loading="lazy" 
                referrerPolicy="no-referrer-when-downgrade">
              </iframe>
            </div>

            <div className="card-dots">
              <span className={`dot ${currentSection === 0 ? 'dot-active' : ''}`} onClick={() => goTo(0)} />
              <span className={`dot ${currentSection === 1 ? 'dot-active' : ''}`} onClick={() => goTo(1)} />
              <span className={`dot ${currentSection === 2 ? 'dot-active' : ''}`} onClick={() => goTo(2)} />
              <span className={`dot ${currentSection === 3 ? 'dot-active' : ''}`} onClick={() => goTo(3)} />
            </div>
          </div>
        </div>

        <footer className="ft"><p>© {new Date().getFullYear()} PinjamIN — Sistem Peminjaman Alat Organisasi Kampus</p></footer>
      </section>
    </div>
  );
}
