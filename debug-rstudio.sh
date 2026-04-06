#!/bin/bash
# RStudio Server Debug Script

echo "Debugging RStudio Server..."

# Check if container is running
echo -e "\n1. Container Status:"
podman ps | grep bioinformatics-env

# Check RStudio process inside container
echo -e "\n2. RStudio Process Status:"
podman exec bioinformatics-env ps aux | grep rserver

# Check RStudio logs
echo -e "\n3. RStudio Server Logs:"
podman exec bioinformatics-env cat /var/log/rstudio-server/rserver.log 2>/dev/null || echo "No log file found"

# Check RStudio configuration
echo -e "\n4. RStudio Configuration:"
podman exec bioinformatics-env cat /etc/rstudio/rserver.conf

# Check if RStudio port is listening
echo -e "\n5. Port Status:"
podman exec bioinformatics-env netstat -tlnp | grep 8787 || echo "Port 8787 not listening"

# Check container logs for errors
echo -e "\n6. Container Logs (last 50 lines):"
podman logs --tail 50 bioinformatics-env 2>&1 | grep -E "(error|Error|ERROR|fail|Failed|FAILED)"

# Check memory usage
echo -e "\n7. Memory Usage:"
podman stats bioinformatics-env --no-stream

# Test RStudio HTTP response
echo -e "\n8. Testing HTTP Response:"
curl -I http://localhost:8787 2>/dev/null || echo "Failed to get HTTP response"
