import React, { useState, useEffect } from 'react';
import { fetchDeals, notifyDeal } from './api';
import DealCard from './DealCard';

function DealList() {
  const [deals, setDeals] = useState([]);
  const [filters, setFilters] = useState({ min_voteup: '', user_notified: '', relevance_assessed: '' });
  const [loading, setLoading] = useState(false);

  const loadDeals = async () => {
    setLoading(true);
    const params = {};
    if (filters.min_voteup) params.min_voteup = filters.min_voteup;
    if (filters.user_notified !== '') params.user_notified = filters.user_notified === 'true';
    if (filters.relevance_assessed !== '') params.relevance_assessed = filters.relevance_assessed === 'true';
    try {
      setDeals(await fetchDeals(params));
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { loadDeals(); }, []);

  const handleNotify = async (deal) => {
    await notifyDeal(deal);
    await loadDeals(); // Optionally reload
  };

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-5">Deals</h1>
      <div className="mb-4 flex gap-2 flex-wrap">
        <input
          placeholder="Min Upvotes"
          type="number"
          className="border px-2 py-1 rounded"
          value={filters.min_voteup}
          onChange={e => setFilters(f => ({ ...f, min_voteup: e.target.value }))}
        />
        <select
          className="border px-2 py-1 rounded"
          value={filters.user_notified}
          onChange={e => setFilters(f => ({ ...f, user_notified: e.target.value }))}
        >
          <option value="">All Notified</option>
          <option value="false">Not Notified</option>
          <option value="true">Notified</option>
        </select>
        <select
          className="border px-2 py-1 rounded"
          value={filters.relevance_assessed}
          onChange={e => setFilters(f => ({ ...f, relevance_assessed: e.target.value }))}
        >
          <option value="">All Relevant</option>
          <option value="true">Relevant</option>
          <option value="false">Not Relevant</option>
        </select>
        <button className="px-3 py-1 bg-blue-600 text-white rounded" onClick={loadDeals}>Filter</button>
      </div>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {loading ? <div>Loading...</div> : deals.map(deal =>
          <DealCard key={deal.DealID} deal={deal} onNotify={handleNotify} />
        )}
      </div>
    </div>
  );
}

export default DealList;