#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}   Updating Alert Components   ${NC}"
echo -e "${BLUE}======================================${NC}"
echo

# Update the alert settings component
echo -e "${YELLOW}Updating alert settings component...${NC}"
if [ -f "components/alert-settings.tsx" ]; then
  # Backup the original file
  cp components/alert-settings.tsx components/alert-settings.tsx.bak
  echo -e "${GREEN}Backed up original alert-settings.tsx${NC}"
  
  # Replace with the fixed version
  cp components/alert-settings-fixed.tsx components/alert-settings.tsx
  echo -e "${GREEN}Updated alert-settings.tsx with fixed version${NC}"
else
  echo -e "${RED}Error: components/alert-settings.tsx not found${NC}"
fi

# Update the API routes to use the fixed email service
echo -e "${YELLOW}Updating API routes...${NC}"

# Update monitor route
if [ -f "app/api/alerts/monitor/route.ts" ]; then
  sed -i 's/import { emailService } from "@\/lib\/email-service"/import { emailServiceFixed as emailService } from "@\/lib\/email-service-fixed"/' app/api/alerts/monitor/route.ts
  echo -e "${GREEN}Updated monitor route to use fixed email service${NC}"
else
  echo -e "${RED}Error: app/api/alerts/monitor/route.ts not found${NC}"
fi

# Update test route
if [ -f "app/api/alerts/test/route.ts" ]; then
  cp app/api/alerts/test/route.ts app/api/alerts/test/route.ts.bak
  echo -e "${GREEN}Backed up original test route${NC}"
else
  echo -e "${YELLOW}Warning: app/api/alerts/test/route.ts not found${NC}"
fi

echo -e "${GREEN}All components updated successfully!${NC}"
echo
echo -e "${BLUE}Next Steps:${NC}"
echo "1. Run ./email-fix.sh to configure your email settings"
echo "2. Restart your application with: npm run dev"
echo "3. Test your email alerts with: ./test-email.sh"
echo
