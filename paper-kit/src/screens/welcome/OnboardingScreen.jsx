import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Sparkles,
  ShieldCheck,
  Layers,
  Zap,
  MessageSquare,
  Table,
  ScanText,
  ShieldAlert,
  PenTool,
  Archive,
  Grid,
  Globe,
  Cpu,
  Gauge,
  FileText,
  Brain,
  Clock,
  ChevronRight,
  ChevronLeft,
  ArrowRight,
  CheckCircle2,
  AlertTriangle,
  Info
} from 'lucide-react';
import ParticleBackground from '../../components/ui/ParticleBackground';
import { useI18n } from '../../context/I18nContext';
import { probeBothRenderServices } from '../../services/backendHealth';
import './OnboardingScreen.css';

export default function OnboardingScreen({ onFinish = null }) {
  const navigate = useNavigate();
  const { t, lang, setLang, supportedLanguages } = useI18n();
  const [currentSlideIndex, setCurrentSlideIndex] = useState(0);
  const [touchStartX, setTouchStartX] = useState(null);
  const autoPlayTimerRef = useRef(null);

  // Background boot-up poller for Render 50s cold start
  useEffect(() => {
    let isMounted = true;
    let timerId = null;

    async function pollCloudBoot() {
      if (!isMounted) return;
      try {
        const res = await probeBothRenderServices(5000);
        if (isMounted && res.backendOk) {
          return; // Backend is booted and ready
        }
      } catch {
        // continue polling
      }
      if (isMounted) {
        timerId = setTimeout(pollCloudBoot, 3000);
      }
    }

    pollCloudBoot();
    return () => {
      isMounted = false;
      if (timerId) clearTimeout(timerId);
    };
  }, []);

  const onboardingPages = useMemo(() => [
    {
      id: 1,
      badge: t('ob_s1_badge'),
      title: t('ob_s1_title'),
      subtitle: t('ob_s1_sub'),
      icon: Sparkles,
      iconColor: '#2563EB',
      bgColor: 'rgba(37, 99, 235, 0.12)',
      highlightColor: '#2563EB',
      features: [
        t('ob_s1_f1'),
        t('ob_s1_f2'),
        t('ob_s1_f3')
      ]
    },
    {
      id: 2,
      badge: t('ob_s2_badge'),
      title: t('ob_s2_title'),
      subtitle: t('ob_s2_sub'),
      icon: ShieldCheck,
      iconColor: '#059669',
      bgColor: 'rgba(5, 150, 105, 0.12)',
      highlightColor: '#059669',
      features: [
        t('ob_s2_f1'),
        t('ob_s2_f2'),
        t('ob_s2_f3')
      ]
    },
    {
      id: 3,
      badge: t('ob_s3_badge'),
      title: t('ob_s3_title'),
      subtitle: t('ob_s3_sub'),
      icon: Layers,
      iconColor: '#7C3AED',
      bgColor: 'rgba(124, 58, 237, 0.12)',
      highlightColor: '#7C3AED',
      features: [
        t('ob_s3_f1'),
        t('ob_s3_f2'),
        t('ob_s3_f3')
      ]
    },
    {
      id: 4,
      badge: t('ob_s4_badge'),
      title: t('ob_s4_title'),
      subtitle: t('ob_s4_sub'),
      icon: Zap,
      iconColor: '#D97706',
      bgColor: 'rgba(217, 119, 6, 0.12)',
      highlightColor: '#D97706',
      features: [
        t('ob_s4_f1'),
        t('ob_s4_f2'),
        t('ob_s4_f3')
      ]
    },
    {
      id: 5,
      badge: t('ob_s5_badge'),
      title: t('ob_s5_title'),
      subtitle: t('ob_s5_sub'),
      icon: MessageSquare,
      iconColor: '#2563EB',
      bgColor: 'rgba(37, 99, 235, 0.12)',
      highlightColor: '#2563EB',
      features: [
        t('ob_s5_f1'),
        t('ob_s5_f2'),
        t('ob_s5_f3')
      ]
    },
    {
      id: 6,
      badge: t('ob_s6_badge'),
      title: t('ob_s6_title'),
      subtitle: t('ob_s6_sub'),
      icon: Table,
      iconColor: '#059669',
      bgColor: 'rgba(5, 150, 105, 0.12)',
      highlightColor: '#059669',
      features: [
        t('ob_s6_f1'),
        t('ob_s6_f2'),
        t('ob_s6_f3')
      ]
    },
    {
      id: 7,
      badge: t('ob_s7_badge'),
      title: t('ob_s7_title'),
      subtitle: t('ob_s7_sub'),
      icon: ScanText,
      iconColor: '#7C3AED',
      bgColor: 'rgba(124, 58, 237, 0.12)',
      highlightColor: '#7C3AED',
      features: [
        t('ob_s7_f1'),
        t('ob_s7_f2'),
        t('ob_s7_f3')
      ]
    },
    {
      id: 8,
      badge: t('ob_s8_badge'),
      title: t('ob_s8_title'),
      subtitle: t('ob_s8_sub'),
      icon: ShieldAlert,
      iconColor: '#DC2626',
      bgColor: 'rgba(220, 38, 38, 0.12)',
      highlightColor: '#DC2626',
      features: [
        t('ob_s8_f1'),
        t('ob_s8_f2'),
        t('ob_s8_f3')
      ]
    },
    {
      id: 9,
      badge: t('ob_s9_badge'),
      title: t('ob_s9_title'),
      subtitle: t('ob_s9_sub'),
      icon: PenTool,
      iconColor: '#2563EB',
      bgColor: 'rgba(37, 99, 235, 0.12)',
      highlightColor: '#2563EB',
      features: [
        t('ob_s9_f1'),
        t('ob_s9_f2'),
        t('ob_s9_f3')
      ]
    },
    {
      id: 10,
      badge: t('ob_s10_badge'),
      title: t('ob_s10_title'),
      subtitle: t('ob_s10_sub'),
      icon: Archive,
      iconColor: '#D97706',
      bgColor: 'rgba(217, 119, 6, 0.12)',
      highlightColor: '#D97706',
      features: [
        t('ob_s10_f1'),
        t('ob_s10_f2'),
        t('ob_s10_f3')
      ]
    },
    {
      id: 11,
      badge: t('ob_s11_badge'),
      title: t('ob_s11_title'),
      subtitle: t('ob_s11_sub'),
      icon: Grid,
      iconColor: '#059669',
      bgColor: 'rgba(5, 150, 105, 0.12)',
      highlightColor: '#059669',
      features: [
        t('ob_s11_f1'),
        t('ob_s11_f2'),
        t('ob_s11_f3')
      ]
    },
    {
      id: 12,
      badge: t('ob_s12_badge'),
      title: t('ob_s12_title'),
      subtitle: t('ob_s12_sub'),
      icon: Globe,
      iconColor: '#7C3AED',
      bgColor: 'rgba(124, 58, 237, 0.12)',
      highlightColor: '#7C3AED',
      features: [
        t('ob_s12_f1'),
        t('ob_s12_f2'),
        t('ob_s12_f3')
      ]
    },
    {
      id: 13,
      badge: t('ob_s13_badge'),
      title: t('ob_s13_title'),
      subtitle: t('ob_s13_sub'),
      icon: Cpu,
      iconColor: '#2563EB',
      bgColor: 'rgba(37, 99, 235, 0.12)',
      highlightColor: '#2563EB',
      features: [
        t('ob_s13_f1'),
        t('ob_s13_f2'),
        t('ob_s13_f3')
      ]
    },
    {
      id: 14,
      type: 'rate-limits',
      badge: t('ob_s14_badge'),
      title: t('ob_s14_title'),
      subtitle: t('ob_s14_sub'),
      icon: Gauge,
      iconColor: '#EA580C',
      bgColor: 'rgba(234, 88, 12, 0.10)',
      highlightColor: '#EA580C',
      limits: [
        {
          category: t('ob_s14_pdf_cat'),
          icon: 'pdf',
          color: '#DC2626',
          softColor: 'rgba(220,38,38,0.10)',
          borderColor: 'rgba(220,38,38,0.22)',
          rule: t('ob_s14_pdf_rule'),
          note: t('ob_s14_pdf_note'),
          tip: t('ob_s14_pdf_tip'),
        },
        {
          category: t('ob_s14_ai_cat'),
          icon: 'ai',
          color: '#7C3AED',
          softColor: 'rgba(124,58,237,0.10)',
          borderColor: 'rgba(124,58,237,0.22)',
          rule: t('ob_s14_ai_rule'),
          note: t('ob_s14_ai_note'),
          tip: t('ob_s14_ai_tip'),
        },
      ],
      features: [
        t('ob_s14_f1'),
        t('ob_s14_f2')
      ]
    }
  ], [t]);

  const totalPages = onboardingPages.length;
  const currentPage = onboardingPages[currentSlideIndex];
  const IconComponent = currentPage.icon;
  const isLastPage = currentSlideIndex === totalPages - 1;

  const handleNext = useCallback(() => {
    setCurrentSlideIndex((prev) => (prev < totalPages - 1 ? prev + 1 : prev));
  }, [totalPages]);

  const handlePrev = useCallback(() => {
    setCurrentSlideIndex((prev) => (prev > 0 ? prev - 1 : prev));
  }, []);

  const handleFinish = useCallback(() => {
    try {
      localStorage.setItem('paperkit_onboarding_done', 'true');
    } catch {
      // Ignore storage error
    }
    if (onFinish) {
      onFinish();
    } else {
      navigate('/', { replace: true });
    }
  }, [navigate, onFinish]);

  /* Keyboard arrows navigation */
  useEffect(() => {
    function handleKeyDown(e) {
      if (e.key === 'ArrowRight' || e.key === 'Space') {
        if (!isLastPage) handleNext();
        else handleFinish();
      } else if (e.key === 'ArrowLeft') {
        handlePrev();
      }
    }
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [handleNext, handlePrev, handleFinish, isLastPage]);

  /* Automatic slide transition (pause if user moves) */
  useEffect(() => {
    if (!isLastPage) {
      autoPlayTimerRef.current = setTimeout(() => {
        handleNext();
      }, 5000);
    }
    return () => {
      if (autoPlayTimerRef.current) clearTimeout(autoPlayTimerRef.current);
    };
  }, [currentSlideIndex, handleNext, isLastPage]);

  /* Touch Swiping */
  function handleTouchStart(e) {
    setTouchStartX(e.touches[0].clientX);
  }

  function handleTouchEnd(e) {
    if (touchStartX === null) return;
    const touchEndX = e.changedTouches[0].clientX;
    const diffX = touchStartX - touchEndX;

    if (diffX > 40) {
      if (!isLastPage) handleNext();
    } else if (diffX < -40) {
      handlePrev();
    }
    setTouchStartX(null);
  }

  const progressPercent = Math.round(((currentSlideIndex + 1) / totalPages) * 100);
  const currentLanguageObj = supportedLanguages.find(l => l.code === lang) || supportedLanguages[0];

  return (
    <div
      className="onboarding-screen onboarding-screen--light-theme"
      onTouchStart={handleTouchStart}
      onTouchEnd={handleTouchEnd}
    >
      {/* Dynamic Animated Particle Background */}
      <ParticleBackground />

      {/* Ambient lighting */}
      <div className="onboarding-screen__glow-1" style={{ background: currentPage.bgColor }} />
      <div className="onboarding-screen__glow-2" />

      {/* Top Header Bar with Language Selector & Brand */}
      <header className="onboarding-screen__topbar">
        <div className="onboarding-screen__brand-pill">
          <img src="/icon-48.png" alt="PaperKit Logo" width="22" height="22" style={{ borderRadius: '6px' }} />
          <span className="onboarding-screen__brand-name">PaperKit</span>
          <span className="onboarding-screen__brand-badge">{t('ob_badge_tour')}</span>
        </div>

        <div className="onboarding-screen__top-actions">
          {/* Language Selector Dropdown */}
          <div className="onboarding-screen__lang-pill">
            <Globe size={14} color="#2563EB" />
            <select
              value={lang}
              onChange={e => setLang(e.target.value)}
              className="onboarding-screen__lang-select"
              aria-label="Select Language"
              id="onboarding-language-selector"
            >
              {supportedLanguages.map(l => (
                <option key={l.code} value={l.code}>
                  {l.flag} {l.nativeName} ({l.name})
                </option>
              ))}
            </select>
            <span className="onboarding-screen__active-lang-code">{currentLanguageObj.flag}</span>
          </div>

          {/* Quick Skip button */}
          <button
            type="button"
            className="onboarding-screen__skip-btn"
            onClick={handleFinish}
            title={t('ob_skip')}
          >
            {t('ob_skip')}
          </button>
        </div>
      </header>

      {/* Top Visual Progress Line */}
      <div className="onboarding-screen__progress-container">
        <div
          className="onboarding-screen__progress-bar"
          style={{
            width: `${progressPercent}%`,
            background: currentPage.highlightColor
          }}
        />
      </div>

      {/* Main Slide Card Container */}
      <main className="onboarding-screen__main">
        <div className="onboarding-screen__card" key={`${currentPage.id}-${lang}`}>
          {/* Badge & Icon Header */}
          <div className="onboarding-screen__card-header">
            <div
              className="onboarding-screen__icon-orb"
              style={{
                backgroundColor: currentPage.bgColor,
                borderColor: `${currentPage.highlightColor}33`
              }}
            >
              <IconComponent size={38} color={currentPage.iconColor} />
            </div>

            <span
              className="onboarding-screen__badge"
              style={{
                color: currentPage.highlightColor,
                backgroundColor: currentPage.bgColor,
                borderColor: `${currentPage.highlightColor}40`
              }}
            >
              {currentPage.badge}
            </span>
          </div>

          {/* Slide Text Content */}
          <h2 className="onboarding-screen__title">{currentPage.title}</h2>
          <p className="onboarding-screen__subtitle">{currentPage.subtitle}</p>

          {/* Feature Bullets — standard slides */}
          {currentPage.type !== 'rate-limits' && (
            <div className="onboarding-screen__features-list">
              {currentPage.features.map((feat, idx) => (
                <div key={idx} className="onboarding-screen__feature-item">
                  <CheckCircle2
                    size={18}
                    color={currentPage.highlightColor}
                    className="onboarding-screen__feature-icon"
                  />
                  <span>{feat}</span>
                </div>
              ))}
            </div>
          )}

          {/* Rate Limits special slide */}
          {currentPage.type === 'rate-limits' && (
            <div className="ob-rate-limits">
              {currentPage.limits.map((limit, idx) => (
                <div
                  key={idx}
                  className="ob-rate-limit-card"
                  style={{ borderColor: limit.borderColor, background: limit.softColor }}
                >
                  {/* Card header */}
                  <div className="ob-rate-limit-card__header">
                    <div
                      className="ob-rate-limit-card__icon-bubble"
                      style={{ background: limit.softColor, borderColor: limit.borderColor }}
                    >
                      {limit.icon === 'pdf'
                        ? <FileText size={18} color={limit.color} />
                        : <Brain size={18} color={limit.color} />}
                    </div>
                    <div>
                      <div className="ob-rate-limit-card__category" style={{ color: limit.color }}>
                        {limit.category}
                      </div>
                      <div className="ob-rate-limit-card__rule">
                        {limit.rule}
                      </div>
                    </div>
                    <div
                      className="ob-rate-limit-card__badge"
                      style={{ color: limit.color, background: limit.softColor, borderColor: limit.borderColor }}
                    >
                      {idx === 0 ? <><FileText size={11} /> PDF</> : <><Clock size={11} /> AI</>}
                    </div>
                  </div>
                  {/* Applies to note */}
                  <p className="ob-rate-limit-card__note">
                    <Info size={12} style={{ flexShrink: 0, marginTop: 2 }} />
                    {limit.note}
                  </p>
                  {/* Tip */}
                  <div className="ob-rate-limit-card__tip">
                    <AlertTriangle size={12} color="#92400E" style={{ flexShrink: 0, marginTop: 1 }} />
                    <span>{limit.tip}</span>
                  </div>
                </div>
              ))}
              {/* Bottom always-unlimited note */}
              <div className="ob-rate-limit-card__footer">
                {currentPage.features.map((f, i) => (
                  <div key={i} className="onboarding-screen__feature-item" style={{ fontSize: '0.82rem' }}>
                    <CheckCircle2 size={14} color={currentPage.highlightColor} className="onboarding-screen__feature-icon" />
                    <span>{f}</span>
                  </div>
                ))}
              </div>
            </div>
          )}

        </div>
      </main>

      {/* Bottom Controls Bar */}
      <footer className="onboarding-screen__footer">
        {/* Slide Dots Indicator */}
        <div className="onboarding-screen__dots">
          {onboardingPages.map((page, index) => (
            <button
              key={page.id}
              type="button"
              className={`onboarding-screen__dot ${index === currentSlideIndex ? 'onboarding-screen__dot--active' : ''
                }`}
              style={{
                backgroundColor:
                  index === currentSlideIndex
                    ? currentPage.highlightColor
                    : 'rgba(255, 255, 255, 0.3)'
              }}
              onClick={() => setCurrentSlideIndex(index)}
              aria-label={`Go to slide ${index + 1}`}
            />
          ))}
        </div>

        {/* Action Controls */}
        <div className="onboarding-screen__nav-buttons">
          {currentSlideIndex > 0 && (
            <button
              type="button"
              className="onboarding-screen__nav-btn onboarding-screen__nav-btn--secondary"
              onClick={handlePrev}
            >
              <ChevronLeft size={18} />
              <span>{t('ob_prev')}</span>
            </button>
          )}

          {!isLastPage ? (
            <button
              type="button"
              className="onboarding-screen__nav-btn onboarding-screen__nav-btn--primary"
              style={{ backgroundColor: currentPage.highlightColor }}
              onClick={handleNext}
            >
              <span>{t('ob_next')}</span>
              <ChevronRight size={18} />
            </button>
          ) : (
            <button
              type="button"
              className="onboarding-screen__finish-btn"
              onClick={handleFinish}
              id="onboarding-enter-studio-btn"
            >
              <span>{t('ob_finish')}</span>
              <ArrowRight size={18} />
            </button>
          )}
        </div>
      </footer>
    </div>
  );
}
