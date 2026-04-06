# Installation Guide

This guide will help you deploy the Bioinformatics Container Environment on your Ubuntu server and access it from your laptop.

## Prerequisites

### Server Requirements
- **OS**: Ubuntu 18.04+ (or other Linux distribution)
- **RAM**: 4GB minimum, 8GB+ recommended
- **Storage**: 20GB+ free space
- **Network**: Accessible from your laptop
- **Ports**: 8787, 8888, 8080 available

### Your Laptop
- Modern web browser (Chrome, Firefox, Safari)
- Network access to server

## Quick Installation (Recommended)

### Option 1: One Line Install
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/Bioinformatics_env/main/deploy.sh | bash
```

### Option 2: Manual Installation
```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/Bioinformatics_env.git
cd Bioinformatics_env

# Run deployment script
./deploy.sh
```

## Detailed Installation Steps

### Step 1: Install Podman (if not already installed)

```bash
# Update package index
sudo apt update

# Install Podman
sudo apt install -y podman

# Verify installation
podman --version
```

### Step 2: Install podman-compose

```bash
# Install podman-compose via pip (user level)
pip install --user podman-compose

# Or using pipx
pipx install podman-compose

# Verify installation
podman-compose --version
```

### Step 3: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/Bioinformatics_env.git
cd Bioinformatics_env

# Create workspace directory
mkdir -p workspace/{projects,data,notebooks,scripts,presentations}

# Copy environment template (optional for development)
cp .env.example .env
```

### Step 4: Configure Firewall

```bash
# Check if firewall is active
sudo ufw status

# If active, allow the required ports
sudo ufw allow 8787/tcp comment "RStudio Server"
sudo ufw allow 8888/tcp comment "Jupyter Lab"
sudo ufw allow 8080/tcp comment "VSCode Server"
```

### Step 5: Deploy the Environment

#### Development Deployment (No Authentication)
```bash
# Build and start services
podman-compose up --build -d

# Check status
podman-compose ps
```

#### Production Deployment (With Authentication)
```bash
# Edit environment file with secure passwords
nano .env

# Deploy
podman-compose up --build -d
```

## Accessing from Your Laptop

Once deployed on your server (IP: 192.168.2.140), open these URLs in your laptop browser:

| Service | URL | Description |
|---------|-----|-------------|
| **RStudio Server** | `http://192.168.2.140:8787` | R IDE with Bioconductor |
| **Jupyter Lab** | `http://192.168.2.140:8888` | Python/R notebooks |
| **VSCode** | `http://192.168.2.140:8080` | Web based code editor |

### Login Information

**Development Mode (default):**
- RStudio: Username `rstudio`, Password `rstudio`
- Jupyter: No password required
- VSCode: No password required

**Production Mode:**
- Passwords as configured in your `.env` file

## Security Configuration

### For Local Network Use
The default configuration is suitable for trusted local networks:

```yaml
# In docker-compose.yml
environment:
  - DISABLE_AUTH=true
```

### For Production Use
Edit `.env` file:

```bash
# Security settings
DISABLE_AUTH=false
RSTUDIO_PASSWORD=your-secure-password
JUPYTER_TOKEN=your-secure-token
VSCODE_PASSWORD=your-secure-password
```

Then deploy with:
```bash
podman-compose up --build -d
```

## File Management

### Workspace Structure
```
workspace/
├── projects/       # Your data science projects
├── data/          # Datasets
├── notebooks/     # Jupyter notebooks
├── scripts/       # R and Python scripts
└── presentations/ # Quarto presentations
```

### Persistent Storage
- All files in `workspace/` persist between container restarts
- RStudio settings saved in `home/` directory
- Jupyter settings and kernels preserved

## Management Commands

### Daily Operations
```bash
# View service status
podman-compose ps

# View logs
podman-compose logs -f

# Restart services
podman-compose restart

# Stop services
podman-compose down

# Start services
podman-compose up -d
```

### Maintenance
```bash
# Access container shell
podman exec -it bioinformatics-env bash
```

## Troubleshooting

### Services Won't Start

1. **Check port conflicts:**
```bash
sudo netstat -tlnp | grep -E ':(8787|8888|8080)'
```

2. **Check container status:**
```bash
podman-compose logs
```

3. **Verify firewall:**
```bash
sudo ufw status verbose
```

### Can't Access from Laptop

1. **Test server connectivity:**
```bash
# From laptop
ping 192.168.2.140
telnet 192.168.2.140 8787
```

2. **Check if services are listening:**
```bash
# On server
sudo netstat -tlnp | grep -E ':(8787|8888|8080)'
```

3. **Verify container port binding:**
```bash
podman port bioinformatics-env
```

### Memory Issues

1. **Check available memory:**
```bash
free -h
podman stats
```

2. **Increase swap if needed:**
```bash
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Permission Problems

1. **Fix workspace permissions:**
```bash
sudo chown -R $USER:$USER workspace/
```

2. **Fix Podman permissions (rootless):**
Podman runs rootless by default. If you encounter permission issues, check your subuid/subgid mappings:
```bash
cat /etc/subuid
cat /etc/subgid
```

## Regular Maintenance

### Weekly
- Check `podman-compose logs` for errors
- Monitor disk space: `df -h`

### Monthly
- Clean old container images: `podman system prune`
- Review and update packages in Containerfile if needed

## Verification Checklist

After installation, verify:

- [ ] Podman and podman-compose installed
- [ ] Repository cloned and workspace created
- [ ] Firewall configured (if applicable)
- [ ] Containers built and running
- [ ] Can access RStudio from laptop browser
- [ ] Can access Jupyter from laptop browser  
- [ ] Can access VSCode from laptop browser
- [ ] Files saved in workspace persist
- [ ] R packages load correctly
- [ ] Python packages import successfully
- [ ] Quarto renders presentations

## Next Steps

1. **Customize environment:** Add your favorite packages to Containerfile
2. **Set up projects:** Create project directories in workspace
3. **Configure backups:** Set up automated backups
4. **Explore integrations:** Use R Python integration features
5. **Create presentations:** Start with Quarto examples
