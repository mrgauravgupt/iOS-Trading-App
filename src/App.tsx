import React from 'react';
import './App.css';

function App() {
  return (
    <div className="app">
      {/* Header */}
      <header className="app-header">
        <div className="container">
          <nav className="nav">
            <div className="nav-brand">
              <h1 className="brand-title">React App</h1>
            </div>
            <div className="nav-links">
              <a href="#home" className="nav-link">Home</a>
              <a href="#about" className="nav-link">About</a>
              <a href="#contact" className="nav-link">Contact</a>
            </div>
          </nav>
        </div>
      </header>

      {/* Main Content */}
      <main className="app-main">
        <div className="container">
          {/* Hero Section */}
          <section className="hero">
            <div className="hero-content">
              <h2 className="hero-title">
                Welcome to Your Enhanced React App
              </h2>
              <p className="hero-description">
                A beautifully designed, full-screen application with modern styling,
                perfect typography, and responsive layout that adapts to any screen size.
              </p>
              <div className="hero-actions">
                <button className="btn btn-primary">Get Started</button>
                <button className="btn btn-secondary">Learn More</button>
              </div>
            </div>
          </section>

          {/* Features Section */}
          <section className="features">
            <div className="features-grid">
              <div className="feature-card">
                <div className="feature-icon">🎨</div>
                <h3 className="feature-title">Modern Design</h3>
                <p className="feature-description">
                  Clean, elegant interface with carefully crafted spacing and typography.
                </p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">📱</div>
                <h3 className="feature-title">Responsive</h3>
                <p className="feature-description">
                  Perfectly optimized for desktop, tablet, and mobile devices.
                </p>
              </div>
              <div className="feature-card">
                <div className="feature-icon">⚡</div>
                <h3 className="feature-title">Fast & Efficient</h3>
                <p className="feature-description">
                  Built with performance in mind using modern React patterns.
                </p>
              </div>
            </div>
          </section>
        </div>
      </main>

      {/* Footer */}
      <footer className="app-footer">
        <div className="container">
          <div className="footer-content">
            <p className="footer-text">
              © 2024 React App. Built with ❤️ using React & TypeScript.
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}

export default App;
