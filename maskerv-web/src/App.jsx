import { useEffect } from 'react';
import { BrowserRouter } from 'react-router-dom';
import { AuthProvider, useAuth } from './hooks/useAuth';
import { I18nProvider } from './context/I18nContext';
import { prewarmBackend } from './services/api';
import { configureStatusBar } from './services/native';
import AppRouter from './router/index';
import './index.css';

function ThemeApp() {
  const { user } = useAuth();

  useEffect(() => {
    prewarmBackend();
    configureStatusBar(false);

    // Auto-delete backend session data and storage chunks when the session/window is closed
    function handleSessionClose() {
      const apiUrl = import.meta.env.VITE_API_URL || 'https://paperkit-backend.onrender.com';
      const clearUrl = `${apiUrl}/auth/clear-session`;
      try {
        if (typeof navigator !== 'undefined' && navigator.sendBeacon) {
          navigator.sendBeacon(clearUrl);
        } else {
          fetch(clearUrl, { method: 'POST', keepalive: true }).catch(() => {});
        }
      } catch (err) {
        console.warn('Session auto-clean trigger failed:', err);
      }
    }

    window.addEventListener('pagehide', handleSessionClose);
    window.addEventListener('beforeunload', handleSessionClose);
    return () => {
      window.removeEventListener('pagehide', handleSessionClose);
      window.removeEventListener('beforeunload', handleSessionClose);
    };
  }, []);

  useEffect(() => {
    const isDark = Boolean(user?.preferences?.dark_mode);
    if (isDark) {
      document.documentElement.setAttribute('data-theme', 'dark');
    } else {
      document.documentElement.removeAttribute('data-theme');
    }
    if (user?.preferences?.language) {
      document.documentElement.lang = user.preferences.language;
    }
    configureStatusBar(isDark);
  }, [user]);

  return (
    <I18nProvider>
      <AppRouter />
    </I18nProvider>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <ThemeApp />
      </AuthProvider>
    </BrowserRouter>
  );
}
