import React from 'react';
import Hero from './components/Hero';
import Features from './components/Features';
import DemoSection from './components/DemoSection';
import Footer from './components/Footer';
import Dashboard from './components/Dashboard'; // Keeping this import available if needed, but not rendering it by default.

function App() {
  // Simple routing check (can be expanded later)
  const path = window.location.pathname;

  if (path === '/dashboard') {
    return <Dashboard />;
  }

  return (
    <div className="App">
      <nav className="navbar">
        <div className="container navbar-container">
          <div className="logo">VoiceScribe</div>
          <div className="nav-links">
            <a href="#features">Features</a>
            <a href="#demo">Demo</a>
            <button className="btn-primary small">Get App</button>
          </div>
        </div>
      </nav>

      <main>
        <Hero />
        <div id="features">
          <Features />
        </div>
        <div id="demo">
          <DemoSection />
        </div>
      </main>

      <Footer />

      <style>{`
        .navbar {
          position: fixed;
          top: 0;
          left: 0;
          width: 100%;
          z-index: 100;
          background: rgba(10, 10, 10, 0.8);
          backdrop-filter: blur(10px);
          border-bottom: 1px solid var(--card-border);
          padding: 1rem 0;
        }

        .navbar-container {
          display: flex;
          justify-content: space-between;
          align-items: center;
        }

        .logo {
          font-size: 1.5rem;
          font-weight: 700;
          background: linear-gradient(to right, #fff, #ccc);
          -webkit-background-clip: text;
          -webkit-text-fill-color: transparent;
        }

        .nav-links {
          display: flex;
          align-items: center;
          gap: 2rem;
        }

        .nav-links a {
          color: var(--text-secondary);
          font-size: 0.95rem;
          font-weight: 500;
        }

        .nav-links a:hover {
          color: white;
        }

        .btn-primary.small {
          padding: 0.5rem 1.2rem;
          font-size: 0.9rem;
        }

        @media (max-width: 768px) {
          .nav-links {
            display: none; /* Simple mobile menu hiding for now */
          }
        }
      `}</style>
    </div>
  );
}

export default App;
