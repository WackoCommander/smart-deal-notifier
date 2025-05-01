#!/bin/bash
# Smart Deal Notifier Deployment Script
# This script deploys both frontend and backend components

# Exit on any error
set -e

# Display colorful logs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
FRONTEND_DIR="$PROJECT_ROOT/frontend"
BACKEND_DIR="$PROJECT_ROOT/backend"
LOGS_DIR="$PROJECT_ROOT/logs"

# Default configuration
BACKEND_TYPE="fastapi"  # Options: fastapi, express
PORT="8000"
AWS_REGION="us-east-1"
DYNAMO_TABLE="deals"
DEPLOY_ENV="production"
INSTALL_DEPS=true
BUILD_FRONTEND=true
DEPLOY_BACKEND=true
SETUP_NGINX=false
SYSTEMD_USER="$(whoami)"

# Print header
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}        Smart Deal Notifier Deployment         ${NC}"
echo -e "${BLUE}===============================================${NC}"

# Function to print section header
section() {
    echo -e "\n${GREEN}>>> $1${NC}"
}

# Function to print info
info() {
    echo -e "${BLUE}INFO:${NC} $1"
}

# Function to print warning
warning() {
    echo -e "${YELLOW}WARNING:${NC} $1"
}

# Function to print error
error() {
    echo -e "${RED}ERROR:${NC} $1"
}

# Function to print success
success() {
    echo -e "${GREEN}SUCCESS:${NC} $1"
}

# Function to show help
show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --backend TYPE       Backend type: fastapi or express (default: fastapi)"
    echo "  --port PORT          Port for the backend service (default: 8000)"
    echo "  --region REGION      AWS region (default: us-east-1)"
    echo "  --table TABLE        DynamoDB table name (default: deals)"
    echo "  --env ENV            Deployment environment: development or production (default: production)"
    echo "  --user USER          User for systemd service (default: current user)"
    echo "  --skip-deps          Skip dependency installation"
    echo "  --skip-frontend      Skip frontend build"
    echo "  --skip-backend       Skip backend deployment"
    echo "  --setup-nginx        Configure NGINX"
    echo "  --help               Show this help message"
    echo ""
    exit 0
}

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
    --table)
      DYNAMO_TABLE="$2"
      shift 2
      ;;
    --env)
      DEPLOY_ENV="$2"
      shift 2
      ;;
    --user)
      SYSTEMD_USER="$2"
      shift 2
      ;;
    --skip-deps)
      INSTALL_DEPS=false
      shift
      ;;
    --skip-frontend)
      BUILD_FRONTEND=false
      shift
      ;;
    --skip-backend)
      DEPLOY_BACKEND=false
      shift
      ;;
    --setup-nginx)
      SETUP_NGINX=true
      shift
      ;;
    --help)
      show_help
      ;;
    *)
      error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate backend type
if [[ "$BACKEND_TYPE" != "fastapi" && "$BACKEND_TYPE" != "express" ]]; then
    error "Invalid backend type: $BACKEND_TYPE (must be 'fastapi' or 'express')"
    exit 1
fi

# Print configuration
section "Configuration"
echo "Backend type:    $BACKEND_TYPE"
echo "Backend port:    $PORT"
echo "AWS region:      $AWS_REGION"
echo "DynamoDB table:  $DYNAMO_TABLE"
echo "Environment:     $DEPLOY_ENV"
echo "Systemd user:    $SYSTEMD_USER"

# Create logs directory
mkdir -p "$LOGS_DIR"

# Create .env file
section "Creating environment configuration"
ENV_FILE="$PROJECT_ROOT/.env"
info "Writing environment file to $ENV_FILE"

cat > "$ENV_FILE" << EOL
# Server Configuration
PORT=$PORT
NODE_ENV=$DEPLOY_ENV

# AWS Configuration
AWS_REGION=$AWS_REGION
DYNAMO_TABLE=$DYNAMO_TABLE

# API Configuration - used by frontend
VITE_API_URL=/api
EOL

success "Environment file created"
warning "Please ensure your EC2 instance has the correct IAM role for DynamoDB access"

# Deploy Frontend
if [ "$BUILD_FRONTEND" = true ]; then
    section "Deploying Frontend"
    cd "$FRONTEND_DIR"
    
    # Install dependencies
    if [ "$INSTALL_DEPS" = true ]; then
        info "Installing frontend dependencies..."
        npm install
    else
        info "Skipping frontend dependency installation..."
    fi
    
    # Build frontend
    info "Building frontend for $DEPLOY_ENV environment..."
    if [ "$DEPLOY_ENV" = "production" ]; then
        NODE_ENV=production npm run build
    else
        npm run build
    fi
    
    success "Frontend built successfully"
fi

