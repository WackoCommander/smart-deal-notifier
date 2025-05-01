import React from 'react';

const DealCard = (props) => {
  const deal = props.deal || {};
  const onNotify = props.onNotify || (() => {});
  
  // Simple props extraction
  const title = deal.DealName || deal.title || "Deal";
  const url = deal.DealURL || deal.url || "#";
  const isNotified = deal.UserNotified || false;
  
  return (
    <div className="border p-4 m-2 bg-white">
      <div>
        <h3>{title}</h3>
        <a href={url}>View Deal</a>
      </div>
      <button 
        onClick={() => onNotify(deal)} 
        disabled={isNotified}
      >
        {isNotified ? "Notified" : "Notify Me"}
      </button>
    </div>
  );
};

export default DealCard;