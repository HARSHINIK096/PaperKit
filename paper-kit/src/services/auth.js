import api from './api';

export async function getMe() {
  const token = localStorage.getItem('pk_token');
  if (!token || token === 'guest_access_token') {
    const stored = localStorage.getItem('pk_user_profile');
    if (stored) {
      try {
        return JSON.parse(stored);
      } catch {
        // Fallback
      }
    }
    return {
      _id: 'local_user',
      name: 'Open Source User',
      email: 'user@paperkit.local',
      preferences: { dark_mode: false, default_view: 'list', language: 'en' },
    };
  }

  try {
    const res = await api.get('/auth/me');
    return res.data;
  } catch {
    return {
      _id: 'local_user',
      name: 'Open Source User',
      email: 'user@paperkit.local',
      preferences: { dark_mode: false, default_view: 'list', language: 'en' },
    };
  }
}

export async function logout() {
  localStorage.removeItem('pk_token');
  localStorage.removeItem('pk_user_profile');
}

export async function updateMe(data) {
  const token = localStorage.getItem('pk_token');
  if (!token || token === 'guest_access_token') {
    let storedUser = {};
    const rawUser = localStorage.getItem('pk_user_profile');
    if (rawUser) {
      try {
        storedUser = JSON.parse(rawUser);
      } catch {
        storedUser = {};
      }
    }

    const updatedUser = {
      _id: 'local_user',
      name: data.name || storedUser.name || 'Open Source User',
      email: storedUser.email || 'user@paperkit.local',
      preferences: {
        ...(storedUser.preferences || { dark_mode: false, default_view: 'list', language: 'en' }),
        ...(data.preferences || {}),
      },
    };
    try {
      localStorage.setItem('pk_user_profile', JSON.stringify(updatedUser));
    } catch {
      // Ignore storage error
    }
    return updatedUser;
  }

  try {
    const res = await api.put('/auth/me', data);
    return res.data;
  } catch {
    return data;
  }
}

export async function deleteAccount() {
  return { status: 'ok' };
}

export async function endSessionAndClearStorage() {
  try {
    await api.delete('/auth/clear-session');
  } catch (err) {
    console.warn("Backend session clear error/offline:", err);
  }

  // Clear all localStorage & sessionStorage
  try {
    localStorage.clear();
  } catch (e) {
    console.warn("localStorage clear error:", e);
  }
  try {
    sessionStorage.clear();
  } catch (e) {
    console.warn("sessionStorage clear error:", e);
  }

  // Clear all IndexedDB databases
  if (typeof window !== 'undefined' && window.indexedDB && window.indexedDB.databases) {
    try {
      const dbs = await window.indexedDB.databases();
      for (const db of dbs) {
        if (db.name) {
          window.indexedDB.deleteDatabase(db.name);
        }
      }
    } catch (e) {
      console.warn("IndexedDB clear error:", e);
    }
  }

  // Clear all CacheStorage
  if (typeof window !== 'undefined' && window.caches) {
    try {
      const cacheNames = await window.caches.keys();
      await Promise.all(cacheNames.map(name => window.caches.delete(name)));
    } catch (e) {
      console.warn("CacheStorage clear error:", e);
    }
  }

  // Clear cookies
  if (typeof document !== 'undefined') {
    try {
      const cookies = document.cookie.split(";");
      for (let i = 0; i < cookies.length; i++) {
        const cookie = cookies[i];
        const eqPos = cookie.indexOf("=");
        const name = eqPos > -1 ? cookie.substr(0, eqPos).trim() : cookie.trim();
        document.cookie = name + "=;expires=Thu, 01 Jan 1970 00:00:00 GMT;path=/";
      }
    } catch {}
  }
}
