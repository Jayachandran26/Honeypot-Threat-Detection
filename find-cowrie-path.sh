#!/bin/bash

echo "🔍 Finding Your Cowrie Installation Path..."
echo "=========================================="

# Function to check if a directory contains Cowrie
check_cowrie_directory() {
    local dir="$1"
    if [ -d "$dir" ]; then
        # Check for Cowrie-specific files/directories
        if [ -f "$dir/bin/cowrie" ] || [ -f "$dir/cowrie.py" ] || [ -d "$dir/etc" ]; then
            echo "✅ Found Cowrie installation at: $dir"
            
            # Check for configuration file
            if [ -f "$dir/etc/cowrie.cfg" ]; then
                echo "   📝 Config file: $dir/etc/cowrie.cfg"
            fi
            
            # Check for log directory
            if [ -d "$dir/var/log/cowrie" ]; then
                echo "   📁 Log directory: $dir/var/log/cowrie"
                if [ -f "$dir/var/log/cowrie/cowrie.json" ]; then
                    echo "   📄 JSON log: $dir/var/log/cowrie/cowrie.json"
                fi
            fi
            
            return 0
        fi
    fi
    return 1
}

echo "Method 1: Checking if Cowrie is currently running..."
COWRIE_PID=$(pgrep -f cowrie | head -1)
if [ -n "$COWRIE_PID" ]; then
    echo "✅ Found Cowrie process (PID: $COWRIE_PID)"
    
    # Get the working directory of the running process
    if command -v lsof >/dev/null 2>&1; then
        WORKING_DIR=$(sudo lsof -p "$COWRIE_PID" 2>/dev/null | grep cwd | awk '{print $9}')
        if [ -n "$WORKING_DIR" ]; then
            echo "📁 Cowrie working directory: $WORKING_DIR"
            check_cowrie_directory "$WORKING_DIR"
        fi
    fi
    
    # Get the executable path
    EXE_PATH=$(sudo readlink -f /proc/$COWRIE_PID/exe 2>/dev/null)
    if [ -n "$EXE_PATH" ]; then
        echo "🔧 Cowrie executable: $EXE_PATH"
        COWRIE_DIR=$(dirname "$(dirname "$EXE_PATH")")
        check_cowrie_directory "$COWRIE_DIR"
    fi
    
    # Show process details
    echo "📊 Process details:"
    ps aux | grep cowrie | grep -v grep
else
    echo "❌ No Cowrie process currently running"
fi

echo ""
echo "Method 2: Checking common installation locations..."

# Common Cowrie installation paths
COMMON_PATHS=(
    "/home/cowrie/cowrie"
    "/home/$USER/cowrie"
    "/opt/cowrie"
    "/usr/local/cowrie"
    "/var/lib/cowrie"
    "$(pwd)/cowrie"
    "/home/*/cowrie"
)

for path in "${COMMON_PATHS[@]}"; do
    # Handle wildcard paths
    if [[ "$path" == *"*"* ]]; then
        for expanded_path in $path; do
            if check_cowrie_directory "$expanded_path"; then
                echo "   Found via common path check"
            fi
        done
    else
        if check_cowrie_directory "$path"; then
            echo "   Found via common path check"
        fi
    fi
done

echo ""
echo "Method 3: Searching filesystem for Cowrie directories..."

# Search for directories named cowrie
echo "🔍 Searching for 'cowrie' directories..."
FOUND_DIRS=$(find /home /opt /usr/local /var -name "*cowrie*" -type d 2>/dev/null | head -10)

if [ -n "$FOUND_DIRS" ]; then
    echo "Found potential Cowrie directories:"
    while IFS= read -r dir; do
        echo "   📁 $dir"
        if check_cowrie_directory "$dir"; then
            echo "      ✅ This appears to be a valid Cowrie installation"
        fi
    done <<< "$FOUND_DIRS"
else
    echo "❌ No directories named 'cowrie' found"
fi

echo ""
echo "Method 4: Checking systemd service..."

if systemctl list-unit-files | grep -q cowrie; then
    echo "✅ Found Cowrie systemd service"
    
    # Get service file location
    SERVICE_FILE=$(systemctl show cowrie -p FragmentPath --value 2>/dev/null)
    if [ -n "$SERVICE_FILE" ] && [ -f "$SERVICE_FILE" ]; then
        echo "📄 Service file: $SERVICE_FILE"
        
        # Extract working directory from service file
        WORKING_DIR=$(grep "WorkingDirectory" "$SERVICE_FILE" | cut -d'=' -f2)
        if [ -n "$WORKING_DIR" ]; then
            echo "📁 Service working directory: $WORKING_DIR"
            check_cowrie_directory "$WORKING_DIR"
        fi
        
        # Extract ExecStart path
        EXEC_START=$(grep "ExecStart" "$SERVICE_FILE" | cut -d'=' -f2)
        if [ -n "$EXEC_START" ]; then
            echo "🔧 Service exec start: $EXEC_START"
            COWRIE_DIR=$(dirname "$(dirname "$EXEC_START")")
            check_cowrie_directory "$COWRIE_DIR"
        fi
    fi
else
    echo "❌ No Cowrie systemd service found"
fi

echo ""
echo "Method 5: Checking current project log configuration..."

if [ -f ".env.local" ]; then
    echo "✅ Found .env.local file"
    COWRIE_LOG_PATH=$(grep "COWRIE_LOG_PATH" .env.local | cut -d'=' -f2)
    if [ -n "$COWRIE_LOG_PATH" ]; then
        echo "📄 Configured log path: $COWRIE_LOG_PATH"
        
        # Extract directory from log path
        LOG_DIR=$(dirname "$COWRIE_LOG_PATH")
        COWRIE_DIR=$(dirname "$(dirname "$LOG_DIR")")
        
        echo "📁 Inferred Cowrie directory: $COWRIE_DIR"
        check_cowrie_directory "$COWRIE_DIR"
    fi
else
    echo "❌ No .env.local file found"
fi

echo ""
echo "Method 6: Checking for Python virtual environments..."

# Look for Cowrie virtual environments
VENV_PATHS=$(find /home -name "*cowrie*env*" -type d 2>/dev/null | head -5)
if [ -n "$VENV_PATHS" ]; then
    echo "✅ Found potential Cowrie virtual environments:"
    while IFS= read -r venv; do
        echo "   🐍 $venv"
        COWRIE_DIR=$(dirname "$venv")
        check_cowrie_directory "$COWRIE_DIR"
    done <<< "$VENV_PATHS"
fi

echo ""
echo "📋 SUMMARY"
echo "=========="

# Check if we found any valid installations
if pgrep -f cowrie > /dev/null; then
    echo "✅ Cowrie is currently running"
    echo "🎯 To find the exact path, run: sudo lsof -p \$(pgrep cowrie) | grep cwd"
else
    echo "❌ Cowrie is not currently running"
fi

echo ""
echo "💡 NEXT STEPS:"
echo "1. If Cowrie was found above, note the path"
echo "2. If not found, you may need to install Cowrie first"
echo "3. Run './find-and-fix-cowrie.sh' to install if needed"
echo "4. Update your .env.local with the correct COWRIE_LOG_PATH"

echo ""
echo "🔧 Quick commands to try:"
echo "   sudo systemctl status cowrie"
echo "   ps aux | grep cowrie"
echo "   find /home -name cowrie -type d 2>/dev/null"
