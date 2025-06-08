# Quick Reference - Bioinformatics Docker Environment

## 🚀 Access URLs
- **RStudio**: http://localhost:8787 (user: rstudio, password: set in RSTUDIO_PASSWORD)
- **Jupyter**: http://localhost:8888 (token: set in JUPYTER_TOKEN)
- **VSCode**: http://localhost:8080

## 📝 Common Commands

### Container Management
```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Restart services
docker-compose restart

# View status
docker-compose ps

# View logs
docker-compose logs -f
```

### Working Inside Container
```bash
# Enter container shell
docker exec -it bioinformatics-env bash

# Run R command
docker exec bioinformatics-env R -e "print('Hello')"

# Run Python command
docker exec bioinformatics-env python3 -c "print('Hello')"

# Install R package (temporary)
docker exec bioinformatics-env R -e "install.packages('newpackage')"

# Install Python package (temporary)
docker exec bioinformatics-env pip3 install newpackage
```

### File Operations
```bash
# Copy file into container
docker cp myfile.csv bioinformatics-env:/workspace/data/

# Copy file from container
docker cp bioinformatics-env:/workspace/results.csv ./

# Backup workspace
tar -czf workspace_backup_$(date +%Y%m%d).tar.gz workspace/
```

### Troubleshooting
```bash
# Check service logs
docker logs bioinformatics-env

# Check RStudio logs specifically
docker exec bioinformatics-env cat /var/log/rstudio-server/rserver.log

# Fix permissions (if needed)
docker exec bioinformatics-env chown -R rstudio:rstudio /home/rstudio

# Restart RStudio Server
docker exec bioinformatics-env pkill rserver
docker exec bioinformatics-env /usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --server-app-armor-enabled=0 &
```

### Updates and Maintenance
```bash
# Update container with latest packages
docker-compose build --no-cache
docker-compose up -d

# Clean up Docker resources
docker system prune -a  # Warning: removes all unused images

# Check resource usage
docker stats bioinformatics-env
```

## 🔧 Configuration Changes

### Environment Variables
Edit `.env` file:
```bash
RSTUDIO_PASSWORD=your_password
JUPYTER_TOKEN=your_token
DISABLE_AUTH=false  # Set to true to disable authentication
```

### Add R Package Permanently
Edit `Dockerfile`:
```dockerfile
RUN R -e "install.packages('package-name')"
```

### Add Python Package Permanently
Edit `Dockerfile`:
```dockerfile
RUN pip3 install --no-cache-dir --break-system-packages package-name
```

### Change Memory Limits
Edit `docker-compose.yml`:
```yaml
deploy:
  resources:
    limits:
      memory: 32G  # Your limit
```

After any configuration change:
```bash
docker-compose build
docker-compose up -d
```

## 💡 Tips
- Save work frequently - containers can be rebuilt
- Use git for version control inside `/workspace/projects/`
- Export important results outside the container
- Regular backups of `/workspace/` are recommended
- Keep your `.env` file secure and never commit it to version control
