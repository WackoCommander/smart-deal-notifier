import React from 'react';
import DealsPage from './DealsPage';
import './App.css';

function App() {
  return (
    <div className="app">
      <DealsPage />
      <footer className="app-footer">
        <p>© {new Date().getFullYear()} Smart Deal Notifier</p>
      </footer>
    </div>
  );
}

export default App;