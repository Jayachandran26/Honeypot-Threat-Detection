#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}   Cowrie Honeypot Email Alert Fixer   ${NC}"
echo -e "${BLUE}======================================${NC}"
echo

# Check if .env.local exists
if [ ! -f .env.local ]; then
  echo -e "${YELLOW}Creating .env.local file...${NC}"
  touch .env.local
else
  echo -e "${GREEN}Found .env.local file${NC}"
fi

# Function to update or add environment variable
update_env_var() {
  local var_name=$1
  local var_value=$2
  local env_file=".env.local"
  
  # Check if variable exists
  if grep -q "^${var_name}=" "$env_file"; then
    # Update existing variable
    sed -i "s|^${var_name}=.*|${var_name}=${var_value}|" "$env_file"
  else
    # Add new variable
    echo "${var_name}=${var_value}" >> "$env_file"
  fi
}

echo -e "${YELLOW}Let's configure your email settings:${NC}"
echo

# SMTP Host
read -p "Enter SMTP Host (e.g., smtp.gmail.com): " smtp_host
if [ -z "$smtp_host" ]; then
  smtp_host="smtp.gmail.com"
  echo -e "${YELLOW}Using default: ${smtp_host}${NC}"
fi
update_env_var "SMTP_HOST" "$smtp_host"

# SMTP Port
read -p "Enter SMTP Port (default: 587): " smtp_port
if [ -z "$smtp_port" ]; then
  smtp_port="587"
  echo -e "${YELLOW}Using default: ${smtp_port}${NC}"
fi
update_env_var "SMTP_PORT" "$smtp_port"

# SMTP Secure
read -p "Use secure connection? (true/false, default: false): " smtp_secure
if [ -z "$smtp_secure" ]; then
  smtp_secure="false"
  echo -e "${YELLOW}Using default: ${smtp_secure}${NC}"
fi
update_env_var "SMTP_SECURE" "$smtp_secure"

# SMTP User
read -p "Enter SMTP Username (your email address): " smtp_user
if [ -z "$smtp_user" ]; then
  echo -e "${RED}SMTP Username is required!${NC}"
  exit 1
fi
update_env_var "SMTP_USER" "$smtp_user"

# SMTP Password
read -p "Enter SMTP Password (for Gmail, use App Password): " smtp_password
if [ -z "$smtp_password" ]; then
  echo -e "${RED}SMTP Password is required!${NC}"
  exit 1
fi
update_env_var "SMTP_PASSWORD" "$smtp_password"

# Admin Email
read -p "Enter Admin Email (where alerts will be sent): " admin_email
if [ -z "$admin_email" ]; then
  admin_email=$smtp_user
  echo -e "${YELLOW}Using SMTP user as admin email: ${admin_email}${NC}"
fi
update_env_var "ADMIN_EMAIL" "$admin_email"

# Cowrie Log Path
read -p "Enter Cowrie Log Path (leave empty to keep current): " cowrie_log_path
if [ ! -z "$cowrie_log_path" ]; then
  update_env_var "COWRIE_LOG_PATH" "$cowrie_log_path"
  echo -e "${GREEN}Updated Cowrie log path${NC}"
fi

echo
echo -e "${GREEN}Email configuration updated successfully!${NC}"
echo

# Gmail App Password Instructions
if [[ "$smtp_host" == *"gmail"* ]]; then
  echo -e "${YELLOW}Gmail Setup Instructions:${NC}"
  echo "1. Make sure 2-Step Verification is enabled in your Google Account"
  echo "2. Generate an App Password: Google Account → Security → App passwords"
  echo "3. Use the App Password (not your regular password) in the SMTP Password field"
  echo
fi

# Create a simple script to update the components
cat > update-components.sh << 'EOF'
#!/bin/bash

# Update the components to use the fixed email service
sed -i 's/import { emailService } from "@\/lib\/email-service"/import { emailServiceFixed as emailService } from "@\/lib\/email-service-fixed"/' app/api/alerts/monitor/route.ts
sed -i 's/import { emailService } from "@\/lib\/email-service"/import { emailServiceFixed as emailService } from "@\/lib\/email-service-fixed"/' components/alert-settings.tsx

echo "Components updated to use the fixed email service!"
EOF

chmod +x update-components.sh
./update-components.sh

echo -e "${BLUE}Next Steps:${NC}"
echo "1. Restart your application to apply the new settings:"
echo "   npm run dev"
echo "2. Go to the alerts dashboard and click 'Send Test Alert' to verify settings"
echo

echo -e "${GREEN}Done!${NC}"