# Deploy Backend
if [ "$DEPLOY_BACKEND" = true ]; then
    section "Deploying Backend"
    cd "$BACKEND_DIR"
    
    if [ "$BACKEND_TYPE" = "fastapi" ]; then
        info "Setting up FastAPI backend..."
        
        # Create virtual environment
        if [ ! -d "venv" ]; then
            info "Creating Python virtual environment..."
            python3 -m venv venv
        fi
        
        # Activate virtual environment and install dependencies
        if [ "$INSTALL_DEPS" = true ]; then
            info "Installing backend dependencies..."
            source venv/bin/activate
            pip install fastapi uvicorn boto3 pydantic
            deactivate
        else
            info "Skipping backend dependency installation..."
        fi
        
        # Create systemd service file
        info "Creating systemd service file..."
        SERVICE_FILE="/tmp/smart-deal-notifier.service"
        
        cat > "$SERVICE_FILE" << EOL
[Unit]
Description=Smart Deal Notifier API
After=network.target

[Service]
User=$SYSTEMD_USER
WorkingDirectory=$BACKEND_DIR
ExecStart=$BACKEND_DIR/venv/bin/uvicorn main:app --host 0.0.0.0 --port $PORT
Restart=always
Environment="DYNAMO_TABLE=$DYNAMO_TABLE"
Environment="AWS_REGION=$AWS_REGION"
StandardOutput=append:$LOGS_DIR/backend.log
StandardError=append:$LOGS_DIR/backend_error.log

[Install]
WantedBy=multi-user.target
EOL
        
        success "FastAPI backend setup complete"
        info "To install and start the systemd service, run:"
        echo "sudo cp $SERVICE_FILE /etc/systemd/system/"
        echo "sudo systemctl daemon-reload"
        echo "sudo systemctl enable smart-deal-notifier"
        echo "sudo systemctl start smart-deal-notifier"
        
    elif [ "$BACKEND_TYPE" = "express" ]; then
        info "Setting up Express backend..."
        
        # Install dependencies
        if [ "$INSTALL_DEPS" = true ]; then
            info "Installing backend dependencies..."
            npm install
        else
            info "Skipping backend dependency installation..."
        fi
        
        # Create PM2 ecosystem file
        info "Creating PM2 ecosystem file..."
        cat > ecosystem.config.js << EOL
module.exports = {
  apps: [{
    name: 'smart-deal-notifier',
    script: 'server.js',
    env: {
      NODE_ENV: '$DEPLOY_ENV',
      PORT: $PORT,
      AWS_REGION: '$AWS_REGION',
      DYNAMO_TABLE: '$DYNAMO_TABLE'
    },
    max_memory_restart: '300M',
    error_file: '$LOGS_DIR/err.log',
    out_file: '$LOGS_DIR/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss',
    watch: false,
    max_restarts: 10
  }]
};
EOL
        
        success "Express backend setup complete"
        info "To start the application with PM2, run:"
        echo "cd $BACKEND_DIR && pm2 start ecosystem.config.js"
    fi
fi

# Setup NGINX
if [ "$SETUP_NGINX" = true ]; then
    section "Setting up NGINX"
    
    info "Creating NGINX configuration file..."
    NGINX_CONF="/tmp/smart-deal-notifier.conf"
    
    cat > $NGINX_CONF << EOL
server {
    listen 80;
    server_name _;
    
    # Frontend
    location / {
        root $FRONTEND_DIR/dist;
        try_files \$uri \$uri/ /index.html;
        
        # Caching static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 30d;
            add_header Cache-Control "public, no-transform";
        }
    }
    
    # Backend API
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
    
    # Logging
    access_log $LOGS_DIR/nginx_access.log;
    error_log $LOGS_DIR/nginx_error.log;
}
EOL
    
    success "NGINX configuration created"
    info "To install the NGINX configuration, run:"
    echo "sudo cp $NGINX_CONF /etc/nginx/conf.d/"
    echo "sudo nginx -t"
    echo "sudo systemctl reload nginx"
fi

# Final instructions
section "Deployment Summary"
echo "Smart Deal Notifier deployment prepared successfully!"
echo ""

if [ "$DEPLOY_BACKEND" = true ]; then
    if [ "$BACKEND_TYPE" = "fastapi" ]; then
        echo "To start the backend manually (for testing):"
        echo "cd $BACKEND_DIR"
        echo "source venv/bin/activate"
        echo "uvicorn main:app --host 0.0.0.0 --port $PORT"
        echo ""
        echo "Or start as a service with:"
        echo "sudo systemctl start smart-deal-notifier"
    else
        echo "To start the backend with PM2:"
        echo "cd $BACKEND_DIR"
        echo "pm2 start ecosystem.config.js"
    fi
    echo ""
fi

if [ "$BUILD_FRONTEND" = true ]; then
    echo "Frontend built at: $FRONTEND_DIR/dist"
    echo ""
fi

if [ "$SETUP_NGINX" = true ]; then
    echo "After setting up NGINX, your application will be available at:"
    echo "http://your-server-ip/"
    echo ""
fi

echo "Logs will be available in: $LOGS_DIR"
echo ""

success "Deployment preparation complete!"