#!/bin/bash
# Script to fix the build error related to DealsPage.jsx export

# Set the frontend directory
FRONTEND_DIR="/home/ec2-user/smart-deal-notifier/frontend"
SRC_DIR="$FRONTEND_DIR/src"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Smart Deal Notifier Build Error Fix ===${NC}"

# Check if the src directory exists
if [ ! -d "$SRC_DIR" ]; then
  echo -e "${RED}Error: Source directory $SRC_DIR does not exist!${NC}"
  exit 1
fi

# Function to backup a file before modifying it
backup_file() {
  if [ -f "$1" ]; then
    cp "$1" "$1.bak"
    echo -e "${GREEN}Created backup:${NC} $1.bak"
  else
    echo -e "${RED}Error: File $1 does not exist!${NC}"
    return 1
  fi
}

# Step 1: Fix DealsPage.jsx
echo -e "\n${BLUE}Fixing DealsPage.jsx...${NC}"
DEALS_PAGE="$SRC_DIR/DealsPage.jsx"

if [ -f "$DEALS_PAGE" ]; then
  backup_file "$DEALS_PAGE"
  
  # Check if the file already has a default export
  if grep -q "export default DealsPage" "$DEALS_PAGE"; then
    echo "DealsPage.jsx already has a default export."
  else
    # Add default export if it doesn't exist
    echo -e "\n// Make sure to include this default export\nexport default DealsPage;" >> "$DEALS_PAGE"
    echo -e "${GREEN}Added default export to DealsPage.jsx${NC}"
  fi
else
  echo -e "${RED}Error: DealsPage.jsx does not exist at $DEALS_PAGE${NC}"
  echo "Please ensure DealsPage.jsx is correctly placed in the src directory."
  exit 1
fi

# Step 2: Verify App.jsx imports
echo -e "\n${BLUE}Verifying App.jsx imports...${NC}"
APP_JSX="$SRC_DIR/App.jsx"

if [ -f "$APP_JSX" ]; then
  backup_file "$APP_JSX"
  
  # Check if App.jsx correctly imports DealsPage
  if grep -q "import DealsPage from './DealsPage'" "$APP_JSX"; then
    echo -e "${GREEN}App.jsx correctly imports DealsPage.${NC}"
  else
    # Try to fix the import
    sed -i 's/import DealsPage.*/import DealsPage from '\''\.\/DealsPage'\'';/g' "$APP_JSX"
    echo -e "${GREEN}Updated import statement in App.jsx${NC}"
  fi
else
  echo -e "${RED}Error: App.jsx does not exist at $APP_JSX${NC}"
  echo "Please ensure App.jsx is correctly placed in the src directory."
  exit 1
fi

# Step 3: Verify folder structure for imports
echo -e "\n${BLUE}Verifying file structure...${NC}"
if [ -f "$SRC_DIR/DealCard.jsx" ]; then
  echo -e "${GREEN}DealCard.jsx found in correct location.${NC}"
else
  echo -e "${RED}Warning: DealCard.jsx not found in $SRC_DIR${NC}"
  echo "This might cause additional import errors."
fi

if [ -f "$SRC_DIR/api.js" ]; then
  echo -e "${GREEN}api.js found in correct location.${NC}"
else
  echo -e "${RED}Warning: api.js not found in $SRC_DIR${NC}"
  echo "This might cause additional import errors."
fi

# Final instructions
echo -e "\n${GREEN}Fixes applied successfully!${NC}"
echo -e "Next steps:"
echo "1. Run 'npm run build' to verify the error is fixed."
echo "2. If you encounter additional errors, they may be related to other missing files or imports."
echo "3. In case of issues, you can restore the backup files with '.bak' extension."