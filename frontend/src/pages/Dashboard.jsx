import React, { useEffect, useState, useRef } from 'react';
import Sidebar from '../partials/admin/Sidebar';
import Flash from '../partials/Flash';
import AdminNavbar from '../partials/admin/AdminNavbar';
import { useTheme } from '../App';
import { authFetch } from '../utils/authFetch';
import './Dashboard.css';

const API = 'http://localhost:3000';

const WEEKS = ['Mg 1', 'Mg 2', 'Mg 3', 'Mg 4', 'Mg 5'];

function MiniSparkline({ data, color }) {
  const points = data.map((v, i) => {
    const x = (i / (data.length - 1)) * 100;
    const y = 100 - (v / Math.max(...data)) * 80;
    return `${x},${y}`;
  }).join(' ');

  return (
    <svg viewBox="0 0 100 100" preserveAspectRatio="none" className="sparkline">
      <defs>
        <linearGradient id={`sg-${color}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" stopColor={color} stopOpacity="0.3"/>
          <stop offset="100%" stopColor={color} stopOpacity="0.02"/>
        </linearGradient>
      </defs>
      <polygon
        points={`0,100 ${points} 100,100`}
        fill={`url(#sg-${color})`}
      />
      <polyline
        points={points}
        fill="none"
        stroke={color}
        strokeWidth="2.5"
        strokeLinejoin="round"
        strokeLinecap="round"
      />
    </svg>
  );
}

function DonutChart({ segments, centerLabel, centerSub }) {
  const total = segments.reduce((s, seg) => s + seg.value, 0);
  let cumulative = 0;
  const radius = 40;
  const circumference = 2 * Math.PI * radius;

  return (
    <div className="donut-wrapper">
      <svg viewBox="0 0 100 100" className="donut-svg">
        {segments.map((seg, i) => {
          const dashLen = (seg.value / total) * circumference;
          const dashOff = -(cumulative / total) * circumference;
          cumulative += seg.value;
          return (
            <circle
              key={i}
              cx="50" cy="50" r={radius}
              fill="none"
              stroke={seg.color}
              strokeWidth="12"
              strokeDasharray={`${dashLen} ${circumference - dashLen}`}
              strokeDashoffset={dashOff}
              strokeLinecap="round"
              style={{ transform: 'rotate(-90deg)', transformOrigin: '50% 50%' }}
            />
          );
        })}
        <text x="50" y="46" textAnchor="middle" className="donut-center-label">{centerLabel}</text>
        <text x="50" y="58" textAnchor="middle" className="donut-center-sub">{centerSub}</text>
      </svg>
    </div>
  );
}

function ProgressBar({ label, value, target, percent, color }) {
  return (
    <div className="progress-item">
      <div className="progress-header">
        <span className="progress-label">{label}</span>
        <span className="progress-percent" style={{ color }}>{percent}%</span>
      </div>
      <div className="progress-track">
        <div className="progress-fill" style={{ width: `${percent}%`, background: color }}></div>
      </div>
      <div className="progress-meta">
        <span>{value}</span>
        <span>Target: {target}</span>
      </div>
    </div>
  );
}

function StatCard({ title, value, change, positive, icon, sparkData, sparkColor }) {
  return (
    <div className="stat-card">
      <div className="stat-top">
        <div>
          <span className="stat-title">{title}</span>
          <span className="stat-value">{value}</span>
          <span className={`stat-change ${positive ? 'up' : 'down'}`}>
            {positive ? '↗' : '↘'} {change}
          </span>
        </div>
        <div className="stat-icon-wrap" style={{ background: sparkColor + '18', color: sparkColor }}>
          {icon}
        </div>
      </div>
      <MiniSparkline data={sparkData} color={sparkColor} />
    </div>
  );
}

function Dashboard() {
  const user = JSON.parse(localStorage.getItem('user') || '{}');
  const canvasRef = useRef(null);
  const [chartTab, setChartTab] = useState('Peminjaman');
  const { dark, toggleTheme } = useTheme();
  const [toasts, setToasts] = useState([]);
  const [stats, setStats] = useState({
     totalBarang: '-',
     totalAnggota: '-',
     totalPeminjaman: '-',
     barangDipinjam: '-',
     recentOrders: [],
     chartPeminjaman: [0, 0, 0, 0, 0],
     chartPengembalian: [0, 0, 0, 0, 0],
     goals: {
        peminjaman: { value: 0, target: 50, percent: 0 },
        anggota: { value: 0, target: 100, percent: 0 },
        barang: { value: 0, target: 200, percent: 0 }
     }
  });

  const addToast = (type, message) => {
    const id = Date.now() + Math.random();
    setToasts(prev => [...prev, { id, type, message }]);
    setTimeout(() => setToasts(prev => prev.filter(t => t.id !== id)), 4500);
  };
  const removeToast = (id) => setToasts(prev => prev.filter(t => t.id !== id));

  // Pop flash dari login atau redirect lain
  useEffect(() => {
    try {
      const raw = localStorage.getItem('_flash');
      if (raw) {
        const flash = JSON.parse(raw);
        localStorage.removeItem('_flash');
        setTimeout(() => addToast(flash.type, flash.message), 300);
      }
    } catch (_) {}
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        const [resStat, resPem] = await Promise.all([
          authFetch(`${API}/api/beranda/statistik`),
          authFetch(`${API}/api/peminjaman`)
        ]);

        const [jStat, jPem] = await Promise.all([
          resStat.json(), resPem.json()
        ]);

        const dataStat = jStat.data || {};
        const dataPem = jPem.data || [];

        const recentOrders = dataPem.slice(0, 5).map(p => {
            const genCode = (id) => ((id * 2654435761) >>> 0).toString(16).substring(0, 6).toUpperCase().padStart(6, '0');
            return {
                id: `PMJ-${genCode(p.id_peminjaman)}`,
                customer: p.nama_user,
                product: p.nama_barang,
                status: p.status.charAt(0).toUpperCase() + p.status.slice(1),
                amount: p.jumlah + ' Unit'
            }
        });

        const currentMonth = new Date().getMonth();
        const currentYear = new Date().getFullYear();
        const getWeek = (d) => Math.min(Math.floor((d.getDate() - 1) / 7), 4);

        const chartPeminjaman = [0, 0, 0, 0, 0];
        const chartPengembalian = [0, 0, 0, 0, 0];
        let selesaiCount = 0;

        dataPem.forEach(p => {
           const d = new Date(p.tanggal_pinjam || p.created_at);
           if (d.getMonth() === currentMonth && d.getFullYear() === currentYear) {
               const w = getWeek(d);
               chartPeminjaman[w]++;
               if (p.status === 'selesai' || p.status === 'dikembalikan') {
                   chartPengembalian[w]++;
               }
           }
           if (p.status === 'selesai') selesaiCount++;
        });

        const totalBrg = dataStat.total_barang || 0;
        const totalAgt = dataStat.total_anggota || 0;
        const goals = {
          peminjaman: { value: selesaiCount, target: 50, percent: Math.min(Math.round((selesaiCount / 50) * 100), 100) },
          anggota: { value: totalAgt, target: 100, percent: Math.min(Math.round((totalAgt / 100) * 100), 100) },
          barang: { value: totalBrg, target: 200, percent: Math.min(Math.round((totalBrg / 200) * 100), 100) }
        };

        setStats({
           totalBarang: totalBrg,
           totalAnggota: totalAgt,
           totalPeminjaman: dataPem.length,
           barangDipinjam: dataStat.dipinjam || 0,
           recentOrders,
           chartPeminjaman,
           chartPengembalian,
           goals
        });
      } catch(e) {
          console.error(e);
      }
    };
    fetchDashboardData();
  }, []);

  useEffect(() => {
    drawChart();
    const handleResize = () => drawChart();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [chartTab, dark, stats.chartPeminjaman, stats.chartPengembalian]);

  function drawChart() {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.parentElement.getBoundingClientRect();
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    canvas.style.width = rect.width + 'px';
    canvas.style.height = rect.height + 'px';
    ctx.scale(dpr, dpr);

    const W = rect.width;
    const H = rect.height;
    const padL = 50, padR = 20, padT = 20, padB = 40;
    const chartW = W - padL - padR;
    const chartH = H - padT - padB;

    ctx.clearRect(0, 0, W, H);

    const isDark = document.documentElement.classList.contains('dark');
    const gridColor = isDark ? '#2a2d3a' : '#f1f5f9';
    const labelColor = isDark ? '#64748b' : '#94a3b8';

    const activeData = chartTab === 'Pengembalian' ? stats.chartPengembalian : stats.chartPeminjaman;
    const maxValFound = Math.max(...activeData, 5);
    const MAX_VAL = Math.ceil(maxValFound * 1.5);

    ctx.font = '11px Inter, sans-serif';
    ctx.fillStyle = labelColor;
    ctx.textAlign = 'right';
    for (let i = 0; i <= 5; i++) {
      const y = padT + (chartH / 5) * i;
      const val = MAX_VAL - (MAX_VAL / 5) * i;
      ctx.fillText(val.toFixed(0), padL - 10, y + 4);
      ctx.beginPath();
      ctx.strokeStyle = gridColor;
      ctx.lineWidth = 1;
      ctx.moveTo(padL, y);
      ctx.lineTo(padL + chartW, y);
      ctx.stroke();
    }

    ctx.textAlign = 'center';
    WEEKS.forEach((m, i) => {
      const x = padL + (chartW / (WEEKS.length - 1)) * i;
      ctx.fillStyle = labelColor;
      ctx.fillText(m, x, H - 10);
    });

    const pts = activeData.map((v, i) => ({
      x: padL + (chartW / (activeData.length - 1)) * i,
      y: padT + chartH - (v / MAX_VAL) * chartH
    }));

    const grad = ctx.createLinearGradient(0, padT, 0, padT + chartH);
    grad.addColorStop(0, 'rgba(56, 189, 248, 0.25)');
    grad.addColorStop(1, 'rgba(56, 189, 248, 0.01)');

    ctx.beginPath();
    ctx.moveTo(pts[0].x, padT + chartH);
    pts.forEach((p, i) => {
      if (i === 0) { ctx.lineTo(p.x, p.y); return; }
      const prev = pts[i - 1];
      const cpx1 = prev.x + (p.x - prev.x) * 0.4;
      const cpx2 = prev.x + (p.x - prev.x) * 0.6;
      ctx.bezierCurveTo(cpx1, prev.y, cpx2, p.y, p.x, p.y);
    });
    ctx.lineTo(pts[pts.length - 1].x, padT + chartH);
    ctx.closePath();
    ctx.fillStyle = grad;
    ctx.fill();

    ctx.beginPath();
    pts.forEach((p, i) => {
      if (i === 0) { ctx.moveTo(p.x, p.y); return; }
      const prev = pts[i - 1];
      const cpx1 = prev.x + (p.x - prev.x) * 0.4;
      const cpx2 = prev.x + (p.x - prev.x) * 0.6;
      ctx.bezierCurveTo(cpx1, prev.y, cpx2, p.y, p.x, p.y);
    });
    ctx.strokeStyle = '#38bdf8';
    ctx.lineWidth = 2.5;
    ctx.lineJoin = 'round';
    ctx.lineCap = 'round';
    ctx.stroke();

    pts.forEach(p => {
      ctx.beginPath();
      ctx.arc(p.x, p.y, 3, 0, Math.PI * 2);
      ctx.fillStyle = '#ffffff';
      ctx.fill();
      ctx.strokeStyle = '#38bdf8';
      ctx.lineWidth = 2;
      ctx.stroke();
    });
  }

  const trafficSegments = [
    { label: 'Direct', value: 35, color: '#ef4444' },
    { label: 'Organic', value: 28, color: '#06b6d4' },
    { label: 'Referral', value: 22, color: '#f59e0b' },
    { label: 'Social', value: 15, color: '#f97316' },
  ];

  const statusClass = (s) => {
    const map = { 'Disetujui': 'approved', 'Menunggu': 'pending', 'Diambil': 'taken', 'Selesai': 'done', 'Ditolak': 'rejected' };
    return map[s] || '';
  };

  return (
    <div className="dashboard-layout">
      <Flash toasts={toasts} removeToast={removeToast} />
      <Sidebar />
      <main className="dashboard-main">
        <AdminNavbar
          title="Dashboard"
          subtitle={`Selamat datang, ${user.nama || 'Admin'}!`}
        />

        <div className="dashboard-content">
          <div className="stats-row">
            <StatCard
              title="Total Barang"
              value={stats.totalBarang}
              change="+12.5% vs bulan lalu"
              positive={true}
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 002 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/></svg>}
              sparkData={[4,6,5,7,9,8,11,13,12,15]}
              sparkColor="#3b82f6"
            />
            <StatCard
              title="Total Anggota"
              value={stats.totalAnggota}
              change="+8.2% vs bulan lalu"
              positive={true}
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>}
              sparkData={[10,14,12,16,18,20,22,21,24,26]}
              sparkColor="#06b6d4"
            />
            <StatCard
              title="Total Peminjaman"
              value={stats.totalPeminjaman}
              change="-3.1% vs bulan lalu"
              positive={false}
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/></svg>}
              sparkData={[20,18,22,16,14,15,12,14,11,10]}
              sparkColor="#f59e0b"
            />
            <StatCard
              title="Barang Dipinjam"
              value={stats.barangDipinjam}
              change="+24.7% vs bulan lalu"
              positive={true}
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><polyline points="12 6 12 12 16 14"/></svg>}
              sparkData={[5,8,6,10,12,14,16,18,22,28]}
              sparkColor="#8b5cf6"
            />
          </div>

          <div className="main-grid">
            <div className="chart-card">
              <div className="chart-header">
                <div>
                  <h3 className="card-title">Overview</h3>
                  <p className="card-sub">Performa bulanan tahun ini</p>
                </div>
                <div className="chart-tabs">
                  {['Peminjaman','Pengembalian','Barang'].map(tab => (
                    <button
                      key={tab}
                      className={`chart-tab ${chartTab === tab ? 'active' : ''}`}
                      onClick={() => setChartTab(tab)}
                    >{tab}</button>
                  ))}
                </div>
              </div>
              <div className="chart-area">
                <canvas ref={canvasRef} />
              </div>
            </div>

            <div className="side-cards">
              <div className="traffic-card">
                <h3 className="card-title">Traffic Sources</h3>
                <p className="card-sub">Dari mana pengguna datang</p>
                <DonutChart
                  segments={trafficSegments}
                  centerLabel="284K"
                  centerSub="visits"
                />
                <div className="traffic-legend">
                  {trafficSegments.map(seg => (
                    <div key={seg.label} className="legend-item">
                      <span className="legend-dot" style={{ background: seg.color }}></span>
                      <span className="legend-label">{seg.label}</span>
                      <span className="legend-value">{seg.value}%</span>
                    </div>
                  ))}
                </div>
              </div>

              <div className="goals-card">
                <h3 className="card-title">Monthly Goals</h3>
                <p className="card-sub">Progres menuju target</p>
                <ProgressBar label="Peminjaman Selesai" value={stats.goals.peminjaman.value} target={stats.goals.peminjaman.target} percent={stats.goals.peminjaman.percent} color="#3b82f6" />
                <ProgressBar label="Pertumbuhan Anggota" value={stats.goals.anggota.value} target={stats.goals.anggota.target} percent={stats.goals.anggota.percent} color="#06b6d4" />
                <ProgressBar label="Ketersediaan Barang" value={stats.goals.barang.value} target={stats.goals.barang.target} percent={stats.goals.barang.percent} color="#f59e0b" />
              </div>
            </div>
          </div>

          <div className="bottom-grid">
            <div className="orders-card">
              <div className="card-header-row">
                <div>
                  <h3 className="card-title">Recent Orders</h3>
                  <p className="card-sub">Transaksi peminjaman terbaru</p>
                </div>
                <a href="#" className="view-all">View all →</a>
              </div>
              <table className="orders-table">
                <thead>
                  <tr>
                    <th>Peminjam</th>
                    <th>Order ID</th>
                    <th>Barang</th>
                    <th>Status</th>
                    <th>Jumlah</th>
                  </tr>
                </thead>
                <tbody>
                  {stats.recentOrders.length > 0 ? stats.recentOrders.map(o => (
                    <tr key={o.id}>
                      <td className="customer-cell">{o.customer}</td>
                      <td className="order-id">{o.id}</td>
                      <td>{o.product}</td>
                      <td><span className={`status-badge ${statusClass(o.status)}`}>{o.status}</span></td>
                      <td>{o.amount}</td>
                    </tr>
                  )) : <tr><td colSpan="5" style={{textAlign:'center', padding:'20px'}}>Belum ada peminjaman</td></tr>}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

export default Dashboard;
