import React, { Suspense, lazy } from 'react';
import { BrowserRouter as Router, Routes, Route, useLocation } from 'react-router-dom';
import Navbar from './components/Navbar';
import Footer from './components/Footer';
import ScrollToTop from './components/ScrollToTop';

// Eager load Home for faster LCP
import Home from './pages/Home';

// Lazy load other pages
const UseCases = lazy(() => import('./pages/UseCases'));
const Pricing = lazy(() => import('./pages/Pricing'));
const Research = lazy(() => import('./pages/Research'));
const ResearchArticle = lazy(() => import('./pages/ResearchArticle'));
const VoiceHabitsArticle = lazy(() => import('./pages/VoiceHabitsArticle'));
const TechnicalChallengesArticle = lazy(() => import('./pages/TechnicalChallengesArticle'));
const TryNow = lazy(() => import('./pages/TryNow'));

function App() {


  return (
    <Router>
      <ScrollToTop />
      <AppContent />
    </Router>
  );
}

function AppContent() {
  const [footerHeight, setFooterHeight] = React.useState(0);
  const [revealState, setRevealState] = React.useState({ showTop: false, showBottom: false, isVisible: false });
  const footerRef = React.useRef(null);
  const spacerRef = React.useRef(null);
  const location = useLocation();
  const showFooter = location.pathname !== '/pricing' && location.pathname !== '/try-now';

  React.useEffect(() => {
    // Set body background to black to fix overscroll issue (hide white gap)
    document.body.style.backgroundColor = '#0a0a0a';
    return () => {
      document.body.style.backgroundColor = '';
    };
  }, []);

  React.useEffect(() => {
    if (!footerRef.current || !showFooter) return;

    // Resize Observer for footer height
    const resizeObserver = new ResizeObserver((entries) => {
      for (const entry of entries) {
        setFooterHeight(entry.contentRect.height);
      }
    });

    resizeObserver.observe(footerRef.current.firstChild || footerRef.current);

    return () => resizeObserver.disconnect();
  }, [showFooter]);

  React.useEffect(() => {
    // Intersection Observer for Animation Triggers
    if (!showFooter) return;

    const options = {
      root: null, // viewport
      threshold: [0, 0.5, 0.7] // Triggers at 0%, 50%, 70% visibility
    };

    const observer = new IntersectionObserver(([entry]) => {
      const ratio = entry.intersectionRatio;
      setRevealState({
        isVisible: entry.isIntersecting,
        showTop: ratio >= 0.5,
        showBottom: ratio >= 0.7
      });
    }, options);

    if (spacerRef.current) {
      observer.observe(spacerRef.current);
    }

    return () => observer.disconnect();
  }, [showFooter]);

  return (
    <div className="App">
      <div
        className="main-content"
        style={{
          position: 'relative',
          zIndex: 2,
          backgroundColor: 'var(--bg-color)',
          marginBottom: 0 // We use the spacer now instead of margin
        }}
      >
        {location.pathname !== '/try-now' && <Navbar />}
        <Suspense fallback={<div className="min-h-screen bg-black" />}>
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/use-cases" element={<UseCases />} />
            <Route path="/pricing" element={<Pricing />} />
            <Route path="/research" element={<Research />} />
            <Route path="/research/invisible-interface" element={<ResearchArticle />} />
            <Route path="/research/voice-habits" element={<VoiceHabitsArticle />} />
            <Route path="/research/technical-challenges" element={<TechnicalChallengesArticle />} />
            <Route path="/try-now" element={<TryNow />} />
          </Routes>
        </Suspense>
      </div>
      {/* Physical spacer that pushes content scroll height */}
      {showFooter && (
        <div
          ref={spacerRef}
          className="footer-spacer"
          style={{ height: `${footerHeight}px`, width: '100%', pointerEvents: 'none' }}
        />
      )}
      {showFooter && (
        <div
          ref={footerRef}
          style={{
            position: 'fixed',
            bottom: 0,
            width: '100%',
            zIndex: 1,
            visibility: revealState.isVisible ? 'visible' : 'hidden',
            opacity: revealState.isVisible ? 1 : 0,
            transition: 'opacity 0.1s linear' // Faster toggle
          }}
        >
          <Footer revealState={revealState} />
        </div>
      )}
    </div>
  );
}

export default App;
