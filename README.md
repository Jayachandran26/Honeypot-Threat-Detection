# Honeypot-Threat-Detection

A Honeypot Threat Detection System using Cowrie and WSL.

---

## 📋 Prerequisites & Setup Guide

Follow the steps below to set up the system from scratch:

---

### ✅ 1. WSL Installed

Ensure you have Windows Subsystem for Linux (WSL) enabled with a Linux distribution like Ubuntu.

```powershell
# Run this in PowerShell as Administrator to install WSL and the Ubuntu distribution
wsl --install

# Restart your computer after installation completes
# Launch "Ubuntu" from the Start menu to finish setup

### ✅ 2. Cowrie Installed
Install the Cowrie honeypot framework after setting up WSL.

bash
Copy
Edit
# Inside Ubuntu (WSL), update your packages
sudo apt update && sudo apt upgrade -y

# Install system dependencies for Cowrie
sudo apt install git python3 python3-venv python3-pip libssl-dev libffi-dev \
build-essential libpython3-dev libevent-dev authbind -y

# (Optional) Create a dedicated user for running Cowrie
sudo adduser --disabled-password cowrie

# Switch to the cowrie user
sudo su - cowrie

# Clone Cowrie from GitHub
git clone https://github.com/cowrie/cowrie.git
cd cowrie 

### ✅ 3. Python 3.10+
Cowrie requires Python 3.10 or later. Install and configure it in your WSL environment.

bash
Copy
Edit
# Install Python 3.10 and development tools
sudo apt install python3.10 python3.10-venv python3.10-dev -y

# Set Python 3.10 as the default python3 interpreter (if needed)
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

### ✅ 4. Virtual Environment
Use python-virtualenv to manage Cowrie’s dependencies in an isolated environment.

bash
Copy
Edit
# Install the virtual environment module
sudo apt install python3-venv -y

# Create and activate the virtual environment in the Cowrie directory
python3 -m venv cowrie-env
source cowrie-env/bin/activate

### ✅ 5. Required Dependencies
Install all necessary Python packages using the requirements.txt file provided by Cowrie.

bash
Copy
Edit
# Upgrade pip first
pip install --upgrade pip

# Install all required Python dependencies
pip install -r requirements.txt

### ✅ 6. Basic Configuration
Copy default config files to get started.

bash
Copy
Edit
cp etc/cowrie.cfg.dist etc/cowrie.cfg
cp etc/userdb.txt.dist etc/userdb.txt
Edit the configuration file:

bash
Copy
Edit
nano etc/cowrie.cfg

### ✅ 7. Run Cowrie
Use the following commands to start or stop Cowrie:

bash
Copy
Edit
# Start Cowrie
bin/cowrie start

# Stop Cowrie
bin/cowrie stop

### ✅ 8. SSH & Telnet Proxy Setup
Configure Cowrie to act as an SSH and Telnet proxy.

Edit etc/cowrie.cfg:

ini
Copy
Edit
[ssh]
listen_port = 22

[telnet]
enabled = true
listen_port = 23
To bind Cowrie to privileged ports (like 22/23), configure authbind:

bash
Copy
Edit
sudo touch /etc/authbind/byport/22
sudo touch /etc/authbind/byport/23
sudo chown cowrie /etc/authbind/byport/22
sudo chown cowrie /etc/authbind/byport/23
sudo chmod 500 /etc/authbind/byport/22
sudo chmod 500 /etc/authbind/byport/23
Modify the bin/cowrie script's shebang line to use authbind:

bash
Copy
Edit
#!/usr/bin/env authbind --deep /home/cowrie/cowrie/cowrie-env/bin/python

### ✅ 9. Fake Filesystem
Cowrie includes a simulated UNIX filesystem to trick attackers.

Default path:

bash
Copy
Edit
share/cowrie/fs.pickle
You can customize it to appear like any Linux system attackers would expect.

### ✅ 10. Logging & Monitoring
Enable logging to JSON for structured logging.

Edit etc/cowrie.cfg:

ini
Copy
Edit
[output_jsonlog]
enabled = true
Logs are saved in:

bash
Copy
Edit
var/log/cowrie/json.log

### ✅ 11. Network Configuration
Ensure proper firewall and port forwarding settings.

bash
Copy
Edit
# Allow ports 22 and 23 using UFW
sudo ufw allow 22
sudo ufw allow 23
If you're using port forwarding with Windows, set up using PowerShell:

powershell
Copy
Edit
netsh interface portproxy add v4tov4 listenport=22 listenaddress=0.0.0.0 connectport=2222 connectaddress=127.0.0.1
netsh interface portproxy add v4tov4 listenport=23 listenaddress=0.0.0.0 connectport=2323 connectaddress=127.0.0.1
Then, update cowrie.cfg to listen on ports 2222 and 2323 instead of 22 and 23.

### 📎 References
Cowrie GitHub Repository

WSL Official Documentation
