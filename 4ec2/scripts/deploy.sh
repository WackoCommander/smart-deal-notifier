#!/bin/bash
# This script should be run from the project root

# Requirements: nginx, nodejs, npm, python3, pip installed

cd backend
pip3 install -r requirements.txt

cd ../frontend
npm install
npm run build

sudo mkdir -p /var/www/frontend
sudo cp -r build/* /var/www/frontend/

sudo cp ../nginx/default.conf /etc/nginx/sites-available/default
sudo nginx -s reload

# Start backend (detached for demo; recommend use systemd in real prod)
cd ../backend
nohup uvicorn main:app --host 0.0.0.0 --port 8000 &