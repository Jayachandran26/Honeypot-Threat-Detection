#!/bin/bash

# Cowrie Honeypot Setup Script for WSL
# This script sets up a high-interaction SSH/Telnet honeypot

echo "🍯 Setting up Cowrie Honeypot in WSL..."

# Update system
sudo apt update && sudo apt upgrade -y

# Install dependencies
sudo apt install -y git python3-virtualenv libssl-dev libffi-dev build-essential libpython3-dev python3-minimal authbind virtualenv

# Create cowrie user
sudo adduser --disabled-password cowrie
sudo su - cowrie

# Clone Cowrie repository
git clone http://github.com/cowrie/cowrie
cd cowrie

# Create virtual environment
virtualenv --python=python3 cowrie-env
source cowrie-env/bin/activate

# Install Python dependencies
pip install --upgrade pip
pip install --upgrade -r requirements.txt

# Copy configuration files
cp etc/cowrie.cfg.dist etc/cowrie.cfg
cp etc/userdb.example etc/userdb.txt

# Configure Cowrie
cat > etc/cowrie.cfg << 'EOF'
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
EOF

# Generate SSH keys
ssh-keygen -t rsa -b 2048 -f etc/ssh_host_rsa_key -N ''
ssh-keygen -t dsa -b 1024 -f etc/ssh_host_dsa_key -N ''

# Create filesystem structure
mkdir -p var/log/cowrie var/lib/cowrie/downloads var/lib/cowrie/tty

# Set up port forwarding (requires root)
echo "Setting up port forwarding..."
sudo iptables -t nat -A PREROUTING -p tcp --dport 22 -j REDIRECT --to-port 2222
sudo iptables -t nat -A PREROUTING -p tcp --dport 23 -j REDIRECT --to-port 2223

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

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable cowrie
sudo systemctl start cowrie

echo "✅ Cowrie honeypot setup complete!"
echo "📊 Dashboard available at: http://localhost:3000"
echo "🔍 SSH honeypot listening on port 2222"
echo "🔍 Telnet honeypot listening on port 2223"
echo "📝 Logs available at: /home/cowrie/cowrie/var/log/cowrie/"
