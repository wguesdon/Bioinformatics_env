# Installation Guide

This guide will help you deploy the DataScience Docker Environment on your Ubuntu server and access it from your laptop.

## 📋 Prerequisites

### Server Requirements
- **OS**: Ubuntu 18.04+ (or other Docker-compatible Linux)
- **RAM**: 4GB minimum, 8GB+ recommended
- **Storage**: 20GB+ free space
- **Network**: Accessible from your laptop
- **Ports**: 8787, 8888, 8080 available

### Your Laptop
- Modern web browser (Chrome, Firefox, Safari)
- Network access to server

## 🚀 Quick Installation (Recommended)

### Option 1: One-Line Install
```bash
curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/datascience-docker-env/main/scripts/deploy.sh | bash
```

### Option 2: Manual Installation
```bash
# Clone repository
git clone https://github.com/YOUR_USERNAME/datascience-docker-env.git
cd datascience-docker-env

# Run deployment script
./scripts/deploy.sh
```

## 🔧 Detailed Installation Steps

### Step 1: Install Docker (if not already installed)

```bash
# Update package index
sudo apt update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or run:
newgrp docker

# Verify installation
docker --version
```

### Step 2: Install Docker Compose

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

### Step 3: Clone and Configure

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/datascience-docker-env.git
cd datascience-docker-env

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
docker-compose up --build -d

# Check status
docker-compose ps
```

#### Production Deployment (With Authentication)
```bash
# Edit environment file with secure passwords
nano .env

# Deploy with production configuration
docker-compose -f docker-compose.prod.yml up --build -d
```

## 🌐 Accessing from Your Laptop

Once deployed on your server (IP: 192.168.2.140), open these URLs in your laptop browser:

| Service | URL | Description |
|---------|-----|-------------|
| **RStudio Server** | `http://192.168.2.140:8787` | R IDE with Bioconductor |
| **Jupyter Lab** | `http://192.168.2.140:8888` | Python/R notebooks |
| **VSCode** | `http://192.168.2.140:8080` | Web-based code editor |

### Login Information

**Development Mode (default):**
- RStudio: Username `rstudio`, Password `rstudio`
- Jupyter: No password required
- VSCode: No password required

**Production Mode:**
- Passwords as configured in your `.env` file

## 🔒 Security Configuration

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
docker-compose -f docker-compose.prod.yml up --build -d
```

## 📁 File Management

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

## 🛠️ Management Commands

### Daily Operations
```bash
# View service status
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Start services
docker-compose up -d
```

### Maintenance
```bash
# Update environment
./scripts/update.sh

# Backup workspace
./scripts/backup.sh

# Access container shell
docker exec -it datascience-env bash
```

## 🚨 Troubleshooting

### Services Won't Start

1. **Check port conflicts:**
```bash
sudo netstat -tlnp | grep -E ':(8787|8888|8080)'
```

2. **Check Docker status:**
```bash
docker-compose logs
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

3. **Verify Docker port binding:**
```bash
docker port datascience-env
```

### Memory Issues

1. **Check available memory:**
```bash
free -h
docker stats
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

2. **Fix Docker permissions:**
```bash
sudo usermod -aG docker $USER
newgrp docker
```

## 🔄 Regular Maintenance

### Weekly
- Check `docker-compose logs` for errors
- Run `./scripts/backup.sh` to backup workspace
- Monitor disk space: `df -h`

### Monthly
- Run `./scripts/update.sh` to update environment
- Clean old Docker images: `docker system prune`
- Review and update packages in Dockerfile if needed

### Backups
```bash
# Manual backup
./scripts/backup.sh

# Restore from backup
tar -xzf backups/datascience_backup_YYYYMMDD_HHMMSS.tar.gz
docker-compose down && docker-compose up -d
```

## 📞 Getting Help

1. **Check documentation:** Review README.md and this guide
2. **View logs:** `docker-compose logs -f`
3. **GitHub issues:** Report problems on the repository
4. **Community:** Check Docker and R/Python communities

## ✅ Verification Checklist

After installation, verify:

- [ ] Docker and Docker Compose installed
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

## 🎯 Next Steps

1. **Customize environment:** Add your favorite packages to Dockerfile
2. **Set up projects:** Create project directories in workspace
3. **Configure backups:** Set up automated backups
4. **Explore integrations:** Use R-Python integration features
5. **Create presentations:** Start with Quarto examples

---

🎉 **Congratulations!** Your DataScience Docker Environment is ready for productive data science work!
