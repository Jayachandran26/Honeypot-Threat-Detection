#!/bin/bash

echo "🔧 ULTIMATE Cowrie Log Fix - Permanent Solution"
echo "=============================================="

# Stop Cowrie first
echo "🛑 Stopping Cowrie..."
sudo systemctl stop cowrie
sleep 3

# Find Cowrie installation
COWRIE_HOME="/home/cowrie/cowrie"
if [ ! -d "$COWRIE_HOME" ]; then
    echo "❌ Cowrie not found at $COWRIE_HOME"
    exit 1
fi

echo "✅ Found Cowrie at: $COWRIE_HOME"

# Create the complete logging structure
echo "📁 Creating complete logging structure..."
sudo -u cowrie bash << 'EOF'
cd /home/cowrie/cowrie

# Create all necessary directories
mkdir -p var/log/cowrie
mkdir -p var/lib/cowrie/downloads
mkdir -p var/lib/cowrie/tty
mkdir -p etc

# Create the JSON log file
touch var/log/cowrie/cowrie.json
touch var/log/cowrie/cowrie.log

echo "✅ Created log directories and files"
ls -la var/log/cowrie/
EOF

# Create a COMPLETELY NEW Cowrie configuration with ABSOLUTE paths
echo "⚙️ Creating new Cowrie configuration with absolute paths..."
sudo -u cowrie bash << 'EOF'
cd /home/cowrie/cowrie

# Backup existing config
if [ -f "etc/cowrie.cfg" ]; then
    cp etc/cowrie.cfg etc/cowrie.cfg.backup.$(date +%Y%m%d_%H%M%S)
fi

# Create a completely new configuration file
cat > etc/cowrie.cfg << 'CONFIG'
#
# Cowrie configuration file (cowrie.cfg)
#

# ============================================================================
# General Honeypot Options
# ============================================================================
[honeypot]

# Sensor name is used to identify this Cowrie instance. Used by the database
# logging modules such as mysql.
#
# If not specified, the logging modules will instead use the IP address of the
# connection as the sensor name.
#
# (default: not specified)
#sensor_name=myhostname

# Hostname for the honeypot. Displayed by the shell prompt of the virtual
# environment.
#
# (default: svr04)
hostname = srv04

# Directory where to save log files in.
#
# (default: log)
log_path = /home/cowrie/cowrie/var/log/cowrie

# Directory where to save downloaded (malware) files in.
#
# (default: dl)
download_path = /home/cowrie/cowrie/var/lib/cowrie/downloads

# Directory where virtual file contents are kept in.
#
# This is only used by commands like 'cat' to display the contents of files.
# Adding files here is not enough for them to appear in the honeypot - the
# actual virtual filesystem is kept in filesystem_file (see below)
#
# (default: honeyfs)
contents_path = /home/cowrie/cowrie/honeyfs

# File in the python pickle format containing the virtual filesystem.
#
# This includes the filenames, paths, permissions for the Cowrie filesystem,
# but not the file contents. This is created by the createfs.py utility from
# a real template linux installation.
#
# (default: fs.pickle)
filesystem_file = /home/cowrie/cowrie/share/cowrie/fs.pickle

# Directory for miscellaneous data files, such as the password database.
#
# (default: data_path)
data_path = /home/cowrie/cowrie/data

# Directory for creating simple commands that only output text.
#
# The command must be placed under this directory with the proper path, such
# as:
#   txtcmds/usr/bin/vi
# The contents of the file will be the output of the command when run inside
# the honeypot.
#
# In addition to this, the file must exist in the virtual
# filesystem {filesystem_file}
#
# (default: txtcmds)
txtcmds_path = /home/cowrie/cowrie/txtcmds

# Maximum file size (in bytes) for downloaded files to be stored in downloaded_path.
# A value of 0 means no limit. If the file size is known to be too big from the start
# the file will not be stored on disk at all.
#
# (default: 0)
#download_limit_size = 10485760

# TTY logging directory.
# Cowrie will store TTY recordings in this directory. Each recording is a
# typescript file that can be replayed with the `replay.py` utility.
#
# (default: ttylog)
ttylog_path = /home/cowrie/cowrie/var/lib/cowrie/tty

# Session timeout. (default: 3600)
#
# The maximum time (in seconds) for a session to stay active before being
# terminated. If set to 0, sessions will not timeout.
#
# (default: 3600)
#interactive_timeout = 300

