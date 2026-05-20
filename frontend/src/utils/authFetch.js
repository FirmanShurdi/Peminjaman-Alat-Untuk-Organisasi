/**
 * authFetch — wrapper fetch dengan dual-auth support.
 *
 * Strategi:
 *  - Kirim cookie httpOnly otomatis (credentials: 'include')
 *  - Sekaligus kirim Authorization header dari localStorage sebagai fallback
 *    (untuk user yang login sebelum cookie diimplementasi)
 *
 * Backend authJWT.js sudah mendukung keduanya (cookie prioritas, lalu Bearer).
 * Semua logika JWT ada di: Projek_A/config/middleware/authJWT.js
 */

const FLASH_KEY = 'flash_message';

export function redirectToLogin(msg = 'Sesi habis. Silakan login kembali.') {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    localStorage.setItem(FLASH_KEY, JSON.stringify({ type: 'error', message: msg }));
    window.location.replace('/login');
}

export async function authFetch(url, options = {}) {
    const token = localStorage.getItem('token');

    const headers = {
        ...(options.headers || {}),
        // Tetap kirim Bearer agar backward compat (user belum punya cookie)
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
    };

    // Jangan override Content-Type untuk FormData
    if (!(options.body instanceof FormData) && !headers['Content-Type']) {
        headers['Content-Type'] = 'application/json';
    }

    const res = await fetch(url, {
        ...options,
        headers,
        credentials: 'include', // kirim cookie httpOnly sekaligus
    });

    if (res.status === 401) {
        const data = await res.json().catch(() => ({}));
        redirectToLogin(data.message);
        return new Promise(() => {}); // hentikan eksekusi pemanggil
    }

    return res;
}
