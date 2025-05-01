import React from 'react';
import { notifyDeal } from './api';

// This component works with both the backend model formats
const DealCard = ({ deal, onNotify }) => {
  // Handle different property formats from different APIs
  const title = deal.DealName || deal.title;
  const url = deal.DealURL || deal.url || deal.link;
  const votesUp = deal.VoteUp || deal.votes_plus || 0;
  const votesDown = deal.VoteDown || deal.votes_minus || 0;
  const isNotified = deal.UserNotified || false;
  const price = deal.price || '';
  const description = deal.description || '';
  const imageUrl = deal.imageUrl || 'https://via.placeholder.com/300x200?text=No+Image';
  const category = deal.category || 'Uncategorized';

  const handleNotify = async () => {
    if (isNotified) return;
    
    try {
      await notifyDeal(deal);
      if (onNotify) onNotify(deal);
    } catch (err) {
      console.error('Error sending notification:', err);
    }
  };

  return (
    <div className="deal-card">
      <div className="deal-image">
        <img src={imageUrl} alt={title} />
      </div>
      <div className="deal-content">
        <h3>{title}</h3>
        {price && <p className="price">${price}</p>}
        <p className="description">{description || title}</p>
        <div className="deal-footer">
          <div className="vote-info">
            <span className="upvotes">👍 {votesUp}</span>
            <span className="downvotes">👎 {votesDown}</span>
          </div>
          <span className="category-tag">{category}</span>
          <div className="action-buttons">
            <a href={url} target="_blank" rel="noopener noreferrer" className="view-deal">
              View Deal
            </a>
            {!isNotified && (
              <button 
                onClick={handleNotify} 
                className="notify-btn"
                disabled={isNotified}
              >
                Notify
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default DealCard;