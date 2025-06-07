# Bioinformatics Environment

🧬 A Docker container for bioinformatics and data science with R/Bioconductor, Python, RStudio Server, Jupyter Lab, VSCode, and Quarto.

## Quick Start

### On Your Server (192.168.2.140)

1. **Clone and deploy:**
```bash
git clone https://github.com/wguesdon/Bioinformatics_env.git
cd Bioinformatics_env
docker-compose up --build -d
```

2. **Access from your laptop:**
- **RStudio**: http://192.168.2.140:8787 (user: `rstudio`, pass: `rstudio`)
- **Jupyter Lab**: http://192.168.2.140:8888
- **VSCode**: http://192.168.2.140:8080

## What's Included

- **R 4.3.2** with Bioconductor packages (DESeq2, edgeR, GenomicRanges, etc.)
- **Python 3** with data science stack (pandas, numpy, scikit-learn, etc.)
- **RStudio Server** - Full R IDE
- **Jupyter Lab** - Python/R notebooks
- **VSCode** - Web-based code editor
- **Quarto** - For presentations and reports

## File Storage

All your work is saved in the `workspace/` directory, which persists between container restarts.

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
