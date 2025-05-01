import React, { useState, useEffect } from 'react';
import { fetchDeals, subscribeToDeals, unsubscribeFromDeals } from './api';
import DealCard from './DealCard';
import './App.css';

const App = () => {
  const [deals, setDeals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [userEmail, setUserEmail] = useState('');
  const [subscribed, setSubscribed] = useState(false);
  const [categories, setCategories] = useState(['Electronics', 'Clothing', 'Home', 'Toys', 'Travel']);
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [notification, setNotification] = useState(null);
  
  useEffect(() => {
    // Load user subscription status from local storage
    const savedEmail = localStorage.getItem('userEmail');
    if (savedEmail) {
      setUserEmail(savedEmail);
      setSubscribed(true);
    }
    
    // Fetch deals from API
    fetchDeals().catch(error => {});
  }, []);
  
  // Handle API calls with proper loading and error states
  const fetchDealsWithState = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await fetchDeals();
      setDeals(data);
    } catch (err) {
      console.error('Error fetching deals:', err);
      setError('Failed to load deals. Please try again later.');
    } finally {
      setLoading(false);
    }
  };
  
  // Fetch deals on initial load
  useEffect(() => {
    fetchDealsWithState();
  }, []);
  
  // Show notifications temporarily then fade out
  const showNotification = (message, type = 'success') => {
    setNotification({ message, type });
    // Auto-dismiss after 5 seconds
    setTimeout(() => setNotification(null), 5000);
  };
  
  const handleSubscribe = async (e) => {
    e.preventDefault();
    if (!userEmail) return;
    
    try {
      setLoading(true);
      await subscribeToDeals(
        userEmail, 
        selectedCategory === 'all' ? [] : [selectedCategory]
      );
      
      localStorage.setItem('userEmail', userEmail);
      setSubscribed(true);
      showNotification('Successfully subscribed to deal notifications! Please check your email to confirm subscription.');
    } catch (err) {
      showNotification(err.message || 'Failed to subscribe. Please try again.', 'error');
    } finally {
      setLoading(false);
    }
  };
  
  const handleUnsubscribe = async () => {
    try {
      setLoading(true);
      await unsubscribeFromDeals(userEmail);
      localStorage.removeItem('userEmail');
      setSubscribed(false);
      setUserEmail('');
      showNotification('Successfully unsubscribed from notifications.');
    } catch (err) {
      showNotification(err.message || 'Failed to unsubscribe. Please try again.', 'error');
    } finally {
      setLoading(false);
    }
  };
  
  const filterDealsByCategory = (deals) => {
    if (selectedCategory === 'all') return deals;
    return deals.filter(deal => deal.category === selectedCategory || 
                               deal.tags?.includes(selectedCategory));
  };
  
  const renderDeals = () => {
    if (loading && deals.length === 0) {
      return <div className="loading-container"><div className="loading-spinner"></div></div>;
    }
    
    const filteredDeals = filterDealsByCategory(deals);
    
    if (filteredDeals.length === 0) {
      return <p className="no-deals">No deals found in this category. Check back later!</p>;
    }
    
    return (
      <div className="deals-grid">
        {filteredDeals.map((deal) => (
          <DealCard 
            key={deal.DealID || deal.id || deal.url} 
            deal={deal} 
            onNotify={() => {}} 
          />
        ))}
      </div>
    );
  };
  
  return (
    <div className="container">
      <header>
        <h1>🔥 Smart Deal Notifier</h1>
        <p>Never miss a great deal again!</p>
      </header>
      
      {notification && (
        <div className={`notification ${notification.type}`}>
          {notification.message}
          <button onClick={() => setNotification(null)} className="close-btn">×</button>
        </div>
      )}
      
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
              <button 
                type="submit" 
                className="subscribe-btn" 
                disabled={loading}
              >
                {loading ? 'Subscribing...' : 'Subscribe'}
              </button>
            </div>
          </form>
        ) : (
          <div className="subscribed">
            <p>You are subscribed with: <strong>{userEmail}</strong></p>
            <button 
              onClick={handleUnsubscribe} 
              className="unsubscribe-btn"
              disabled={loading}
            >
              {loading ? 'Processing...' : 'Unsubscribe'}
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
            <button 
              onClick={fetchDealsWithState} 
              className="refresh-btn"
              disabled={loading}
            >
              {loading ? 'Loading...' : '↻ Refresh'}
            </button>
          </div>
        </div>
        
        {error && <div className="error-container">{error}</div>}
        {renderDeals()}
      </section>
      
      <footer>
        <p>© {new Date().getFullYear()} Smart Deal Notifier - Powered by AWS</p>
      </footer>
    </div>
  );
};

export default App;