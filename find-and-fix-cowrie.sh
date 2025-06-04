#!/bin/bash

echo "🔍 Finding and Fixing Cowrie Installation..."
echo "============================================"

# Function to find Cowrie installation
find_cowrie_installation() {
    echo "🔍 Searching for Cowrie installation..."
    
    # Check common locations
    possible_locations=(
        "/home/cowrie/cowrie"
        "/opt/cowrie"
        "/usr/local/cowrie"
        "/home/$USER/cowrie"
        "$(pwd)/cowrie"
        "/var/lib/cowrie"
    )
    
    for location in "${possible_locations[@]}"; do
        if [ -d "$location" ]; then
            echo "✅ Found Cowrie at: $location"
            echo "$location"
            return 0
        fi
    done
    
    # Search for cowrie directories
    echo "🔍 Searching entire system for cowrie directories..."
    find /home /opt /usr/local /var -name "*cowrie*" -type d 2>/dev/null | head -10
    
    return 1
}

# Function to check if Cowrie is running
check_cowrie_process() {
    echo "🔍 Checking for Cowrie processes..."
    
    if pgrep -f cowrie > /dev/null; then
        echo "✅ Cowrie process found!"
        ps aux | grep cowrie | grep -v grep
        
        # Get working directory from process
        COWRIE_PID=$(pgrep -f cowrie | head -1)
        if [ -n "$COWRIE_PID" ]; then
            WORKING_DIR=$(sudo lsof -p "$COWRIE_PID" 2>/dev/null | grep cwd | awk '{print $9}')
            if [ -n "$WORKING_DIR" ]; then
                echo "📁 Cowrie working directory: $WORKING_DIR"
                echo "$WORKING_DIR"
                return 0
            fi
        fi
    else
        echo "❌ No Cowrie process found"
    fi
    
    return 1
}

# Function to install Cowrie if not found
install_cowrie() {
    echo "📦 Installing Cowrie from scratch..."
    
    # Update system
    sudo apt update
    
    # Install dependencies
    sudo apt install -y git python3-virtualenv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind virtualenv python3-pip
    
    # Create cowrie user
    if ! id "cowrie" &>/dev/null; then
        sudo adduser --disabled-password --gecos "" cowrie
        echo "✅ Created cowrie user"
    fi
    
    # Install Cowrie
    sudo -u cowrie bash << 'EOF'
cd /home/cowrie

# Clone Cowrie
if [ ! -d "cowrie" ]; then
    git clone https://github.com/cowrie/cowrie.git
fi

cd cowrie

# Create virtual environment
python3 -m venv cowrie-env

# Activate and install dependencies
source cowrie-env/bin/activate
pip install --upgrade pip
pip install --upgrade -r requirements.txt

# Copy configuration
cp etc/cowrie.cfg.dist etc/cowrie.cfg
cp etc/userdb.example etc/userdb.txt

# Generate SSH keys
ssh-keygen -t rsa -b 2048 -f etc/ssh_host_rsa_key -N ''
ssh-keygen -t dsa -b 1024 -f etc/ssh_host_dsa_key -N ''
ssh-keygen -t ecdsa -b 256 -f etc/ssh_host_ecdsa_key -N ''
ssh-keygen -t ed25519 -f etc/ssh_host_ed25519_key -N ''

# Create directories
mkdir -p var/log/cowrie var/lib/cowrie/downloads var/lib/cowrie/tty

echo "✅ Cowrie installed successfully"
EOF

    # Create systemd service
    sudo tee /etc/systemd/system/cowrie.service > /dev/null << 'EOF'
[Unit]
Description=Cowrie SSH/Telnet Honeypot
After=network.target

[Service]
Type=forking
User=cowrie
Group=cowrie
ExecStart=/home/cowrie/cowrie/bin/cowrie start
ExecStop=/home/cowrie/cowrie/bin/cowrie stop
PIDFile=/home/cowrie/cowrie/var/run/cowrie.pid
WorkingDirectory=/home/cowrie/cowrie
Environment=VIRTUAL_ENV=/home/cowrie/cowrie/cowrie-env
Environment=PATH=/home/cowrie/cowrie/cowrie-env/bin:/usr/local/bin:/usr/bin:/bin

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable cowrie
    
    echo "/home/cowrie/cowrie"
}

# Main execution
echo "Step 1: Finding Cowrie..."
COWRIE_PATH=$(find_cowrie_installation)

if [ -z "$COWRIE_PATH" ]; then
    echo "Step 2: Checking running processes..."
    COWRIE_PATH=$(check_cowrie_process)
fi

if [ -z "$COWRIE_PATH" ]; then
    echo "Step 3: Installing Cowrie..."
    COWRIE_PATH=$(install_cowrie)
fi

if [ -z "$COWRIE_PATH" ]; then
    echo "❌ Could not find or install Cowrie"
    exit 1
fi

echo ""
echo "✅ Cowrie found/installed at: $COWRIE_PATH"

