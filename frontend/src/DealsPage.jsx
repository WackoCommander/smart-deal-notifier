import React, { useState, useEffect } from 'react';
import { fetchDeals } from './api';
import DealCard from './DealCard';
import './DealsPage.css';

const DealsPage = () => {
  const [deals, setDeals] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [filters, setFilters] = useState({
    min_voteup: '',
    relevance_assessed: ''
  });

  // Function to load deals from API
  const loadDeals = async () => {
    setLoading(true);
    setError(null);
    
    try {
      // Build filter params
      const filterParams = {};
      if (filters.min_voteup) filterParams.min_voteup = parseInt(filters.min_voteup);
      if (filters.relevance_assessed !== '') {
        filterParams.relevance_assessed = filters.relevance_assessed === 'true';
      }
      
      // Fetch deals from API
      const data = await fetchDeals(filterParams);
      setDeals(data);
    } catch (err) {
      console.error('Failed to fetch deals:', err);
      setError(err.message || 'Failed to load deals');
    } finally {
      setLoading(false);
    }
  };

  // Load deals on initial render
  useEffect(() => {
    loadDeals();
  }, []);

  // Handle filter changes
  const handleFilterChange = (e) => {
    const { name, value } = e.target;
    setFilters(prev => ({ ...prev, [name]: value }));
  };

  // Apply filters
  const applyFilters = (e) => {
    e.preventDefault();
    loadDeals();
  };

  return (
    <div className="deals-page">
      <header className="deals-header">
        <h1>🔥 Smart Deal Notifier</h1>
        <p>Never miss a great deal again!</p>
      </header>

      <section className="deals-filters">
        <form onSubmit={applyFilters}>
          <div className="filters-container">
            <div className="filter-group">
              <label htmlFor="min_voteup">Min Upvotes</label>
              <input
                type="number"
                id="min_voteup"
                name="min_voteup"
                value={filters.min_voteup}
                onChange={handleFilterChange}
                placeholder="0"
                min="0"
              />
            </div>
            
            <div className="filter-group">
              <label htmlFor="relevance_assessed">Relevance</label>
              <select
                id="relevance_assessed"
                name="relevance_assessed"
                value={filters.relevance_assessed}
                onChange={handleFilterChange}
              >
                <option value="">All Deals</option>
                <option value="true">Relevant Only</option>
                <option value="false">Not Relevant</option>
              </select>
            </div>
            
            <button type="submit" className="filter-button">
              Apply Filters
            </button>
          </div>
        </form>
      </section>

      <section className="deals-content">
        {loading ? (
          <div className="loading-container">
            <div className="loading-spinner"></div>
            <p>Loading deals...</p>
          </div>
        ) : error ? (
          <div className="error-container">
            <p>Error: {error}</p>
            <button onClick={loadDeals} className="retry-button">
              Try Again
            </button>
          </div>
        ) : deals.length === 0 ? (
          <div className="no-deals">
            <p>No deals found. Try adjusting your filters.</p>
          </div>
        ) : (
          <div className="deals-grid">
            {deals.map(deal => (
              <DealCard key={deal.DealID} deal={deal} />
            ))}
          </div>
        )}
      </section>
    </div>
  );
};

export default DealsPage;