#!/bin/bash
# Simplified Deployment Script for Smart Deal Notifier

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

echo "🚀 Starting Smart Deal Notifier deployment"
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

# Install and build frontend
cd "$PROJECT_ROOT/frontend"
echo "📦 Installing frontend dependencies..."
npm install

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
echo "sudo cp /tmp/smart-deal-notifier.conf /etc/nginx/conf.d/"
echo "sudo nginx -t"
echo "sudo systemctl reload nginx"

echo "✅ Deployment preparation complete!"
echo "   Please follow the instructions above to complete the deployment."