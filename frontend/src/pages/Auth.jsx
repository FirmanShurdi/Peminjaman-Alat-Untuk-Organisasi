import React, { useState, useEffect, useRef } from 'react';
import './Auth.css';
import Flash from '../partials/Flash';

export default function Auth() {
  const [isRegister, setIsRegister] = useState(false);
  const [toasts, setToasts] = useState([]);

  const [loginEmail, setLoginEmail] = useState('');
  const [loginPassword, setLoginPassword] = useState('');
  const [showLoginPassword, setShowLoginPassword] = useState(false);
  const [loginInvalid, setLoginInvalid] = useState(false);

  const [regNim, setRegNim] = useState('');
  const [regName, setRegName] = useState('');
  const [regEmail, setRegEmail] = useState('');
  const [regPassword, setRegPassword] = useState('');
  const [showRegPassword, setShowRegPassword] = useState(false);
  const [regInvalid, setRegInvalid] = useState(false);

  const [capsLockLogin, setCapsLockLogin] = useState(false);
  const [capsLockReg, setCapsLockReg] = useState(false);

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

  const toggleTab = (e, tab) => {
    e?.preventDefault();
    setIsRegister(tab === 'register');
    if (tab === 'register') {
      setTimeout(() => document.getElementById('rn')?.focus(), 100);
    } else {
      setTimeout(() => document.getElementById('le')?.focus(), 100);
    }
  };

  useEffect(() => {
    // Pop any session-expired or redirect flash message
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

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (!(e.ctrlKey || e.metaKey)) return;
      if (e.key === 'ArrowLeft' || e.key === 'ArrowRight') {
        e.preventDefault();
        setIsRegister(prev => !prev);
      }
    };
    document.addEventListener('keydown', handleKeyDown);
    return () => document.removeEventListener('keydown', handleKeyDown);
  }, []);

  const handleLoginSubmit = async (e) => {
    e.preventDefault();
    const form = e.target;
    if (!form.checkValidity()) {
      setLoginInvalid(true);
      setTimeout(() => setLoginInvalid(false), 400);
      return;
    }

    try {
      const res = await fetch('http://localhost:3000/api/login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email: loginEmail, password: loginPassword })
      });
      const data = await res.json();
      if (data.success) {
        if (data.token) {
          localStorage.setItem('token', data.token);
          localStorage.setItem('user', JSON.stringify(data.user));
          // Simpan flash ke localStorage untuk dibaca halaman tujuan
          localStorage.setItem('_flash', JSON.stringify({ type: 'success', message: `Selamat datang, ${data.user?.nama || 'Pengguna'}! Login berhasil.` }));
          // Reset posisi Beranda ke atas (Card 1) agar tidak kembali ke posisi section sebelumnya
          sessionStorage.removeItem('beranda_section');
          setTimeout(() => {
            window.location.href = data.user?.role === 'admin' ? '/dashboard' : '/';
          }, 500);
        }
      } else {
        addToast('error', data.message);
      }
    } catch (err) {
      addToast('error', 'Terjadi kesalahan pada server');
    }
  };

  const handleRegisterSubmit = async (e) => {
    e.preventDefault();
    const form = e.target;
    if (!form.checkValidity()) {
      setRegInvalid(true);
      setTimeout(() => setRegInvalid(false), 400);
      return;
    }

    try {
      const res = await fetch('http://localhost:3000/api/register', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ nim: regNim, nama: regName, email: regEmail, password: regPassword, role: 'anggota' })
      });
      const data = await res.json();
      if (data.success) {
        addToast('success', data.message);
        setIsRegister(false);
      } else {
        addToast('error', data.message);
      }
    } catch (err) {
      addToast('error', 'Terjadi kesalahan pada server');
    }
  };

  return (
    <div className="auth-page">
      <div 
        className={`auth-frame ${isRegister ? 'is-register' : ''}`}
      >
        <div className="wedge" aria-hidden="true"></div>

        <div className="copy" aria-hidden="true">
          <div className="box copy-register">
            <div>
              <h1>WELCOME<br />BACK!</h1>
              <p>Buat akun untuk mulai menggunakan dashboard.</p>
              <button className="cta" onClick={(e) => toggleTab(e, 'login')}>Login</button>
            </div>
          </div>
          <div className="box copy-login">
            <div>
              <h1>WELCOME<br />BACK!</h1>
              <p>Masuk untuk mengelola sistem parkir.</p>
              <button className="cta" onClick={(e) => toggleTab(e, 'register')}>Sign Up</button>
            </div>
          </div>
        </div>

        <Flash toasts={toasts} removeToast={removeToast} />

        <section className="pane pane-login">
          <div className="card" role="region" aria-label="Form Login">
            <h2>Login</h2>
            <div className="underline"></div>

            <form onSubmit={handleLoginSubmit} noValidate autoComplete="off">
              <div className={`field ${loginInvalid && !loginEmail ? 'invalid' : ''}`}>
                <input
                  id="le" type="email" name="email" required autoComplete="off" placeholder=" "
                  value={loginEmail} onChange={e => setLoginEmail(e.target.value)}
                />
                <label htmlFor="le">Email</label>
                <svg className="ico" viewBox="0 0 24 24" fill="none">
                  <path d="M4 4h16a2 2 0 0 1 2 2v1l-10 6L2 7V6a2 2 0 0 1 2-2Zm18 6.3V18a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-7.7l10 6 10-6Z" stroke="currentColor" strokeWidth="1.5" />
                </svg>
              </div>

              <div className={`field ${loginInvalid && !loginPassword ? 'invalid' : ''}`}>
                <input
                  id="lp" type={showLoginPassword ? 'text' : 'password'} name="password" required autoComplete="new-password" placeholder=" "
                  value={loginPassword} onChange={e => setLoginPassword(e.target.value)}
                  onKeyUp={e => setCapsLockLogin(e.getModifierState && e.getModifierState('CapsLock') && loginPassword.length > 0)}
                  onBlur={() => setCapsLockLogin(false)}
                />
                <label htmlFor="lp">Password</label>
                <svg className="ico toggle-pass" viewBox="0 0 24 24" fill="none" onClick={() => setShowLoginPassword(!showLoginPassword)}>
                  {showLoginPassword ? (
                     <>
                     <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7S1 12 1 12Z" stroke="currentColor" strokeWidth="1.5"/>
                     <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.5"/>
                     </>
                  ) : (
                    <path d="M17.94 17.94A10.94 10.94 0 0 1 12 19c-7 0-11-7-11-7a21.33 21.33 0 0 1 5.17-5.88M9.88 9.88A3 3 0 0 0 12 15a3 3 0 0 0 2.12-5.12M1 1l22 22" stroke="currentColor" strokeWidth="1.5"/>
                  )}
                </svg>
                <div className={`caps-tip ${capsLockLogin ? 'show' : ''}`}>CapsLock ON</div>
              </div>

              <button className="btn" type="submit">Login</button>
            </form>

            <div className="tabs">
              Don't have an account? <button className="link-btn" onClick={(e) => toggleTab(e, 'register')}>Sign Up</button>
            </div>
          </div>
        </section>

        <section className="pane pane-register">
          <div className="card" role="region" aria-label="Form Sign Up">
            <h2>Sign Up</h2>
            <div className="underline"></div>

            <form onSubmit={handleRegisterSubmit} noValidate autoComplete="off">
              <div className={`field ${regInvalid && !regNim ? 'invalid' : ''}`}>
                <input id="rnim" type="text" name="nim" required autoComplete="off" placeholder=" " value={regNim} onChange={e => setRegNim(e.target.value)} />
                <label htmlFor="rnim">NIM</label>
                <svg className="ico" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                  <rect x="3" y="5" width="18" height="14" rx="2" />
                  <circle cx="8" cy="12" r="2" />
                  <path d="M14 11h4m-4 4h4m-9 0h.01" />
                </svg>
              </div>
               <div className={`field ${regInvalid && !regName ? 'invalid' : ''}`}>
                <input id="rn" type="text" name="nama" required autoComplete="off" placeholder=" " value={regName} onChange={e => setRegName(e.target.value)} />
                <label htmlFor="rn">Username</label>
                <svg className="ico" viewBox="0 0 24 24" fill="none">
                  <path d="M12 12a5 5 0 1 0-5-5 5 5 0 0 0 5 5Zm0 2c-5 0-9 3-9 6v2h18v-2c0-3-4-6-9-6Z" stroke="currentColor" strokeWidth="1.5" />
                </svg>
              </div>
              <div className={`field ${regInvalid && !regEmail ? 'invalid' : ''}`}>
                <input id="re" type="email" name="email" required autoComplete="off" placeholder=" " value={regEmail} onChange={e => setRegEmail(e.target.value)} />
                <label htmlFor="re">Email</label>
                <svg className="ico" viewBox="0 0 24 24" fill="none">
                  <path d="M4 4h16a2 2 0 0 1 2 2v1l-10 6L2 7V6a2 2 0 0 1 2-2Zm18 6.3V18a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2v-7.7l10 6 10-6Z" stroke="currentColor" strokeWidth="1.5" />
                </svg>
              </div>
              <div className={`field ${regInvalid && !regPassword ? 'invalid' : ''}`}>
                <input
                  id="rp" type={showRegPassword ? 'text' : 'password'} name="password" minLength="1" required autoComplete="new-password" placeholder=" "
                  value={regPassword} onChange={e => setRegPassword(e.target.value)}
                  onKeyUp={e => setCapsLockReg(e.getModifierState && e.getModifierState('CapsLock') && regPassword.length > 0)}
                  onBlur={() => setCapsLockReg(false)}
                />
                <label htmlFor="rp">Password</label>
                <svg className="ico toggle-pass" viewBox="0 0 24 24" fill="none" onClick={() => setShowRegPassword(!showRegPassword)}>
                  {showRegPassword ? (
                     <>
                     <path d="M1 12s4-7 11-7 11 7 11 7-4 7-11 7S1 12 1 12Z" stroke="currentColor" strokeWidth="1.5"/>
                     <circle cx="12" cy="12" r="3" stroke="currentColor" strokeWidth="1.5"/>
                     </>
                  ) : (
                    <path d="M17.94 17.94A10.94 10.94 0 0 1 12 19c-7 0-11-7-11-7a21.33 21.33 0 0 1 5.17-5.88M9.88 9.88A3 3 0 0 0 12 15a3 3 0 0 0 2.12-5.12M1 1l22 22" stroke="currentColor" strokeWidth="1.5"/>
                  )}
                </svg>
                <div className={`caps-tip ${capsLockReg ? 'show' : ''}`}>CapsLock ON</div>
              </div>
              <button className="btn" type="submit">Sign Up</button>
            </form>

            <div className="tabs">
              Already have an account? <button className="link-btn" onClick={(e) => toggleTab(e, 'login')}>Login</button>
            </div>
          </div>
        </section>
      </div>
    </div>
  );
}
