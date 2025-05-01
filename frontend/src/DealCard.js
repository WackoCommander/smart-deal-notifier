import React from 'react';
import './DealCard.css';

const DealCard = ({ deal }) => {
  // Extract deal properties with fallbacks
  const {
    DealID,
    DealName,
    DealURL,
    VoteUp = 0,
    VoteDown = 0,
    UserRelevant = false
  } = deal || {};

  // Calculate vote score
  const voteScore = VoteUp - VoteDown;
  
  // Determine vote color based on score
  const getScoreColor = () => {
    if (voteScore > 20) return '#4caf50'; // Good deal - green
    if (voteScore > 5) return '#8bc34a';  // Decent deal - light green
    if (voteScore >= 0) return '#ffc107'; // Neutral - yellow/amber
    return '#f44336';                     // Bad deal - red
  };

  return (
    <div className="deal-card">
      <div className="deal-card-header">
        <h3 className="deal-title">{DealName || 'Unnamed Deal'}</h3>
        
        <div className="vote-container">
          <div className="vote-score" style={{ color: getScoreColor() }}>
            {voteScore > 0 ? '+' : ''}{voteScore}
          </div>
          <div className="vote-details">
            <span className="upvotes">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 19V5M5 12l7-7 7 7"/>
              </svg>
              {VoteUp}
            </span>
            <span className="downvotes">
              <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                <path d="M12 5v14M5 12l7 7 7-7"/>
              </svg>
              {VoteDown}
            </span>
          </div>
        </div>
      </div>
      
      <div className="deal-card-content">
        {UserRelevant && (
          <div className="relevance-tag">Relevant for you</div>
        )}
      </div>
      
      <div className="deal-card-actions">
        <a 
          href={DealURL} 
          target="_blank" 
          rel="noopener noreferrer" 
          className="view-deal-btn"
        >
          View Deal
          <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <path d="M18 13v6a2 2 0 01-2 2H5a2 2 0 01-2-2V8a2 2 0 012-2h6M15 3h6v6M10 14L21 3"/>
          </svg>
        </a>
      </div>
    </div>
  );
};

export default DealCard;