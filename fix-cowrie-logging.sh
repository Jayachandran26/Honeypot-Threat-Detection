#!/bin/bash

echo "🔧 Fixing Cowrie Logging Configuration..."

# Stop Cowrie temporarily
echo "🛑 Stopping Cowrie temporarily..."
sudo systemctl stop cowrie
sleep 3

# Ensure cowrie user and directories exist
echo "👤 Setting up cowrie user and directories..."
sudo -u cowrie bash << 'EOF'
cd $HOME

# Create cowrie directory if it doesn't exist
if [ ! -d "cowrie" ]; then
    echo "📁 Creating cowrie directory..."
    mkdir -p cowrie
fi

cd cowrie

# Create necessary directories
echo "📁 Creating log directories..."
mkdir -p var/log/cowrie
mkdir -p var/lib/cowrie/downloads
mkdir -p var/lib/cowrie/tty
mkdir -p etc

# Create the JSON log file
echo "📝 Creating JSON log file..."
touch var/log/cowrie/cowrie.json

echo "✅ Directories and log file created"
ls -la var/log/cowrie/
EOF

# Update Cowrie configuration to ensure JSON logging is enabled
echo "⚙️ Updating Cowrie configuration..."
sudo -u cowrie bash << 'EOF'
cd $HOME/cowrie

# Backup existing config if it exists
if [ -f "etc/cowrie.cfg" ]; then
    cp etc/cowrie.cfg etc/cowrie.cfg.backup
fi

# Create a proper configuration file
cat > etc/cowrie.cfg << 'CONFIG'
[honeypot]
hostname = srv04
log_path = var/log/cowrie
download_path = var/lib/cowrie/downloads
share_path = share/cowrie
state_path = var/lib/cowrie
etc_path = etc
contents_path = honeyfs
txtcmds_path = txtcmds
ttylog_path = var/lib/cowrie/tty
interactive_timeout = 180
authentication_timeout = 120
backend = shell

[ssh]
enabled = true
rsa_public_key = etc/ssh_host_rsa_key.pub
rsa_private_key = etc/ssh_host_rsa_key
dsa_public_key = etc/ssh_host_dsa_key.pub
dsa_private_key = etc/ssh_host_dsa_key
ecdsa_public_key = etc/ssh_host_ecdsa_key.pub
ecdsa_private_key = etc/ssh_host_ecdsa_key
ed25519_public_key = etc/ssh_host_ed25519_key.pub
ed25519_private_key = etc/ssh_host_ed25519_key
version = SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2
listen_endpoints = tcp:2222:interface=0.0.0.0
sftp_enabled = true

[telnet]
enabled = true
listen_endpoints = tcp:2223:interface=0.0.0.0

[output_jsonlog]
enabled = true
logfile = var/log/cowrie/cowrie.json
epoch_timestamp = true

[output_mysql]
enabled = false

[output_elasticsearch]
enabled = false

[output_splunk]
enabled = false
CONFIG

echo "✅ Configuration updated"
EOF

# Make sure SSH keys exist
echo "🔑 Ensuring SSH keys exist..."
sudo -u cowrie bash << 'EOF'
cd $HOME/cowrie

if [ ! -f "etc/ssh_host_rsa_key" ]; then
    echo "Generating RSA key..."
    ssh-keygen -t rsa -b 2048 -f etc/ssh_host_rsa_key -N ''
fi

if [ ! -f "etc/ssh_host_dsa_key" ]; then
    echo "Generating DSA key..."
    ssh-keygen -t dsa -b 1024 -f etc/ssh_host_dsa_key -N ''
fi

if [ ! -f "etc/ssh_host_ecdsa_key" ]; then
    echo "Generating ECDSA key..."
    ssh-keygen -t ecdsa -b 256 -f etc/ssh_host_ecdsa_key -N ''
fi

if [ ! -f "etc/ssh_host_ed25519_key" ]; then
    echo "Generating Ed25519 key..."
    ssh-keygen -t ed25519 -f etc/ssh_host_ed25519_key -N ''
fi

echo "✅ SSH keys ready"
EOF

# Set proper permissions
echo "🔒 Setting proper permissions..."
sudo chown -R cowrie:cowrie /home/cowrie/cowrie
sudo chmod 644 /home/cowrie/cowrie/var/log/cowrie/cowrie.json

# Start Cowrie
echo "🚀 Starting Cowrie..."
sudo systemctl start cowrie
sleep 5

# Check if it's running
if systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie is running"
else
    echo "❌ Cowrie failed to start"
    echo "Checking logs..."
    sudo journalctl -u cowrie --no-pager -n 20
fi

# Test log file
echo "🧪 Testing log file..."
LOG_FILE="/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
if [ -f "$LOG_FILE" ]; then
    echo "✅ Log file exists: $LOG_FILE"
    echo "📊 Size: $(du -h "$LOG_FILE" | cut -f1)"
    echo "🔒 Permissions: $(ls -la "$LOG_FILE")"
else
    echo "❌ Log file still missing"
fi

echo ""
echo "✅ Cowrie logging fix complete!"
