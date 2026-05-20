import React, { useEffect, useState, useRef } from 'react';
import Sidebar from '../partials/admin/Sidebar';
import Flash from '../partials/Flash';
import AdminNavbar from '../partials/admin/AdminNavbar';
import { useTheme } from '../App';
import './Dashboard.css';

const MONTHS = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
const CHART_DATA = [8,12,10,18,24,22,28,34,30,38,42,48];
const MAX_VAL = 50;

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
    drawChart();
    const handleResize = () => drawChart();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, [chartTab, dark]);

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
    MONTHS.forEach((m, i) => {
      const x = padL + (chartW / (MONTHS.length - 1)) * i;
      ctx.fillStyle = labelColor;
      ctx.fillText(m, x, H - 10);
    });

    const pts = CHART_DATA.map((v, i) => ({
      x: padL + (chartW / (CHART_DATA.length - 1)) * i,
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

  const recentOrders = [
    { customer: 'Ahmad R.', id: 'PMJ-001', product: 'Proyektor Epson', status: 'Disetujui', amount: '1 Unit' },
    { customer: 'Siti N.', id: 'PMJ-002', product: 'Laptop Asus', status: 'Menunggu', amount: '2 Unit' },
    { customer: 'Budi S.', id: 'PMJ-003', product: 'Speaker JBL', status: 'Diambil', amount: '1 Unit' },
    { customer: 'Dewi A.', id: 'PMJ-004', product: 'Kamera Canon', status: 'Selesai', amount: '1 Unit' },
    { customer: 'Firman H.', id: 'PMJ-005', product: 'Mikrofon Shure', status: 'Ditolak', amount: '3 Unit' },
  ];

  const recentActivities = [
    { icon: '📦', text: 'Proyektor Epson ditambahkan ke inventaris', time: '2 menit lalu' },
    { icon: '✅', text: 'Peminjaman PMJ-001 disetujui', time: '15 menit lalu' },
    { icon: '👤', text: 'User baru "Siti N." terdaftar', time: '1 jam lalu' },
    { icon: '🔄', text: 'Laptop Asus dikembalikan', time: '3 jam lalu' },
    { icon: '⚠️', text: 'Speaker JBL mendekati batas waktu', time: '5 jam lalu' },
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
              value="148"
              change="+12.5% vs bulan lalu"
              positive={true}
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 16V8a2 2 0 00-1-1.73l-7-4a2 2 0 00-2 0l-7 4A2 2 0 002 8v8a2 2 0 001 1.73l7 4a2 2 0 002 0l7-4A2 2 0 0021 16z"/></svg>}
              sparkData={[4,6,5,7,9,8,11,13,12,15]}
              sparkColor="#3b82f6"
            />
            <StatCard
              title="Total Anggota"
              value="2,847"
              change="+8.2% vs bulan lalu"
              positive={true}
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 00-3-3.87"/><path d="M16 3.13a4 4 0 010 7.75"/></svg>}
              sparkData={[10,14,12,16,18,20,22,21,24,26]}
              sparkColor="#06b6d4"
            />
            <StatCard
              title="Total Peminjaman"
              value="1,432"
              change="-3.1% vs bulan lalu"
              positive={false}
              icon={<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2"/><rect x="9" y="3" width="6" height="4" rx="1"/></svg>}
              sparkData={[20,18,22,16,14,15,12,14,11,10]}
              sparkColor="#f59e0b"
            />
            <StatCard
              title="Barang Dipinjam"
              value="284"
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
                <ProgressBar label="Peminjaman Selesai" value="48" target="60" percent={80} color="#3b82f6" />
                <ProgressBar label="Anggota Baru" value="847" target="1,000" percent={85} color="#06b6d4" />
                <ProgressBar label="Pengembalian Tepat" value="3.8" target="5" percent={76} color="#f59e0b" />
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
                  {recentOrders.map(o => (
                    <tr key={o.id}>
                      <td className="customer-cell">{o.customer}</td>
                      <td className="order-id">{o.id}</td>
                      <td>{o.product}</td>
                      <td><span className={`status-badge ${statusClass(o.status)}`}>{o.status}</span></td>
                      <td>{o.amount}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className="activity-card">
              <div className="card-header-row">
                <div>
                  <h3 className="card-title">Recent Activity</h3>
                  <p className="card-sub">Kejadian terbaru di sistem</p>
                </div>
                <a href="#" className="view-all">View all →</a>
              </div>
              <div className="activity-list">
                {recentActivities.map((a, i) => (
                  <div key={i} className="activity-item">
                    <span className="activity-icon">{a.icon}</span>
                    <div className="activity-content">
                      <span className="activity-text">{a.text}</span>
                      <span className="activity-time">{a.time}</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}

export default Dashboard;
