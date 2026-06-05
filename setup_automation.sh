#!/bin/bash
# EconData Automation Setup Script
# Installs the monthly launchd job and configures email notifications

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLIST_NAME="com.econdata.monthly-update.plist"
PLIST_SOURCE="$SCRIPT_DIR/$PLIST_NAME"
PLIST_DEST="$HOME/Library/LaunchAgents/$PLIST_NAME"

echo "========================================"
echo "EconData Automation Setup"
echo "========================================"
echo ""

# Check if plist exists
if [ ! -f "$PLIST_SOURCE" ]; then
    echo "ERROR: Plist file not found at $PLIST_SOURCE"
    exit 1
fi

# Create LaunchAgents directory if needed
mkdir -p "$HOME/Library/LaunchAgents"

# Unload existing job if present
if launchctl list | grep -q "com.econdata.monthly-update"; then
    echo "Unloading existing job..."
    launchctl unload "$PLIST_DEST" 2>/dev/null || true
fi

# Copy plist to LaunchAgents
echo "Installing launchd job..."
cp "$PLIST_SOURCE" "$PLIST_DEST"

# Load the job
echo "Loading launchd job..."
launchctl load "$PLIST_DEST"

echo ""
echo "Launchd job installed successfully!"
echo "Schedule: 20th of each month at 9:00 AM"
echo ""

# Test run option
echo "========================================"
echo "Test the Pipeline"
echo "========================================"
echo ""
echo "To test the monthly update manually, run:"
echo "  cd $SCRIPT_DIR"
echo "  python3 run_monthly_update.py"
echo ""
echo "For a full annual update (including Census/BEA):"
echo "  python3 run_monthly_update.py --annual"
echo ""

# Note about MSA file
echo "========================================"
echo "MSA Unemployment Data"
echo "========================================"
echo ""
echo "MSA seasonally-adjusted unemployment is now downloaded"
echo "automatically from: https://www.bls.gov/web/metro/ssamatab1.txt"
echo ""

# Show status
echo "========================================"
echo "Logs"
echo "========================================"
echo ""
echo "Pipeline logs:  $SCRIPT_DIR/monthly_update.log"
echo "launchd stdout: $SCRIPT_DIR/launchd_stdout.log"
echo "launchd stderr: $SCRIPT_DIR/launchd_stderr.log"
echo ""
echo "========================================"
echo "Current Status"
echo "========================================"
launchctl list | grep -E "com.econdata|PID" | head -5 || echo "Job loaded (will run on schedule)"
echo ""
echo "Setup complete!"
