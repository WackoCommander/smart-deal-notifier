import axios from 'axios';

const API_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

export const fetchDeals = async (filters = {}) => {
  const params = new URLSearchParams(filters).toString();
  const res = await axios.get(`${API_URL}/deals${params ? '?' + params : ''}`);
  return res.data;
};

export const notifyDeal = async (deal) => {
  await axios.post(`${API_URL}/notify`, deal);
};