import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import Navbar from '../partials/Navbar';
import Flash from '../partials/Flash';
import BookingModal from './form/BookingModal';
import './Detail.css';

const API = 'http://localhost:3000';

export default function Detail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [barang, setBarang] = useState(null);
  const [loading, setLoading] = useState(true);
  const [bookedDates, setBookedDates] = useState([]);
  const [currentDate, setCurrentDate] = useState(new Date());
  const [toasts, setToasts] = useState([]);
  const [showBooking, setShowBooking] = useState(false);

  // Ambil data user dari localStorage
  const user = JSON.parse(localStorage.getItem('user'));

  // Flash helpers
  const addToast = (type, message) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4500);
  };
  const removeToast = (id) => setToasts(prev => prev.filter(t => t.id !== id));

  useEffect(() => {
    // Scroll to top when page loads
    window.scrollTo(0, 0);

    // Pop any global flash (e.g. from other pages)
    try {
      const raw = localStorage.getItem('_flash');
      if (raw) {
        const flash = JSON.parse(raw);
        localStorage.removeItem('_flash');
        setTimeout(() => addToast(flash.type, flash.message), 200);
      }
    } catch (_) { }

    fetch(`${API}/api/barang/${id}`)
      .then(res => res.json())
      .then(barangData => {
        if (barangData.status === 'success' && barangData.data) {
          setBarang(barangData.data);

          // Only fetch booked dates if item fetch succeeds
          fetch(`${API}/api/barang/${id}/booked-dates`)
            .then(res => {
              if (res.ok) return res.json();
              throw new Error("Failed");
            })
            .then(bookedData => {
              if (bookedData && bookedData.status === 'success' && bookedData.data) {
                setBookedDates(bookedData.data);
              }
            })
            .catch(err => console.error('Failed to fetch booked dates:', err))
            .finally(() => setLoading(false));

        } else {
          setLoading(false);
        }
      })
      .catch(err => {
        console.error(err);
        setLoading(false);
      });
  }, [id]);

  const nextMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() + 1, 1));
  };

  const prevMonth = () => {
    setCurrentDate(new Date(currentDate.getFullYear(), currentDate.getMonth() - 1, 1));
  };

  // Logika Kalender
  const getDaysInMonth = (year, month) => new Date(year, month + 1, 0).getDate();
  const getFirstDayOfMonth = (year, month) => new Date(year, month, 1).getDay();

  const isBooked = (day, month, year) => {
    const checkDate = new Date(year, month, day);
    // Normalize to midnight for accurate comparison
    checkDate.setHours(0, 0, 0, 0);

    return bookedDates.some(b => {
      const start = new Date(b.tanggal_pinjam);
      start.setHours(0, 0, 0, 0);
      const end = new Date(b.tanggal_kembali);
      end.setHours(0, 0, 0, 0);
      return checkDate >= start && checkDate <= end;
    });
  };

  const renderCalendar = () => {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const daysInMonth = getDaysInMonth(year, month);
    const firstDay = getFirstDayOfMonth(year, month);

    const days = [];
    const weekdays = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];

    for (let i = 0; i < firstDay; i++) {
      days.push(<div key={`empty-${i}`} className="cal-day empty"></div>);
    }

    for (let i = 1; i <= daysInMonth; i++) {
      const booked = isBooked(i, month, year);
      const isToday = new Date().toDateString() === new Date(year, month, i).toDateString();
      days.push(
        <div key={`day-${i}`} className={`cal-day ${booked ? 'booked' : 'available'} ${isToday ? 'today' : ''}`}>
          {i}
        </div>
      );
    }

    return (
      <div className="calendar-widget">
        <div className="cal-header">
          <button onClick={prevMonth}>&lt;</button>
          <h4>{currentDate.toLocaleString('id-ID', { month: 'long', year: 'numeric' })}</h4>
          <button onClick={nextMonth}>&gt;</button>
        </div>
        <div className="cal-grid">
          {weekdays.map(wd => <div key={wd} className="cal-wd">{wd}</div>)}
          {days}
        </div>
        <div className="cal-legend">
          <div className="leg-item"><span className="leg-box leg-av"></span> Tersedia</div>
          <div className="leg-item"><span className="leg-box leg-bk"></span> Dibooking</div>
        </div>
      </div>
    );
  };

  if (loading) {
    return <div className="detail-loading"><div className="loader"></div>Memuat detail barang...</div>;
  }

  if (!barang) {
    return (
      <div className="detail-error">
        <h2>Barang Tidak Ditemukan</h2>
        <p>Maaf, barang yang Anda cari tidak tersedia atau sudah dihapus.</p>
        <button className="detail-back-btn" onClick={() => navigate(-1)}>Kembali</button>
      </div>
    );
  }

  const handlePinjam = () => {
    const userLocal = localStorage.getItem('user');
    if (!userLocal) {
      addToast('error', 'Silakan login terlebih dahulu untuk mengajukan peminjaman.');
      setTimeout(() => navigate('/login'), 1500);
    } else {
      setShowBooking(true);
    }
  };

  return (
    <div className="detail-page">
      <Flash toasts={toasts} removeToast={removeToast} />
      {showBooking && (
        <BookingModal
          barang={barang}
          bookedDates={bookedDates}
          onClose={() => setShowBooking(false)}
          onSuccess={(msg) => {
            setShowBooking(false);
            addToast('success', msg);
            setTimeout(() => navigate('/riwayat-peminjaman'), 1500);
          }}
        />
      )}
      <Navbar user={user} onFlash={addToast} />

      <div className="detail-container" style={{ paddingTop: '100px', position: 'relative' }}>
        <button className="detail-back-btn" onClick={() => navigate(-1)} style={{ position: 'absolute', top: '100px', left: 'clamp(20px, 4vw, 40px)', background: 'transparent', border: 'none', color: '#64748b', fontWeight: '600', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '8px', fontSize: '15px', padding: '0', zIndex: 10 }}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><line x1="19" y1="12" x2="5" y2="12"></line><polyline points="12 19 5 12 12 5"></polyline></svg>
          Kembali
        </button>
        <div className="detail-wrapper">
          <div className="detail-card">
            <div className="dc-left">
              <div className="dc-img-wrap">
                {barang.gambar ? (
                  <img src={barang.gambar.startsWith('http') ? barang.gambar : `/barang/${barang.gambar}`} alt={barang.nama_barang} className="dc-img" />
                ) : (
                  <div className="dc-no-img">Tidak Ada Foto</div>
                )}
              </div>
            </div>

            <div className="dc-right">
              <div className="dc-right-content">
                <div className="dc-info-col">
                  <div className="dc-badges">
                    <span className="badge-kategori">{barang.nama_kategori || 'Tanpa Kategori'}</span>
                    <span className={`badge-stok ${barang.stok > 0 ? 'tersedia' : 'habis'}`}>
                      {barang.stok > 0 ? `Tersedia ${barang.stok} Unit` : 'Stok Habis'}
                    </span>
                  </div>

                  <h1 className="dc-title">{barang.nama_barang}</h1>

                  <div className="dc-info-grid">
                    <div className="dc-info-item">
                      <span className="dc-info-label">Kondisi Alat</span>
                      <span className="dc-info-val">{barang.kondisi || '-'}</span>
                    </div>
                    <div className="dc-info-item">
                      <span className="dc-info-label">Lokasi Simpan</span>
                      <span className="dc-info-val">{barang.lokasi || '-'}</span>
                    </div>
                  </div>

                  <div className="dc-desc-box">
                    <h3>Deskripsi Barang</h3>
                    <p>{barang.deskripsi || 'Belum ada deskripsi yang ditambahkan untuk barang ini.'}</p>
                  </div>

                  <div className="dc-action">
                    <button
                      className="btn-pinjam-besar"
                      onClick={handlePinjam}
                      disabled={barang.stok <= 0}
                    >
                      {barang.stok > 0 ? 'Ajukan Peminjaman' : 'Barang Sedang Kosong'}
                    </button>
                  </div>
                </div>

                <div className="dc-cal-col">
                  <h3 className="dc-cal-title">Jadwal Ketersediaan</h3>
                  {renderCalendar()}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