# Authentication timeout. (default: 120)
#
# The maximum time (in seconds) to wait for authentication to complete.
# If set to 0, authentication will not timeout.
#
# (default: 120)
#authentication_timeout = 120

# Backend to use for the honeypot. Current options:
#   shell - Cowrie's built-in shell
#   proxy - SSH proxy/relay functionality
#
# (default: shell)
backend = shell

# ============================================================================
# Network Specific Options
# ============================================================================

# IP addresses to listen for incoming SSH connections.
#
# (default: 0.0.0.0) = any IPv4 address
#listen_addresses = 0.0.0.0
#listen_addresses = 0.0.0.0,::

# Ports to listen for incoming SSH connections.
#
# (default: 2222)
#listen_ports = 2222
#listen_ports = 2222,2223

# ============================================================================
# SSH Specific Options
# ============================================================================
[ssh]

# Enable/disable the SSH service (default: true)
enabled = true

# IP addresses to listen for incoming SSH connections.
#
# (default: 0.0.0.0) = any IPv4 address
#listen_addresses = 0.0.0.0

# Ports to listen for incoming SSH connections.
#
# (default: 2222)
#listen_ports = 2222

# Endpoints to listen on for incoming SSH connections.
# Use this if you want to bind to multiple specific interfaces.
# Each endpoint is specified as protocol:port:interface, for example:
# tcp:2222:0.0.0.0
# tcp:2222:192.168.1.1
#
# This setting overrides listen_addresses and listen_ports
listen_endpoints = tcp:2222:interface=0.0.0.0

# SSH Version String
#
# Use this to disguise your honeypot from a simple SSH version scan
# frequent Examples:
# SSH-2.0-OpenSSH_5.1p1 Debian-5
# SSH-1.99-OpenSSH_4.3
# SSH-1.99-OpenSSH_4.7
# SSH-1.99-Sun_SSH_1.1
# SSH-2.0-OpenSSH_4.2p1 Debian-7ubuntu3.1
# SSH-2.0-OpenSSH_4.3
# SSH-2.0-OpenSSH_4.6
# SSH-2.0-OpenSSH_5.1p1 Debian-5
# SSH-2.0-OpenSSH_5.1p1 FreeBSD-20080901
# SSH-2.0-OpenSSH_5.3p1 Debian-3ubuntu5
# SSH-2.0-OpenSSH_5.3p1 Debian-3ubuntu6
# SSH-2.0-OpenSSH_5.3p1 Debian-3ubuntu7
# SSH-2.0-OpenSSH_5.5p1 Debian-6
# SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze1
# SSH-2.0-OpenSSH_5.5p1 Debian-6+squeeze2
# SSH-2.0-OpenSSH_5.8p2_hpn13v11 FreeBSD-20110503
# SSH-2.0-OpenSSH_5.9p1 Debian-5ubuntu1
# SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2
# SSH-2.0-OpenSSH_5.9
#
# (default: "SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2")
version = SSH-2.0-OpenSSH_6.0p1 Debian-4+deb7u2

# Public and private SSH key files. If these don't exist, they are created
# automatically.
rsa_public_key = /home/cowrie/cowrie/etc/ssh_host_rsa_key.pub
rsa_private_key = /home/cowrie/cowrie/etc/ssh_host_rsa_key
dsa_public_key = /home/cowrie/cowrie/etc/ssh_host_dsa_key.pub
dsa_private_key = /home/cowrie/cowrie/etc/ssh_host_dsa_key
ecdsa_public_key = /home/cowrie/cowrie/etc/ssh_host_ecdsa_key.pub
ecdsa_private_key = /home/cowrie/cowrie/etc/ssh_host_ecdsa_key
ed25519_public_key = /home/cowrie/cowrie/etc/ssh_host_ed25519_key.pub
ed25519_private_key = /home/cowrie/cowrie/etc/ssh_host_ed25519_key

# Enable/disable SFTP (default: true)
# Disabling it will not impact the honeypot functionality
sftp_enabled = true

# ============================================================================
# Telnet Specific Options
# ============================================================================
[telnet]

# Enable/disable the Telnet service (default: false)
enabled = true

# IP addresses to listen for incoming Telnet connections.
#
# (default: 0.0.0.0) = any IPv4 address
#listen_addresses = 0.0.0.0

# Ports to listen for incoming Telnet connections.
#
# (default: 2223)
#listen_ports = 2223

