import React from 'react';
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Home from './pages/Home';
import UseCases from './pages/UseCases';
import Pricing from './pages/Pricing';
import Research from './pages/Research';

function App() {
  return (
    <Router>
      <div className="App">
        <Navbar />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/use-cases" element={<UseCases />} />
          <Route path="/pricing" element={<Pricing />} />
          <Route path="/research" element={<Research />} />
        </Routes>
      </div>
    </Router>
  );
}

export default App;
