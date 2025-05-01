import React from 'react';

function DealCard({ deal, onNotify }) {
  return (
    <div className="border rounded p-4 bg-white flex flex-col justify-between shadow">
      <div>
        <h2 className="font-bold text-lg">{deal.DealName}</h2>
        <a href={deal.DealURL} className="text-blue-600 underline" target="_blank" rel="noopener noreferrer">View Deal</a>
        <div className="mt-2 flex gap-4">
          <span>👍 {deal.VoteUp}</span>
          <span>👎 {deal.VoteDown}</span>
        </div>
        <div className="mt-2 text-xs text-gray-500">
          Notified: {deal.UserNotified ? "Yes" : "No"} | Relevant: {deal.UserRelevant ? "Yes" : "No"}
        </div>
      </div>
      <button disabled={deal.UserNotified}
        className={`mt-3 px-3 py-1 rounded ${deal.UserNotified ? "bg-gray-300" : "bg-green-600 text-white"}`}
        onClick={() => onNotify(deal)}>
        {deal.UserNotified ? "Already Notified" : "Notify Me"}
      </button>
    </div>
  );
}

export default DealCard;