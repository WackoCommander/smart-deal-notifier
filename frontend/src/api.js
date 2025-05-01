import axios from 'axios';

// Create axios instance with base configuration
const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL || '/api',
  headers: {
    'Content-Type': 'application/json',
  },
  timeout: 10000,
});

// Handle API errors consistently
const handleApiError = (error) => {
  console.error('API Error:', error);
  if (error.response) {
    // The request was made and the server responded with an error status
    return Promise.reject({
      status: error.response.status,
      message: error.response.data.message || 'An error occurred with the server response',
      data: error.response.data
    });
  } else if (error.request) {
    // The request was made but no response was received
    return Promise.reject({
      status: 0,
      message: 'No response received from server. Please check your connection.'
    });
  } else {
    // Something happened in setting up the request
    return Promise.reject({
      status: 0,
      message: error.message || 'Error setting up the request'
    });
  }
};

// API methods
export const fetchDeals = async (filters = {}) => {
  try {
    const params = new URLSearchParams();
    // Add filters to params
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null && value !== '') {
        params.append(key, value);
      }
    });
    
    const query = params.toString();
    const url = `/deals${query ? '?' + query : ''}`;
    const response = await api.get(url);
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const notifyDeal = async (deal) => {
  try {
    const response = await api.post('/notify', deal);
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const subscribeToDeals = async (email, categories = []) => {
  try {
    const response = await api.post('/subscribe', { email, categories });
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export const unsubscribeFromDeals = async (email) => {
  try {
    const response = await api.post('/unsubscribe', { email });
    return response.data;
  } catch (error) {
    throw handleApiError(error);
  }
};

export default api;