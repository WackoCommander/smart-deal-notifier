import React, { useState } from 'react';
import './App.css';

// Simple inline deal card component to avoid import issues
const SimpleDealCard = ({ deal }) => (
  <div className="border p-4 m-2 bg-white">
    <h3>{deal.title}</h3>
    <p>Votes: {deal.votes} | {deal.notified ? "Notified" : "Not Notified"}</p>
    <a href={deal.url} className="text-blue-600">View Deal</a>
  </div>
);

const App = () => {
  const [email, setEmail] = useState('');
  
  // Sample deals data
  const deals = [
    { id: 1, title: "MacBook Pro Deal", votes: 42, url: "#", notified: false },
    { id: 2, title: "AirPods Pro Sale", votes: 28, url: "#", notified: true }
  ];
  
  const handleSubscribe = (e) => {
    e.preventDefault();
    alert(`Subscribed with email: ${email}`);
  };
  
  return (
    <div className="container">
      <header>
        <h1>🔥 Smart Deal Notifier</h1>
        <p>Never miss a great deal again!</p>
      </header>
      
      <section className="subscription-section">
        <form onSubmit={handleSubscribe}>
          <h2>Get Deal Alerts</h2>
          <div className="form-group">
            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            <button type="submit" className="subscribe-btn">Subscribe</button>
          </div>
        </form>
      </section>
      
      <section className="deals-section">
        <h2>Latest Deals</h2>
        {deals.map(deal => (
          <SimpleDealCard key={deal.id} deal={deal} />
        ))}
      </section>
      
      <footer>
        <p>© {new Date().getFullYear()} Smart Deal Notifier - Powered by AWS</p>
      </footer>
    </div>
  );
};

export default App;