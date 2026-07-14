#!/bin/bash
# Simple deployment script

echo "Deploying Bioinformatics Environment..."

# Refuse to start with no credentials. podman-compose does not honour the
# ${VAR:?msg} form, so the check has to happen here.
if [ -f .env ]; then
    set -a
    . ./.env
    set +a
fi
for var in RSTUDIO_PASSWORD JUPYTER_TOKEN; do
    if [ -z "${!var}" ]; then
        echo "ERROR: $var is not set."
        echo "Copy .env.example to .env and set a value:"
        echo "  RSTUDIO_PASSWORD=\$(openssl rand -base64 24)"
        echo "  JUPYTER_TOKEN=\$(openssl rand -hex 24)"
        exit 1
    fi
done

# Create workspace if it doesn't exist
mkdir -p workspace

# Check if ports are free
for port in 8787 8888 8080; do
    if netstat -tuln 2>/dev/null | grep -q ":$port "; then
        echo "Port $port is in use! Please stop the service using it."
        exit 1
    fi
done

# Build and start
echo "Building and starting containers..."
podman-compose up --build -d

echo "Waiting for services to start..."
sleep 15

# Get server IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "Bioinformatics Environment is ready!"
echo ""
echo "Access from your laptop:"
echo "   RStudio:    http://$SERVER_IP:8787"
echo "   Jupyter:    http://$SERVER_IP:8888"
echo "   VSCode:     http://$SERVER_IP:8080"
echo ""
echo "Your files are saved in: $(pwd)/workspace/"
echo ""
echo "To stop: podman-compose down"
