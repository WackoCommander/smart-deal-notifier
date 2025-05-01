#!/bin/bash
# Deployment script for Smart Deal Notifier

# Exit on any error
set -e

echo "Starting deployment process..."

# Install dependencies
echo "Installing server dependencies..."
npm install

# Install frontend dependencies and build
echo "Installing and building frontend..."
cd frontend  # Adjust if your frontend is in a different directory
npm install
npm run build
cd ..

# Copy the built frontend to server's public directory
echo "Copying frontend build to server..."
cp -r frontend/build/* build/

# Setup environment variables
echo "Setting up environment variables..."
if [ ! -f .env ]; then
    echo "Creating .env file..."
    cat > .env << EOL
PORT=3000
AWS_REGION=us-east-1
# Add your AWS credentials and table names here
# AWS_ACCESS_KEY_ID=
# AWS_SECRET_ACCESS_KEY=
# DEALS_TABLE_NAME=
# SUBSCRIBERS_TABLE_NAME=
# SNS_TOPIC_ARN=
EOL
    echo "Please edit the .env file with your AWS credentials"
fi

# Setup PM2 for process management
echo "Setting up PM2 process manager..."
if ! command -v pm2 &> /dev/null; then
    echo "Installing PM2..."
    npm install -g pm2
fi

# Start or restart the application
echo "Starting application with PM2..."
pm2 restart ecosystem.config.js || pm2 start ecosystem.config.js

echo "Deployment complete!"