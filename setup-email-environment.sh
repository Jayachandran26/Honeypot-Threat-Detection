#!/bin/bash

echo "🔧 SETTING UP EMAIL ENVIRONMENT VARIABLES"
echo "========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if .env.local exists
if [ ! -f .env.local ]; then
    echo -e "${YELLOW}Creating .env.local file...${NC}"
    touch .env.local
fi

echo -e "${BLUE}Current .env.local contents:${NC}"
cat .env.local
echo

# Function to update or add environment variable
update_env_var() {
    local var_name=$1
    local var_value=$2
    local env_file=".env.local"
    
    # Remove existing variable if it exists
    sed -i "/^${var_name}=/d" "$env_file"
    # Add new variable
    echo "${var_name}=${var_value}" >> "$env_file"
}

echo -e "${YELLOW}Let's configure your email settings step by step:${NC}"
echo

# SMTP Host
echo -e "${BLUE}1. SMTP Host Configuration${NC}"
read -p "Enter SMTP Host (default: smtp.gmail.com): " smtp_host
smtp_host=${smtp_host:-smtp.gmail.com}
update_env_var "SMTP_HOST" "$smtp_host"
echo -e "${GREEN}✅ SMTP Host set to: $smtp_host${NC}"
echo

# SMTP Port
echo -e "${BLUE}2. SMTP Port Configuration${NC}"
read -p "Enter SMTP Port (default: 587): " smtp_port
smtp_port=${smtp_port:-587}
update_env_var "SMTP_PORT" "$smtp_port"
echo -e "${GREEN}✅ SMTP Port set to: $smtp_port${NC}"
echo

# SMTP Secure
echo -e "${BLUE}3. SMTP Security Configuration${NC}"
read -p "Use secure connection? (true/false, default: false): " smtp_secure
smtp_secure=${smtp_secure:-false}
update_env_var "SMTP_SECURE" "$smtp_secure"
echo -e "${GREEN}✅ SMTP Secure set to: $smtp_secure${NC}"
echo

# SMTP User
echo -e "${BLUE}4. SMTP Username Configuration${NC}"
echo "This should be your full email address (e.g., yourname@gmail.com)"
read -p "Enter SMTP Username: " smtp_user
if [ -z "$smtp_user" ]; then
    echo -e "${RED}❌ SMTP Username is required!${NC}"
    exit 1
fi
update_env_var "SMTP_USER" "$smtp_user"
echo -e "${GREEN}✅ SMTP User set to: $smtp_user${NC}"
echo

# SMTP Password
echo -e "${BLUE}5. SMTP Password Configuration${NC}"
if [[ "$smtp_host" == *"gmail"* ]]; then
    echo -e "${YELLOW}⚠️  For Gmail, you MUST use an App Password, not your regular password!${NC}"
    echo "How to get Gmail App Password:"
    echo "1. Go to Google Account → Security"
    echo "2. Enable 2-Step Verification"
    echo "3. Go to App passwords"
    echo "4. Select 'Mail' and 'Other' (name it 'Cowrie Honeypot')"
    echo "5. Copy the generated 16-character password"
    echo
fi
read -s -p "Enter SMTP Password (App Password for Gmail): " smtp_password
echo
if [ -z "$smtp_password" ]; then
    echo -e "${RED}❌ SMTP Password is required!${NC}"
    exit 1
fi
update_env_var "SMTP_PASSWORD" "$smtp_password"
echo -e "${GREEN}✅ SMTP Password configured${NC}"
echo

# Admin Email
echo -e "${BLUE}6. Admin Email Configuration${NC}"
echo "This is where alert emails will be sent"
read -p "Enter Admin Email (default: use SMTP user): " admin_email
admin_email=${admin_email:-$smtp_user}
update_env_var "ADMIN_EMAIL" "$admin_email"
echo -e "${GREEN}✅ Admin Email set to: $admin_email${NC}"
echo

# Cowrie Log Path
echo -e "${BLUE}7. Cowrie Log Path Configuration${NC}"
cowrie_log_path="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
update_env_var "COWRIE_LOG_PATH" "$cowrie_log_path"
echo -e "${GREEN}✅ Cowrie Log Path set to: $cowrie_log_path${NC}"
echo

# Show final configuration
echo -e "${BLUE}Final .env.local configuration:${NC}"
echo "================================"
cat .env.local
echo

# Set proper permissions
chmod 600 .env.local
echo -e "${GREEN}✅ Set secure permissions on .env.local${NC}"

echo
echo -e "${GREEN}🎉 Email configuration completed successfully!${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Restart your application: npm run dev"
echo "2. Go to http://localhost:3000/alerts"
echo "3. Click 'Send Test Alert' to verify configuration"
echo

if [[ "$smtp_host" == *"gmail"* ]]; then
    echo -e "${YELLOW}Gmail users reminder:${NC}"
    echo "- Make sure you used an App Password, not your regular password"
    echo "- Ensure 2-Step Verification is enabled on your Google Account"
    echo
fi
