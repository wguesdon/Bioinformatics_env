# Rstudio server

When connecting receiving an error message. Seems to be caused by permission issues. 

Testing modification of the docker compose file. 


```bash
# Stop and clean up
docker-compose down
sudo rm -rf ./home
docker volume prune -f

# Build fresh with the new configuration
docker-compose build --no-cache

# Start the services
docker-compose up -d

# Wait for services to initialize
sleep 15

# Check the status
docker-compose ps
docker logs bioinformatics-env
```

still getting permission issues try the quick fix below

```bash
# Fix permissions in the running container
docker exec -u root bioinformatics-env bash -c '
mkdir -p /home/rstudio/.local/share/jupyter/runtime
mkdir -p /home/rstudio/.local/share/rstudio
mkdir -p /home/rstudio/.jupyter
chown -R rstudio:rstudio /home/rstudio
chmod -R 755 /home/rstudio/.local

# Restart Jupyter as rstudio user
pkill jupyter || true
su -c "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace" rstudio &
'
```

This did not work trying the more complete script

```bash 
# 1. Stop and clean everything
docker-compose down
docker volume prune -f

# 2. Create the fixed startup script
cat > startup_fixed.sh << 'EOF'
#!/bin/bash
set -e
echo "Creating directories..."
mkdir -p /home/rstudio/.local/share/jupyter/runtime
mkdir -p /home/rstudio/.local/share/rstudio
mkdir -p /home/rstudio/.jupyter
mkdir -p /var/lib/rstudio-server

echo "Setting permissions..."
chown -R rstudio:rstudio /home/rstudio
chmod -R 755 /home/rstudio/.local

echo "Starting RStudio Server..."
/usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --server-app-armor-enabled=0 &

echo "Starting Jupyter Lab..."
su -c "jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --notebook-dir=/workspace" rstudio &

echo "Starting VSCode..."
su -c "code-server --bind-addr 0.0.0.0:8080 --auth none /workspace" rstudio &

echo "All services started!"
tail -f /dev/null
EOF

chmod +x startup_fixed.sh

# 3. Update Dockerfile to use the fixed script
echo "COPY startup_fixed.sh /startup_fixed.sh
RUN chmod +x /startup_fixed.sh
CMD [\"/startup_fixed.sh\"]" >> Dockerfile

# 4. Build and run
docker-compose build
docker-compose up -d
```