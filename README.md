# Bioinformatics Environment

🧬 A Docker container for bioinformatics and data science with R/Bioconductor, Python, RStudio Server, Jupyter Lab, VSCode, and Quarto.

## Quick Start

### On Your Server

1. **Clone and deploy:**
```bash
git clone https://github.com/wguesdon/Bioinformatics_env.git
cd Bioinformatics_env
docker-compose up --build -d
```

2. **Access:**
- **RStudio**: http://localhost:8787 (user: `rstudio`, pass: see .env)
- **Jupyter Lab**: http://localhost:8888 (token see .env)
- **VSCode**: http://localhost:8080

Access your services at:
  RStudio: http://localhost:8787 (rstudio/rstudio)
  Jupyter: http://localhost:8888
  VSCode:  http://localhost:8080

## What's Included

- **R 4.3.2** with Bioconductor packages (DESeq2, edgeR, GenomicRanges, etc.)
- **Python 3** with data science stack (pandas, numpy, scikit-learn, etc.)
- **RStudio Server** - Full R IDE
- **Jupyter Lab** - Python/R notebooks
- **VSCode** - Web-based code editor
- **Quarto** - For presentations and reports

## File Storage

All your work is saved in the `workspace/` directory, which persists between container restarts.

## Setup on New Machine

Yes, you're correct! With these files in place, setting up on a new Ubuntu machine is simple:

```bash
# 1. Clone repository
git clone <your-repo-url>
cd bioinformatics-docker

# 2. Create workspace
mkdir -p workspace/{projects,data,notebooks,scripts,presentations}

# 3. Build and start
# docker-compose down # to stop running containers
docker-compose build
docker-compose up -d

# 4. Verify (optional)
chmod +x verify_setup.sh
./verify_setup.sh
```

## Management

```bash
# Stop services
docker-compose down

# Start services  
docker-compose up -d

# View logs
docker-compose logs -f

# Update
git pull && docker-compose up --build -d
```

## Firewall Setup (Ubuntu)

If you can't access from your laptop:

```bash
sudo ufw allow 8787,8888,8080/tcp
```

## Security

For production use, edit the `.env` file to set secure passwords:

```bash
cp .env.example .env
nano .env  # Set your passwords
docker-compose up --build -d
```

## Repository Structure

```bash
bioinformatics-docker/
├── Dockerfile              # Docker image definition (updated version)
├── docker-compose.yml      # Service configuration with named volumes
├── startup_proper.sh       # Container startup script
├── README.md               # Project documentation
├── Installation_guide.md   # Detailed setup instructions
└── verify_setup.sh         # Optional: Setup verification script
```
