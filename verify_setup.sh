#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🔍 Verifying Bioinformatics Docker Environment Setup"
echo "=================================================="
echo ""

# Check if docker is installed
echo -n "Docker installation: "
if command -v docker &> /dev/null; then
    echo -e "${GREEN}✓ Installed ($(docker --version))${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    exit 1
fi

# Check if docker-compose is installed
echo -n "Docker Compose: "
if command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✓ Installed ($(docker-compose --version))${NC}"
else
    echo -e "${RED}✗ Not installed${NC}"
    exit 1
fi

# Check if container is running
echo -n "Container status: "
if docker ps | grep -q bioinformatics-env; then
    echo -e "${GREEN}✓ Running${NC}"
else
    echo -e "${RED}✗ Not running${NC}"
    echo "  Run: docker-compose up -d"
    exit 1
fi

# Check services
echo ""
echo "Checking services:"

# RStudio
echo -n "  RStudio Server (8787): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8787 2>/dev/null | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# Jupyter
echo -n "  Jupyter Lab (8888): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8888 2>/dev/null | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# VSCode
echo -n "  VSCode Server (8080): "
if curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null | grep -q "200\|302"; then
    echo -e "${GREEN}✓ Accessible${NC}"
else
    echo -e "${RED}✗ Not accessible${NC}"
fi

# Check workspace
echo ""
echo -n "Workspace directory: "
if [ -d "./workspace" ]; then
    echo -e "${GREEN}✓ Exists${NC}"
    echo "  Contents:"
    ls -la workspace/ | head -6
else
    echo -e "${RED}✗ Not found${NC}"
fi

# Check volumes
echo ""
echo "Docker volumes:"
docker volume ls | grep -E "(rstudio-home|rstudio-local|rstudio-config|rstudio-lib)" | while read -r line; do
    echo "  ✓ $line"
done

# Memory and disk space
echo ""
echo "System resources:"
echo -n "  Available memory: "
free -h | grep "^Mem:" | awk '{print $7}'
echo -n "  Available disk: "
df -h . | tail -1 | awk '{print $4}'

# Summary
echo ""
echo "================================="
echo "Summary:"
all_good=true

if ! docker ps | grep -q bioinformatics-env; then
    all_good=false
fi

if ! curl -s -o /dev/null -w "%{http_code}" http://localhost:8787 2>/dev/null | grep -q "200\|302"; then
    all_good=false
fi

if $all_good; then
    echo -e "${GREEN}✅ All systems operational!${NC}"
    echo ""
    echo "Access your services at:"
    echo "  RStudio: http://localhost:8787"
    echo "  Jupyter: http://localhost:8888"
    echo "  VSCode:  http://localhost:8080"
else
    echo -e "${YELLOW}⚠️  Some issues detected. Check the output above.${NC}"
    echo ""
    echo "Common fixes:"
    echo "  - Restart services: docker-compose restart"
    echo "  - Check logs: docker-compose logs -f"
    echo "  - Rebuild: docker-compose build --no-cache"
fi

echo "================================="
