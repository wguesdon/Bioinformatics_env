#!/bin/bash
set -e

echo "Initializing container environment..."

# Create all necessary directories
echo "Creating directory structure..."
mkdir -p /home/rstudio/.local/share/jupyter/runtime
mkdir -p /home/rstudio/.local/share/rstudio
mkdir -p /home/rstudio/.config/rstudio
mkdir -p /home/rstudio/.rstudio/sessions/active
mkdir -p /home/rstudio/.jupyter
mkdir -p /home/rstudio/.cache
mkdir -p /home/rstudio/R/library
mkdir -p /var/lib/rstudio-server
mkdir -p /var/run/rstudio-server

# Set proper ownership
echo "Setting permissions..."
chown -R rstudio:rstudio /home/rstudio
chmod -R 755 /home/rstudio
chown -R rstudio-server:rstudio-server /var/lib/rstudio-server 2>/dev/null || chown -R rstudio:rstudio /var/lib/rstudio-server
chown -R root:root /var/run/rstudio-server

# Set RStudio password from environment variable
echo "Configuring RStudio password..."
echo "rstudio:${RSTUDIO_PASSWORD:-rstudio}" | chpasswd

# Clean up any stale files
rm -rf /var/run/rstudio-server/* || true
rm -rf /tmp/rstudio-* || true

# Create Jupyter configuration
echo "Configuring Jupyter..."
mkdir -p /root/.jupyter
cat > /root/.jupyter/jupyter_lab_config.py << 'EOFCONFIG'
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.port = 8888
c.ServerApp.open_browser = False
c.ServerApp.root_dir = '/workspace'
c.ServerApp.allow_root = True
EOFCONFIG

# Also create config for rstudio user
cp -r /root/.jupyter /home/rstudio/
chown -R rstudio:rstudio /home/rstudio/.jupyter

# Start RStudio Server (must be started as root)
echo "Starting RStudio Server on port 8787..."
if [ "$DISABLE_AUTH" = "true" ]; then
    /usr/lib/rstudio-server/bin/rserver \
        --server-daemonize=0 \
        --server-app-armor-enabled=0 \
        --www-verify-user-agent=0 \
        --auth-none=1 &
else
    /usr/lib/rstudio-server/bin/rserver \
        --server-daemonize=0 \
        --server-app-armor-enabled=0 \
        --www-verify-user-agent=0 &
fi

# Wait for RStudio to start
sleep 5

# Start Jupyter Lab (as root for now)
echo "Starting Jupyter Lab on port 8888..."
cd /workspace && jupyter lab \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --allow-root \
    --notebook-dir=/workspace &

# Start VSCode
echo "Starting VSCode on port 8080..."
code-server \
    --bind-addr 0.0.0.0:8080 \
    --auth none \
    --user-data-dir /home/rstudio/.vscode \
    /workspace &

echo ""
echo "All services started!"
echo "================================="
echo "RStudio: http://localhost:8787 (username: rstudio, password: rstudio)"
echo "Jupyter: http://localhost:8888"
echo "VSCode: http://localhost:8080"
echo "================================="

# Keep container running
tail -f /dev/null
