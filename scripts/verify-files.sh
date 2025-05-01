#!/bin/bash
# Simple script to verify all required files exist in the correct locations

# Base directory 
FRONTEND_DIR="/home/ec2-user/smart-deal-notifier/frontend"
SRC_DIR="$FRONTEND_DIR/src"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if a file exists
check_file() {
  if [ -f "$1" ]; then
    echo -e "${GREEN}✓${NC} $1 exists"
  else
    echo -e "${RED}✗${NC} $1 does not exist!"
  fi
}

echo "Checking required frontend files..."

# Check main files
check_file "$SRC_DIR/App.jsx"
check_file "$SRC_DIR/App.css"
check_file "$SRC_DIR/main.jsx"
check_file "$SRC_DIR/index.css"
check_file "$SRC_DIR/DealsPage.jsx"
check_file "$SRC_DIR/DealsPage.css"
check_file "$SRC_DIR/DealCard.jsx"
check_file "$SRC_DIR/DealCard.css"
check_file "$SRC_DIR/api.js"

# Print the export statements in DealsPage.jsx
echo -e "\nChecking export in DealsPage.jsx:"
grep -n "export" "$SRC_DIR/DealsPage.jsx"

# Print the import statements in App.jsx
echo -e "\nChecking imports in App.jsx:"
grep -n "import" "$SRC_DIR/App.jsx"

echo -e "\nVerification complete!"