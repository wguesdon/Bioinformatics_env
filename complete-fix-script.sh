#!/bin/bash

echo "🔧 Complete Fix for Bioinformatics Docker Environment"
echo "===================================================="

# Step 1: Stop everything
echo "Step 1: Stopping all containers..."
docker-compose down
docker stop bioinformatics-env 2>/dev/null || true
docker rm bioinformatics-env 2>/dev/null || true

# Step 2: Clean up volumes
echo "Step 2: Cleaning up Docker volumes..."
docker volume rm $(docker volume ls -q | grep -E "bioinformatics.*rstudio") 2>/dev/null || true

# Step 3: Create the proper startup script
echo "Step 3: Creating proper startup script..."
cat > startup_proper.sh << 'EOF'
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
/usr/lib/rstudio-server/bin/rserver \
    --server-daemonize=0 \
    --server-app-armor-enabled=0 \
    --www-verify-user-agent=0 &

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
EOF

chmod +x startup_proper.sh

# Step 4: Update docker-compose.yml
echo "Step 4: Updating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
services:
  bioinformatics:
    build: .
    container_name: bioinformatics-env
    ports:
      - "8787:8787"  # RStudio Server
      - "8888:8888"  # Jupyter Lab
      - "8080:8080"  # VSCode Server
    volumes:
      - ./workspace:/workspace
      # Use named volumes for better permission handling
      - rstudio-home:/home/rstudio
      - rstudio-local:/home/rstudio/.local
      - rstudio-config:/home/rstudio/.config
      - rstudio-lib:/var/lib/rstudio-server
    environment:
      - PASSWORD=rstudio
      - JUPYTER_TOKEN=${JUPYTER_TOKEN:-}
      - DISABLE_AUTH=${DISABLE_AUTH:-true}
      - USER=rstudio
      - USERID=1000
      - GROUPID=1000
    restart: unless-stopped
    stdin_open: true
    tty: true
    shm_size: '2gb'
    deploy:
      resources:
        limits:
          memory: 16G
        reservations:
          memory: 8G
    init: true

volumes:
  rstudio-home:
  rstudio-local:
  rstudio-config:
  rstudio-lib:
EOF

# Step 5: Update Dockerfile to use the proper startup script
echo "Step 5: Updating Dockerfile..."
# Remove any previous startup script additions
sed -i '/startup_fixed.sh/d' Dockerfile 2>/dev/null || true
sed -i '/startup_proper.sh/d' Dockerfile 2>/dev/null || true

# Add the proper startup script before CMD
sed -i '/^CMD/i COPY startup_proper.sh /startup_proper.sh\nRUN chmod +x /startup_proper.sh' Dockerfile

# Update CMD to use the proper script
sed -i 's|CMD \[.*\]|CMD ["/startup_proper.sh"]|' Dockerfile

# Step 6: Build the image
echo "Step 6: Building Docker image (this may take a few minutes)..."
docker-compose build --no-cache

# Step 7: Start the container
echo "Step 7: Starting container..."
docker-compose up -d

# Step 8: Wait for services
echo "Step 8: Waiting for services to initialize (20 seconds)..."
for i in {1..20}; do
    echo -n "."
    sleep 1
done
echo ""

# Step 9: Verify services
echo "Step 9: Verifying services..."
echo ""

# Check RStudio
echo -n "RStudio Server: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8787 2>/dev/null | grep -q "200\|302"; then
    echo "✅ Running at http://localhost:8787"
else
    echo "❌ Not responding"
fi

# Check Jupyter
echo -n "Jupyter Lab: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8888 2>/dev/null | grep -q "200\|302"; then
    echo "✅ Running at http://localhost:8888"
else
    echo "❌ Not responding"
fi

# Check VSCode
echo -n "VSCode: "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200\|302"; then
    echo "✅ Running at http://localhost:8080"
else
    echo "❌ Not responding"
fi

echo ""
echo "Step 10: Container logs (last 20 lines):"
echo "========================================"
docker logs --tail 20 bioinformatics-env

echo ""
echo "✅ Setup complete!"
echo ""
echo "📌 Access your services:"
echo "   RStudio: http://localhost:8787"
echo "   Username: rstudio"
echo "   Password: rstudio"
echo ""
echo "   Jupyter: http://localhost:8888"
echo "   VSCode:  http://localhost:8080"
echo ""
echo "🔍 If you still have issues, check full logs with:"
echo "   docker logs -f bioinformatics-env"
