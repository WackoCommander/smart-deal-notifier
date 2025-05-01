import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

function App() {
  const [deals, setDeals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [userEmail, setUserEmail] = useState('');
  const [subscribed, setSubscribed] = useState(false);
  
  useEffect(() => {
    // Load user subscription status
    const savedEmail = localStorage.getItem('userEmail');
    if (savedEmail) {
      setUserEmail(savedEmail);
      setSubscribed(true);
    }
    
    // Fetch deals from API
    fetchDeals();
  }, []);
  
  const fetchDeals = async () => {
    try {
      setLoading(true);
      // Replace with your actual API endpoint
      const response = await axios.get('/api/deals');
      setDeals(response.data);
      setLoading(false);
    } catch (err) {
      console.error('Error fetching deals:', err);
      setError('Failed to load deals. Please try again later.');
      setLoading(false);
    }
  };
  
  const handleSubscribe = async (e) => {
    e.preventDefault();
    if (!userEmail) return;
    
    try {
      // Replace with your actual subscription API endpoint
      await axios.post('/api/subscribe', { email: userEmail });
      localStorage.setItem('userEmail', userEmail);
      setSubscribed(true);
      alert('Successfully subscribed to deal notifications!');
    } catch (err) {
      console.error('Error subscribing:', err);
      alert('Failed to subscribe. Please try again.');
    }
  };
  
  const handleUnsubscribe = async () => {
    try {
      // Replace with your actual unsubscribe API endpoint
      await axios.post('/api/unsubscribe', { email: userEmail });
      localStorage.removeItem('userEmail');
      setSubscribed(false);
      setUserEmail('');
      alert('Successfully unsubscribed from notifications.');
    } catch (err) {
      console.error('Error unsubscribing:', err);
      alert('Failed to unsubscribe. Please try again.');
    }
  };
  
  if (loading) return <div className="container">Loading deals...</div>;
  if (error) return <div className="container error">{error}</div>;
  
  return (
    <div className="container">
      <header>
        <h1>🔥 Smart Deal Notifier</h1>
        <p>Never miss a great deal again!</p>
      </header>
      
      <section className="subscription-section">
        {!subscribed ? (
          <form onSubmit={handleSubscribe}>
            <h2>Get Deal Alerts</h2>
            <div className="form-group">
              <input
                type="email"
                placeholder="Enter your email"
                value={userEmail}
                onChange={(e) => setUserEmail(e.target.value)}
                required
              />
              <button type="submit">Subscribe</button>
            </div>
          </form>
        ) : (
          <div className="subscribed">
            <p>You are subscribed with: <strong>{userEmail}</strong></p>
            <button onClick={handleUnsubscribe} className="unsubscribe-btn">
              Unsubscribe
            </button>
          </div>
        )}
      </section>
      
      <section className="deals-section">
        <h2>Latest Deals</h2>
        {deals.length === 0 ? (
          <p>No deals available at the moment. Check back later!</p>
        ) : (
          <div className="deals-grid">
            {deals.map((deal) => (
              <div key={deal.id} className="deal-card">
                <h3>{deal.title}</h3>
                <p className="price">${deal.price}</p>
                <p className="description">{deal.description}</p>
                <a href={deal.url} target="_blank" rel="noopener noreferrer" className="view-deal">
                  View Deal
                </a>
              </div>
            ))}
          </div>
        )}
      </section>
    </div>
  );
}

export default App;