# Now configure Cowrie properly
echo ""
echo "⚙️ Configuring Cowrie for proper logging..."

# Stop Cowrie if running
sudo systemctl stop cowrie 2>/dev/null || true
sleep 3

# Configure Cowrie with absolute paths
sudo -u cowrie bash << EOF
cd "$COWRIE_PATH"

# Backup existing config
if [ -f "etc/cowrie.cfg" ]; then
    cp etc/cowrie.cfg etc/cowrie.cfg.backup.\$(date +%Y%m%d_%H%M%S)
fi

# Create new configuration with absolute paths
cat > etc/cowrie.cfg << 'CONFIG'
[honeypot]
hostname = srv04
log_path = $COWRIE_PATH/var/log/cowrie
download_path = $COWRIE_PATH/var/lib/cowrie/downloads
share_path = $COWRIE_PATH/share/cowrie
state_path = $COWRIE_PATH/var/lib/cowrie
etc_path = $COWRIE_PATH/etc
contents_path = $COWRIE_PATH/honeyfs
txtcmds_path = $COWRIE_PATH/txtcmds
ttylog_path = $COWRIE_PATH/var/lib/cowrie/tty
interactive_timeout = 180
authentication_timeout = 120
backend = shell

[ssh]
enabled = true
rsa_public_key = $COWRIE_PATH/etc/ssh_host_rsa_key.pub
rsa_private_key = $COWRIE_PATH/etc/ssh_host_rsa_key
dsa_public_key = $COWRIE_PATH/etc/ssh_host_dsa_key.pub
dsa_private_key = $COWRIE_PATH/etc/ssh_host_dsa_key
ecdsa_public_key = $COWRIE_PATH/etc/ssh_host_ecdsa_key.pub
ecdsa_private_key = $COWRIE_PATH/etc/ssh_host_ecdsa_key
ed25519_public_key = $COWRIE_PATH/etc/ssh_host_ed25519_key.pub
ed25519_private_key = $COWRIE_PATH/etc/ssh_host_ed25519_key
version = SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2
listen_endpoints = tcp:2222:interface=0.0.0.0
sftp_enabled = true

[telnet]
enabled = true
listen_endpoints = tcp:2223:interface=0.0.0.0

[output_jsonlog]
enabled = true
logfile = $COWRIE_PATH/var/log/cowrie/cowrie.json
epoch_timestamp = true

[output_textlog]
enabled = true
logfile = $COWRIE_PATH/var/log/cowrie/cowrie.log

[output_mysql]
enabled = false

[output_elasticsearch]
enabled = false

[output_splunk]
enabled = false
CONFIG

# Create log directories and files
mkdir -p var/log/cowrie var/lib/cowrie/downloads var/lib/cowrie/tty
touch var/log/cowrie/cowrie.json
touch var/log/cowrie/cowrie.log

echo "✅ Configuration updated with absolute paths"
EOF

# Set proper permissions
sudo chown -R cowrie:cowrie "$COWRIE_PATH"
sudo chmod 755 "$COWRIE_PATH/var/log/cowrie"
sudo chmod 644 "$COWRIE_PATH/var/log/cowrie/cowrie.json"

# Update environment file
echo "COWRIE_LOG_PATH=$COWRIE_PATH/var/log/cowrie/cowrie.json" > .env.local

# Start Cowrie
echo "🚀 Starting Cowrie..."
sudo systemctl start cowrie
sleep 5

# Check status
if systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie is running!"
    
    # Check log file
    LOG_FILE="$COWRIE_PATH/var/log/cowrie/cowrie.json"
    if [ -f "$LOG_FILE" ]; then
        echo "✅ Log file exists: $LOG_FILE"
        echo "🔒 Permissions: $(ls -la "$LOG_FILE")"
        
        if [ -r "$LOG_FILE" ]; then
            echo "✅ Log file is readable!"
        else
            echo "🔧 Fixing permissions..."
            sudo chmod 644 "$LOG_FILE"
        fi
    else
        echo "❌ Log file not created"
    fi
    
    # Show process info
    echo "📊 Cowrie process info:"
    ps aux | grep cowrie | grep -v grep
    
    # Check ports
    echo "🌐 Checking ports..."
    if ss -ln | grep -q ":2222"; then
        echo "✅ SSH port 2222 is listening"
    else
        echo "❌ SSH port 2222 is not listening"
    fi
    
    if ss -ln | grep -q ":2223"; then
        echo "✅ Telnet port 2223 is listening"
    else
        echo "❌ Telnet port 2223 is not listening"
    fi
    
else
    echo "❌ Cowrie failed to start"
    echo "📝 Checking logs..."
    sudo journalctl -u cowrie --no-pager -n 20
fi

echo ""
echo "✅ Setup complete!"
echo "📊 Cowrie path: $COWRIE_PATH"
echo "📝 Log file: $COWRIE_PATH/var/log/cowrie/cowrie.json"
echo "🎯 Test with: ssh root@localhost -p 2222"
echo "📊 Dashboard: http://localhost:3000"
