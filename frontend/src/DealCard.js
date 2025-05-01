import React from 'react';

function DealCard({ deal, onNotify }) {
  // Handle different property formats from different APIs
  const title = deal.DealName || deal.title || "Unknown Deal";
  const url = deal.DealURL || deal.url || deal.link || "#";
  const votesUp = deal.VoteUp || deal.votes_plus || 0;
  const votesDown = deal.VoteDown || deal.votes_minus || 0;
  const isNotified = deal.UserNotified || false;
  
  const handleNotify = () => {
    if (isNotified) return;
    if (onNotify) onNotify(deal);
  };

  return (
    <div className="border rounded p-4 bg-white flex flex-col justify-between shadow">
      <div>
        <h2 className="font-bold text-lg">{title}</h2>
        <a href={url} className="text-blue-600 underline" target="_blank" rel="noopener noreferrer">View Deal</a>
        <div className="mt-2 flex gap-4">
          <span>👍 {votesUp}</span>
          <span>👎 {votesDown}</span>
        </div>
        <div className="mt-2 text-xs text-gray-500">
          Notified: {isNotified ? "Yes" : "No"}
        </div>
      </div>
      <button 
        disabled={isNotified}
        className={`mt-3 px-3 py-1 rounded ${isNotified ? "bg-gray-300" : "bg-green-600 text-white"}`}
        onClick={handleNotify}
      >
        {isNotified ? "Already Notified" : "Notify Me"}
      </button>
    </div>
  );
}

export default DealCard;