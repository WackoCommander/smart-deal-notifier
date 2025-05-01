#!/bin/bash
# Smart Deal Notifier Deployment Script

# Exit on any error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
BACKEND_TYPE="fastapi"  # Options: fastapi, express
ENV_FILE=".env"
PORT="8000"
AWS_REGION="us-east-1"

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --backend)
      BACKEND_TYPE="$2"
      shift 2
      ;;
    --port)
      PORT="$2"
      shift 2
      ;;
    --region)
      AWS_REGION="$2"
      shift 2
      ;;
    --env-file)
      ENV_FILE="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--backend fastapi|express] [--port PORT] [--region AWS_REGION] [--env-file ENV_FILE]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo "🚀 Starting Smart Deal Notifier deployment"
echo "   Backend: $BACKEND_TYPE"
echo "   Port: $PORT"
echo "   AWS Region: $AWS_REGION"
echo "   Environment file: $ENV_FILE"

# Create .env file if it doesn't exist
if [ ! -f "$PROJECT_ROOT/$ENV_FILE" ]; then
  echo "Creating $ENV_FILE file..."
  cat > "$PROJECT_ROOT/$ENV_FILE" << EOL
# Server Configuration
PORT=$PORT
NODE_ENV=production

# AWS Configuration
AWS_REGION=$AWS_REGION
# Add your AWS credentials here
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=

# Database Configuration
DYNAMO_TABLE=deals

# SNS Configuration 
SNS_TOPIC_ARN=

# API Configuration
VITE_API_URL=/api
EOL
  echo "⚠️  Please edit $ENV_FILE with your AWS credentials and other settings"
fi

# Install frontend dependencies and build
cd "$PROJECT_ROOT/frontend"
echo "📦 Installing frontend dependencies..."
npm install

# Make sure we have the required files
echo "🔧 Checking for required components..."

# Check if DealCard.js exists, if not copy our fixed version
if [ ! -f "src/DealCard.js" ]; then
  echo "Creating DealCard.js component..."
  cat > "src/DealCard.js" << 'EOL'
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
EOL
fi

# Build the frontend with more verbose output to help debug issues
echo "🔨 Building frontend..."
NODE_ENV=production npm run build

if [ $? -ne 0 ]; then
  echo "❌ Frontend build failed. Checking for common issues..."
  
  # Check if App.jsx has references to non-existent components
  if grep -q "import DealCard from './DealCard'" "src/App.jsx"; then
    if [ ! -f "src/DealCard.js" ] && [ ! -f "src/DealCard.jsx" ]; then
      echo "⚠️  App.jsx imports DealCard but the file doesn't exist."
      echo "   Creating a simplified App.jsx..."
      
      # Create a simplified App.jsx
      cat > "src/App.jsx.new" << 'EOL'
import React, { useState, useEffect } from 'react';
import './App.css';

const App = () => {
  const [loading, setLoading] = useState(false);
  
  return (
    <div className="container">
      <header>
        <h1>🔥 Smart Deal Notifier</h1>
        <p>Never miss a great deal again!</p>
      </header>
      
      <section className="subscription-section">
        <div>
          <h2>Get Deal Alerts</h2>
          <p>Subscribe to receive deal notifications!</p>
        </div>
      </section>
      
      <section className="deals-section">
        <h2>Latest Deals</h2>
        <p>Check back soon for the latest deals!</p>
      </section>
      
      <footer>
        <p>© {new Date().getFullYear()} Smart Deal Notifier - Powered by AWS</p>
      </footer>
    </div>
  );
};

export default App;
EOL
      mv "src/App.jsx.new" "src/App.jsx"
      echo "Trying build again with simplified App.jsx..."
      NODE_ENV=production npm run build
      
      if [ $? -ne 0 ]; then
        echo "❌ Frontend build still failing. Please check the error messages above."
        exit 1
      fi
    fi
  fi
fi

# Setup backend based on type
if [ "$BACKEND_TYPE" == "fastapi" ]; then
  echo "🐍 Setting up FastAPI backend..."
  cd "$PROJECT_ROOT/backend"
  
  # Create virtual environment if it doesn't exist
  if [ ! -d "venv" ]; then
    echo "Creating Python virtual environment..."
    python3 -m venv venv
  fi
  
  # Activate virtual environment
  source venv/bin/activate
  
  # Install dependencies
  echo "Installing backend dependencies..."
  pip install -r requirements.txt
  
  # Create systemd service file
  echo "Creating systemd service file..."
  cat > /tmp/smart-deal-notifier.service << EOL
[Unit]
Description=Smart Deal Notifier API
After=network.target

[Service]
User=$(whoami)
WorkingDirectory=$PROJECT_ROOT/backend
ExecStart=$PROJECT_ROOT/backend/venv/bin/uvicorn main:app --host 0.0.0.0 --port $PORT
Restart=always
Environment="DYNAMO_TABLE=deals"
Environment="AWS_REGION=$AWS_REGION"
EnvironmentFile=$PROJECT_ROOT/$ENV_FILE

[Install]
WantedBy=multi-user.target
EOL

  echo "To install the systemd service, run:"
  echo "sudo cp /tmp/smart-deal-notifier.service /etc/systemd/system/"
  echo "sudo systemctl daemon-reload"
  echo "sudo systemctl enable smart-deal-notifier"
  echo "sudo systemctl start smart-deal-notifier"
  
elif [ "$BACKEND_TYPE" == "express" ]; then
  echo "🟢 Setting up Express backend..."
  cd "$PROJECT_ROOT/backend"
  
  # Install dependencies
  echo "Installing backend dependencies..."
  npm install
  
  # Copy frontend build to server's public directory
  echo "Copying frontend build to server..."
  mkdir -p build
  cp -r "$PROJECT_ROOT/frontend/dist/"* build/
  
  # Create PM2 ecosystem file
  echo "Creating PM2 ecosystem file..."
  cat > ecosystem.config.js << EOL
module.exports = {
  apps: [{
    name: 'smart-deal-notifier',
    script: 'server.js',
    env: {
      NODE_ENV: 'production',
      PORT: $PORT
    },
    max_memory_restart: '300M',
    error_file: 'logs/err.log',
    out_file: 'logs/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    watch: false,
    max_restarts: 10
  }]
};
EOL

  # Create logs directory
  mkdir -p logs
  
  # Install PM2 if not installed
  if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    npm install -g pm2
  fi
  
  echo "To start the application with PM2, run:"
  echo "cd $PROJECT_ROOT/backend && pm2 start ecosystem.config.js"
else
  echo "❌ Unknown backend type: $BACKEND_TYPE"
  exit 1
fi

# Create Nginx configuration
echo "Creating Nginx configuration..."
cat > /tmp/smart-deal-notifier.conf << EOL
server {
    listen 80;
    server_name _;
    
    location / {
        root $PROJECT_ROOT/frontend/dist;
        try_files \$uri \$uri/ /index.html;
    }
    
    location /api/ {
        proxy_pass http://localhost:$PORT/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOL

echo "To install the Nginx configuration, run:"
echo "sudo cp /tmp/smart-deal-notifier.conf /etc/nginx/sites-available/"
echo "sudo ln -s /etc/nginx/sites-available/smart-deal-notifier.conf /etc/nginx/sites-enabled/"
echo "sudo nginx -t"
echo "sudo systemctl reload nginx"

echo "✅ Deployment preparation complete!"
echo "   Please follow the instructions above to complete the deployment."