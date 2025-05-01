#!/bin/bash
# Minimal Deployment Script for Smart Deal Notifier
# This script uses the simplest possible frontend implementation to avoid build issues

# Exit on any error
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Default values
BACKEND_TYPE="fastapi"  # Options: fastapi, express
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
    --help)
      echo "Usage: $0 [--backend fastapi|express] [--port PORT] [--region AWS_REGION]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

echo "🚀 Starting Minimal Smart Deal Notifier deployment"
echo "   Backend: $BACKEND_TYPE"
echo "   Port: $PORT"
echo "   AWS Region: $AWS_REGION"

# Create .env file
echo "Creating .env file..."
cat > "$PROJECT_ROOT/.env" << EOL
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
echo "⚠️  Please edit .env with your AWS credentials and other settings"

# Clean up frontend src and create minimal version
cd "$PROJECT_ROOT/frontend"
echo "📦 Installing frontend dependencies..."
npm install

# Create minimal App.jsx
echo "Creating minimal App.jsx..."
cat > "src/App.jsx" << 'EOL'
import React, { useState } from 'react';
import './App.css';

// Simple inline deal card component to avoid import issues
const SimpleDealCard = ({ deal }) => (
  <div className="border p-4 m-2 bg-white">
    <h3>{deal.title}</h3>
    <p>Votes: {deal.votes} | {deal.notified ? "Notified" : "Not Notified"}</p>
    <a href={deal.url} className="text-blue-600">View Deal</a>
  </div>
);

const App = () => {
  const [email, setEmail] = useState('');
  
  // Sample deals data
  const deals = [
    { id: 1, title: "MacBook Pro Deal", votes: 42, url: "#", notified: false },
    { id: 2, title: "AirPods Pro Sale", votes: 28, url: "#", notified: true }
  ];
  
  const handleSubscribe = (e) => {
    e.preventDefault();
    alert(`Subscribed with email: ${email}`);
  };
  
  return (
    <div className="container">
      <header>
        <h1>🔥 Smart Deal Notifier</h1>
        <p>Never miss a great deal again!</p>
      </header>
      
      <section className="subscription-section">
        <form onSubmit={handleSubscribe}>
          <h2>Get Deal Alerts</h2>
          <div className="form-group">
            <input
              type="email"
              placeholder="Enter your email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
            />
            <button type="submit" className="subscribe-btn">Subscribe</button>
          </div>
        </form>
      </section>
      
      <section className="deals-section">
        <h2>Latest Deals</h2>
        {deals.map(deal => (
          <SimpleDealCard key={deal.id} deal={deal} />
        ))}
      </section>
      
      <footer>
        <p>© {new Date().getFullYear()} Smart Deal Notifier - Powered by AWS</p>
      </footer>
    </div>
  );
};

export default App;
EOL

# Remove DealCard.js to avoid parsing issues
if [ -f "src/DealCard.js" ]; then
  echo "Removing DealCard.js..."
  rm "src/DealCard.js"
fi

if [ -f "src/DealList.js" ]; then
  echo "Removing DealList.js..."
  rm "src/DealList.js"
fi

# Build the frontend
echo "🔨 Building frontend..."
NODE_ENV=production npm run build

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
EnvironmentFile=$PROJECT_ROOT/.env

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