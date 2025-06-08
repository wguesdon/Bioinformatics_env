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
