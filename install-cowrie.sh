#!/bin/bash

echo "🍯 Installing Cowrie Honeypot..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install dependencies
echo "📦 Installing dependencies..."
sudo apt install -y git python3-virtualenv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind virtualenv python3-pip

# Create cowrie user
echo "👤 Creating cowrie user..."
if ! id "cowrie" &>/dev/null; then
    sudo adduser --disabled-password --gecos "" cowrie
    echo "✅ User 'cowrie' created"
else
    echo "✅ User 'cowrie' already exists"
fi

# Switch to cowrie user and install
echo "🔧 Installing Cowrie as cowrie user..."
sudo -u cowrie bash << 'EOF'
cd /home/cowrie

# Clone Cowrie repository
if [ ! -d "cowrie" ]; then
    echo "📥 Cloning Cowrie repository..."
    git clone http://github.com/cowrie/cowrie
else
    echo "✅ Cowrie repository already exists"
fi

cd cowrie

# Create virtual environment
if [ ! -d "cowrie-env" ]; then
    echo "🐍 Creating Python virtual environment..."
    python3 -m venv cowrie-env
else
    echo "✅ Virtual environment already exists"
fi

# Activate virtual environment and install dependencies
echo "📦 Installing Python dependencies..."
source cowrie-env/bin/activate
pip install --upgrade pip
pip install --upgrade -r requirements.txt

# Copy configuration files
echo "⚙️ Setting up configuration..."
if [ ! -f "etc/cowrie.cfg" ]; then
    cp etc/cowrie.cfg.dist etc/cowrie.cfg
fi

if [ ! -f "etc/userdb.txt" ]; then
    cp etc/userdb.example etc/userdb.txt
fi

# Generate SSH keys
echo "🔑 Generating SSH keys..."
if [ ! -f "etc/ssh_host_rsa_key" ]; then
    ssh-keygen -t rsa -b 2048 -f etc/ssh_host_rsa_key -N ''
fi

if [ ! -f "etc/ssh_host_dsa_key" ]; then
    ssh-keygen -t dsa -b 1024 -f etc/ssh_host_dsa_key -N ''
fi

if [ ! -f "etc/ssh_host_ecdsa_key" ]; then
    ssh-keygen -t ecdsa -b 256 -f etc/ssh_host_ecdsa_key -N ''
fi

if [ ! -f "etc/ssh_host_ed25519_key" ]; then
    ssh-keygen -t ed25519 -f etc/ssh_host_ed25519_key -N ''
fi

# Create directories
echo "📁 Creating directories..."
mkdir -p var/log/cowrie var/lib/cowrie/downloads var/lib/cowrie/tty

echo "✅ Cowrie installation completed for user cowrie"
EOF

# Configure Cowrie
echo "⚙️ Configuring Cowrie..."
sudo -u cowrie bash << 'EOF'
cd /home/cowrie/cowrie

# Create custom configuration
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

echo "✅ Cowrie configuration created"
EOF

# Set up systemd service
echo "🔧 Setting up systemd service..."
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

# Enable and start service
echo "🚀 Starting Cowrie service..."
sudo systemctl daemon-reload
sudo systemctl enable cowrie

# Set up authbind for low ports (optional)
echo "🔧 Setting up authbind for low ports..."
sudo touch /etc/authbind/byport/22
sudo touch /etc/authbind/byport/23
sudo chown cowrie:cowrie /etc/authbind/byport/22
sudo chown cowrie:cowrie /etc/authbind/byport/23
sudo chmod 755 /etc/authbind/byport/22
sudo chmod 755 /etc/authbind/byport/23

# Start Cowrie
echo "🚀 Starting Cowrie..."
sudo systemctl start cowrie

# Wait a moment for startup
sleep 5

# Check status
echo "📊 Checking Cowrie status..."
if sudo systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie is running"
else
    echo "❌ Cowrie failed to start"
    echo "📝 Checking logs..."
    sudo journalctl -u cowrie --no-pager -l
fi

# Check if ports are listening
echo "🔍 Checking ports..."
if netstat -ln | grep -q ":2222"; then
    echo "✅ SSH honeypot is listening on port 2222"
else
    echo "❌ SSH honeypot is not listening on port 2222"
fi

if netstat -ln | grep -q ":2223"; then
    echo "✅ Telnet honeypot is listening on port 2223"
else
    echo "❌ Telnet honeypot is not listening on port 2223"
fi

# Set up log file permissions
echo "🔧 Setting up log file permissions..."
sudo chmod 644 /home/cowrie/cowrie/var/log/cowrie/cowrie.json 2>/dev/null || true

echo ""
echo "🎉 Cowrie installation completed!"
echo ""
echo "📊 Service Status:"
sudo systemctl status cowrie --no-pager -l
echo ""
echo "🔗 Connection endpoints:"
echo "   SSH: ssh root@localhost -p 2222"
echo "   Telnet: telnet localhost 2223"
echo ""
echo "📝 Log file: /home/cowrie/cowrie/var/log/cowrie/cowrie.json"
echo ""
echo "🛠️ Management commands:"
echo "   Start: sudo systemctl start cowrie"
echo "   Stop: sudo systemctl stop cowrie"
echo "   Status: sudo systemctl status cowrie"
echo "   Logs: sudo journalctl -u cowrie -f"
