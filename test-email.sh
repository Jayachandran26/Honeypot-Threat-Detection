#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}   Cowrie Honeypot Email Alert Tester   ${NC}"
echo -e "${BLUE}======================================${NC}"
echo

# Check if curl is installed
if ! command -v curl &> /dev/null; then
  echo -e "${RED}Error: curl is not installed. Please install curl and try again.${NC}"
  exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
  echo -e "${YELLOW}Warning: jq is not installed. Output will not be formatted.${NC}"
  JQ_INSTALLED=false
else
  JQ_INSTALLED=true
fi

# Function to format JSON if jq is available
format_json() {
  if [ "$JQ_INSTALLED" = true ]; then
    echo "$1" | jq .
  else
    echo "$1"
  fi
}

# Step 1: Check if the application is running
echo -e "${YELLOW}Step 1: Checking if the application is running...${NC}"
if ! curl -s http://localhost:3000 > /dev/null; then
  echo -e "${RED}Error: Application is not running. Please start the application first.${NC}"
  exit 1
else
  echo -e "${GREEN}Application is running!${NC}"
fi

# Step 2: Check email configuration
echo -e "\n${YELLOW}Step 2: Checking email configuration...${NC}"
EMAIL_DEBUG=$(curl -s http://localhost:3000/api/alerts/debug)
echo "Email configuration debug info:"
format_json "$EMAIL_DEBUG"

# Extract configuration status
if [ "$JQ_INSTALLED" = true ]; then
  CONFIGURED=$(echo "$EMAIL_DEBUG" | jq -r '.debug.configured')
  if [ "$CONFIGURED" = "true" ]; then
    echo -e "${GREEN}Email is properly configured!${NC}"
  else
    echo -e "${RED}Email is not properly configured.${NC}"
    echo -e "${YELLOW}Recommendations:${NC}"
    echo "$EMAIL_DEBUG" | jq -r '.recommendations[]' | while read -r line; do
      echo -e "- ${YELLOW}${line}${NC}"
    done
  fi
fi

# Step 3: Test sending an alert
echo -e "\n${YELLOW}Step 3: Testing email alert...${NC}"
TEST_RESULT=$(curl -s -X POST http://localhost:3000/api/alerts/test)
echo "Test result:"
format_json "$TEST_RESULT"

# Step 4: Check alert monitor status
echo -e "\n${YELLOW}Step 4: Checking alert monitor status...${NC}"
MONITOR_STATUS=$(curl -s http://localhost:3000/api/alerts/monitor)
echo "Monitor status:"
format_json "$MONITOR_STATUS"

# Step 5: Generate a test attack
echo -e "\n${YELLOW}Step 5: Would you like to generate a test attack to trigger an alert? (y/n)${NC}"
read -p "Generate test attack? " generate_attack

if [[ "$generate_attack" =~ ^[Yy]$ ]]; then
  echo -e "${YELLOW}Generating test attack...${NC}"
  
  # Create a simple test attack log entry
  COWRIE_LOG_PATH=$(grep COWRIE_LOG_PATH .env.local | cut -d= -f2)
  
  if [ -z "$COWRIE_LOG_PATH" ]; then
    echo -e "${RED}Error: COWRIE_LOG_PATH is not set in .env.local.${NC}"
    echo -e "${YELLOW}Please run ./email-fix.sh to set the correct log path.${NC}"
  else
    # Create test log entry
    TEST_LOG_ENTRY='{
      "eventid": "cowrie.login.success",
      "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")'",
      "src_ip": "192.168.1.100",
      "username": "test_user",
      "password": "test_password",
      "session": "test_session_'$(date +%s)'",
      "message": "Test attack for email alert"
    }'
    
    # Ensure directory exists
    mkdir -p $(dirname "$COWRIE_LOG_PATH")
    
    # Append to log file
    echo "$TEST_LOG_ENTRY" >> "$COWRIE_LOG_PATH"
    
    echo -e "${GREEN}Test attack log entry created:${NC}"
    format_json "$TEST_LOG_ENTRY"
    echo -e "${YELLOW}Check your email for alerts in the next minute...${NC}"
  fi
fi

echo
echo -e "${BLUE}======================================${NC}"
echo -e "${GREEN}Email Alert System Test Complete!${NC}"
echo -e "${BLUE}======================================${NC}"
echo
echo -e "${YELLOW}If you're still having issues:${NC}"
echo "1. Run ./email-fix.sh to reconfigure your email settings"
echo "2. For Gmail users, make sure you're using an App Password"
echo "3. Check your spam folder for test emails"
echo "4. Restart the application after making configuration changes"
echo
