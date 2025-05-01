import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';
import DealCard from './DealCard';

const App = () => {
  const [deals, setDeals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [userEmail, setUserEmail] = useState('');
  const [subscribed, setSubscribed] = useState(false);
  const [categories] = useState(['Electronics', 'Clothing', 'Home', 'Toys']);
  const [selectedCategory, setSelectedCategory] = useState('all');
  
  // Load saved data from localStorage on component mount
  useEffect(() => {
    const savedEmail = localStorage.getItem('userEmail');
    if (savedEmail) {
      setUserEmail(savedEmail);
      setSubscribed(true);
    }
    
    fetchDeals();
  }, []);
  
  const fetchDeals = async () => {
    try {
      setLoading(true);
      // In a real app, you would fetch from your actual API
      // For now, let's use a dummy response for testing
      
      // Replace this with actual API call when ready
      // const response = await axios.get('/api/deals');
      
      // Dummy data for testing
      const dummyDeals = [
        {
          DealID: '1',
          DealName: 'MacBook Pro 13" M2',
          DealURL: 'https://example.com/deal1',
          VoteUp: 45,
          VoteDown: 5,
          UserNotified: false,
          UserRelevant: true,
          RelevanceAssessed: true
        },
        {
          DealID: '2',
          DealName: 'AirPods Pro 2nd Gen',
          DealURL: 'https://example.com/deal2',
          VoteUp: 32,
          VoteDown: 2,
          UserNotified: true,
          UserRelevant: true,
          RelevanceAssessed: true
        }
      ];
      
      setDeals(dummyDeals);
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
      // In a real app, you would call your subscribe API
      // await axios.post('/api/subscribe', { email: userEmail });
      
      // For now, just save to localStorage
      localStorage.setItem('userEmail', userEmail);
      setSubscribed(true);
      alert('Successfully subscribed! Please check your email to confirm.');
    } catch (err) {
      console.error('Error subscribing:', err);
      alert('Failed to subscribe. Please try again.');
    }
  };
  
  const handleUnsubscribe = async () => {
    try {
      // In a real app, you would call your unsubscribe API
      // await axios.post('/api/unsubscribe', { email: userEmail });
      
      localStorage.removeItem('userEmail');
      setSubscribed(false);
      setUserEmail('');
      alert('Successfully unsubscribed from notifications.');
    } catch (err) {
      console.error('Error unsubscribing:', err);
      alert('Failed to unsubscribe. Please try again.');
    }
  };
  
  const handleNotify = async (deal) => {
    try {
      // In a real app, you would call your notification API
      // await axios.post('/api/notify', deal);
      
      // For now, just update the local state
      setDeals(deals.map(d => 
        d.DealID === deal.DealID ? { ...d, UserNotified: true } : d
      ));
      alert(`You'll be notified about "${deal.DealName}"`);
    } catch (err) {
      console.error('Error sending notification:', err);
      alert('Failed to set up notification. Please try again.');
    }
  };
  
  const filterDealsByCategory = () => {
    // For now, we're not implementing real filtering
    // In a real app, you would filter based on category
    return deals;
  };
  
  if (loading) return <div className="loading-container"><div className="loading-spinner"></div></div>;
  
  if (error) return <div className="error-container">{error}</div>;
  
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
              <select 
                value={selectedCategory} 
                onChange={(e) => setSelectedCategory(e.target.value)}
                className="category-select"
              >
                <option value="all">All Categories</option>
                {categories.map(category => (
                  <option key={category} value={category}>{category}</option>
                ))}
              </select>
              <button type="submit" className="subscribe-btn">Subscribe</button>
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
        <div className="deals-header">
          <h2>Latest Deals</h2>
          <div className="filter-controls">
            <label htmlFor="category-filter">Filter by: </label>
            <select 
              id="category-filter"
              value={selectedCategory} 
              onChange={(e) => setSelectedCategory(e.target.value)}
            >
              <option value="all">All Categories</option>
              {categories.map(category => (
                <option key={category} value={category}>{category}</option>
              ))}
            </select>
            <button onClick={fetchDeals} className="refresh-btn">
              ↻ Refresh
            </button>
          </div>
        </div>
        
        <div className="deals-grid">
          {filterDealsByCategory().map(deal => (
            <DealCard 
              key={deal.DealID} 
              deal={deal} 
              onNotify={handleNotify} 
            />
          ))}
        </div>
      </section>
      
      <footer>
        <p>© {new Date().getFullYear()} Smart Deal Notifier - Powered by AWS</p>
      </footer>
    </div>
  );
};

export default App;