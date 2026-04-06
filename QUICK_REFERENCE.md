# Quick Reference - Bioinformatics Container Environment

## Access URLs
- **RStudio**:  http://localhost:8787 (user: rstudio, password: set in RSTUDIO_PASSWORD)
- **Jupyter**:  http://localhost:8888 (token: set in JUPYTER_TOKEN)
- **VSCode**:   http://localhost:8080

## Common Commands

### Container Management
```bash
# Start services
podman-compose up -d

# Stop services
podman-compose down

# Restart services
podman-compose restart

# View status
podman-compose ps

# View logs
podman-compose logs -f
```

### Working Inside Container
```bash
# Enter container shell
podman exec -it bioinformatics-env bash

# Run R command
podman exec bioinformatics-env R -e "print('Hello')"

# Run Python command
podman exec bioinformatics-env python3 -c "print('Hello')"

# Install R package (temporary)
podman exec bioinformatics-env R -e "install.packages('newpackage')"

# Install Python package (temporary)
podman exec bioinformatics-env pip3 install newpackage
```

### File Operations
```bash
# Copy file into container
podman cp myfile.csv bioinformatics-env:/workspace/data/

# Copy file from container
podman cp bioinformatics-env:/workspace/results.csv ./

# Backup workspace
tar -czf workspace_backup_$(date +%Y%m%d).tar.gz workspace/
```

### Troubleshooting
```bash
# Check service logs
podman logs bioinformatics-env

# Check RStudio logs specifically
podman exec bioinformatics-env cat /var/log/rstudio-server/rserver.log

# Fix permissions (if needed)
podman exec bioinformatics-env chown -R rstudio:rstudio /home/rstudio

# Restart RStudio Server
podman exec bioinformatics-env pkill rserver
podman exec bioinformatics-env /usr/lib/rstudio-server/bin/rserver --server-daemonize=0 --server-app-armor-enabled=0 &
```

### Updates and Maintenance
```bash
# Update container with latest packages
podman-compose build --no-cache
podman-compose up -d

# Clean up container resources
podman system prune -a  # Warning: removes all unused images

# Check resource usage
podman stats bioinformatics-env
```

## Configuration Changes

### Environment Variables
Edit `.env` file:
```bash
RSTUDIO_PASSWORD=your_password
JUPYTER_TOKEN=your_token
DISABLE_AUTH=false  # Set to true to disable authentication
```

### Add R Package Permanently
Edit `Containerfile`:
```dockerfile
RUN R -e "install.packages('package-name')"
```

### Add Python Package Permanently
Edit `Containerfile`:
```dockerfile
RUN pip3 install --no-cache-dir --break-system-packages package-name
```

### Change Memory Limits
Memory limits can be set via environment variables or podman run flags.

After any configuration change:
```bash
podman-compose build
podman-compose up -d
```

## Tips
- Save work frequently. Containers can be rebuilt.
- Use git for version control inside `/workspace/projects/`
- Export important results outside the container
- Regular backups of `/workspace/` are recommended
- Keep your `.env` file secure and never commit it to version control
