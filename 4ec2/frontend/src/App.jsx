import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

const App = () => {
  const [deals, setDeals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [userEmail, setUserEmail] = useState('');
  const [subscribed, setSubscribed] = useState(false);
  const [categories, setCategories] = useState([]);
  const [selectedCategory, setSelectedCategory] = useState('all');
  
  useEffect(() => {
    // Load user subscription status from local storage
    const savedEmail = localStorage.getItem('userEmail');
    if (savedEmail) {
      setUserEmail(savedEmail);
      setSubscribed(true);
    }
    
    // Fetch deals from API
    fetchDeals();
    
    // Extract unique categories from deals
    fetchCategories();
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
  
  const fetchCategories = async () => {
    try {
      const response = await axios.get('/api/categories');
      setCategories(response.data);
    } catch (err) {
      console.error('Error fetching categories:', err);
      // Use dummy categories as fallback
      setCategories(['Electronics', 'Clothing', 'Home', 'Toys']);
    }
  };
  
  const handleSubscribe = async (e) => {
    e.preventDefault();
    if (!userEmail) return;
    
    try {
      // Connect to your AWS SNS subscription endpoint
      await axios.post('/api/subscribe', { 
        email: userEmail,
        categories: selectedCategory === 'all' ? categories : [selectedCategory]
      });
      
      localStorage.setItem('userEmail', userEmail);
      setSubscribed(true);
      alert('Successfully subscribed to deal notifications! Please check your email to confirm subscription.');
    } catch (err) {
      console.error('Error subscribing:', err);
      alert('Failed to subscribe. Please try again.');
    }
  };
  
  const handleUnsubscribe = async () => {
    try {
      // Connect to your AWS SNS unsubscribe endpoint
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
  
  const filterDealsByCategory = (deals) => {
    if (selectedCategory === 'all') return deals;
    return deals.filter(deal => deal.category === selectedCategory);
  };
  
  const renderDeals = () => {
    const filteredDeals = filterDealsByCategory(deals);
    
    if (filteredDeals.length === 0) {
      return <p className="no-deals">No deals found in this category. Check back later!</p>;
    }
    
    return (
      <div className="deals-grid">
        {filteredDeals.map((deal) => (
          <div key={deal.id || deal.url} className="deal-card">
            {deal.imageUrl && <div className="deal-image">
              <img src={deal.imageUrl} alt={deal.title} />
            </div>}
            <div className="deal-content">
              <h3>{deal.title}</h3>
              <p className="price">${deal.price}</p>
              <p className="description">{deal.description}</p>
              <div className="deal-footer">
                <span className="category-tag">{deal.category || 'Uncategorized'}</span>
                <a href={deal.url} target="_blank" rel="noopener noreferrer" className="view-deal">
                  View Deal
                </a>
              </div>
            </div>
          </div>
        ))}
      </div>
    );
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
        
        {renderDeals()}
      </section>
      
      <footer>
        <p>© {new Date().getFullYear()} Smart Deal Notifier - Powered by AWS</p>
      </footer>
    </div>
  );
};

export default App;