# Endpoints to listen on for incoming Telnet connections.
# Use this if you want to bind to multiple specific interfaces.
# Each endpoint is specified as protocol:port:interface, for example:
# tcp:2223:0.0.0.0
# tcp:2223:192.168.1.1
#
# This setting overrides listen_addresses and listen_ports
listen_endpoints = tcp:2223:interface=0.0.0.0

# ============================================================================
# Database logging Specific Options
# ============================================================================

# ============================================================================
# JSON logging Specific Options
# ============================================================================
[output_jsonlog]

# Enable/disable JSON logging (default: true)
enabled = true

# JSON log file
logfile = /home/cowrie/cowrie/var/log/cowrie/cowrie.json

# Whether to use epoch timestamp instead of ISO timestamp (default: false)
epoch_timestamp = true

# ============================================================================
# Text logging Specific Options
# ============================================================================
[output_textlog]

# Enable/disable text logging (default: true)
enabled = true

# Text log file
logfile = /home/cowrie/cowrie/var/log/cowrie/cowrie.log

# ============================================================================
# MySQL logging Specific Options
# ============================================================================
[output_mysql]

# Enable/disable MySQL logging (default: false)
enabled = false

# ============================================================================
# SQLite3 logging Specific Options
# ============================================================================
[output_sqlite]

# Enable/disable SQLite3 logging (default: false)
enabled = false

# ============================================================================
# MongoDB logging Specific Options
# ============================================================================
[output_mongodb]

# Enable/disable MongoDB logging (default: false)
enabled = false

# ============================================================================
# Splunk logging Specific Options
# ============================================================================
[output_splunk]

# Enable/disable Splunk logging (default: false)
enabled = false

# ============================================================================
# ElasticSearch logging Specific Options
# ============================================================================
[output_elasticsearch]

# Enable/disable ElasticSearch logging (default: false)
enabled = false

CONFIG

echo "✅ Created new Cowrie configuration with absolute paths"
EOF

# Ensure SSH keys exist
echo "🔑 Ensuring SSH keys exist..."
sudo -u cowrie bash << 'EOF'
cd /home/cowrie/cowrie

# Generate SSH keys if they don't exist
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
sudo chmod 755 /home/cowrie/cowrie/var/log/cowrie
sudo chmod 644 /home/cowrie/cowrie/var/log/cowrie/cowrie.json
sudo chmod 644 /home/cowrie/cowrie/var/log/cowrie/cowrie.log

# Update our environment file
echo "📝 Updating environment file..."
echo "COWRIE_LOG_PATH=/home/cowrie/cowrie/var/log/cowrie/cowrie.json" > .env.local

# Start Cowrie
echo "🚀 Starting Cowrie with new configuration..."
sudo systemctl start cowrie
sleep 5

# Check if it's running
if systemctl is-active --quiet cowrie; then
    echo "✅ Cowrie is running successfully!"
    
    # Wait a moment and check if log file is being created
    sleep 3
    
    if [ -f "/home/cowrie/cowrie/var/log/cowrie/cowrie.json" ]; then
        echo "✅ JSON log file exists!"
        echo "📊 File permissions: $(ls -la /home/cowrie/cowrie/var/log/cowrie/cowrie.json)"
        
        # Test if we can read it
        if [ -r "/home/cowrie/cowrie/var/log/cowrie/cowrie.json" ]; then
            echo "✅ Log file is readable!"
        else
            echo "⚠️ Log file exists but not readable, fixing..."
            sudo chmod 644 /home/cowrie/cowrie/var/log/cowrie/cowrie.json
        fi
    else
        echo "❌ JSON log file not created yet"
    fi
    
    # Show Cowrie process info
    echo "📊 Cowrie process info:"
    COWRIE_PID=$(pgrep -f cowrie | head -1)
    if [ -n "$COWRIE_PID" ]; then
        echo "PID: $COWRIE_PID"
        echo "Open log files:"
        sudo lsof -p "$COWRIE_PID" | grep -E "\.(json|log)$"
    fi
    
else
    echo "❌ Cowrie failed to start!"
    echo "📝 Checking logs..."
    sudo journalctl -u cowrie --no-pager -n 20
fi

echo ""
echo "🎯 Testing the honeypot..."
echo "Try connecting with: ssh root@localhost -p 2222"
echo "Use password: admin"

echo ""
echo "✅ ULTIMATE FIX COMPLETE!"
echo "📊 Dashboard: http://localhost:3000"
echo "📝 Log file: /home/cowrie/cowrie/var/log/cowrie/cowrie.json"
