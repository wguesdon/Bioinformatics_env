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

2. **Access the tools:**

| Tool | URL | Username | Password/Token |
|------|-----|----------|----------------|
| **RStudio** | http://localhost:8787 | `rstudio` | `rstudio` (or value in `.env`) |
| **Jupyter Lab** | http://localhost:8888 | N/A | `jupyter` (or value in `.env`) |
| **VSCode** | http://localhost:8080 | N/A | No authentication |

Default credentials (change in `.env` file for security):
- RStudio password: `rstudio`
- Jupyter token: `jupyter`

## What's Included

- **R 4.4.2** with Bioconductor packages (DESeq2, edgeR, GenomicRanges, etc.)
- **Python 3** with data science stack (pandas, numpy, scikit-learn, etc.)
- **RStudio Server** - Full R IDE
- **Jupyter Lab** - Python/R notebooks
- **VSCode** - Web-based code editor
- **Quarto** - For presentations and reports

All packages have pinned versions for reproducibility. See `VERSIONS.md` for details.

## Package Version Management

For reproducible environments, all package versions are explicitly pinned:

- **Python packages**: Defined in `pyproject.toml` and installed using `uv` (ultrafast Python package installer)
  - Example: `numpy==1.26.2`, `pandas==2.1.4`, `jupyterlab==4.0.9`
  - Python version is determined by the base Docker image
  
- **R packages**: Listed with versions in `r-packages.txt`
  - Example: `tidyverse@2.0.0`, `DESeq2@1.42.0`, `Seurat@5.0.1`
  - R version 4.4.2 is provided by the `rocker/verse:4.4.2` base image
  - Bioconductor version 3.20 (compatible with R 4.4.2)

To see all package versions or update them, check:
- `pyproject.toml` for Python packages
- `r-packages.txt` for R packages
- `VERSIONS.md` for detailed version management documentation

## File Storage

All your work is saved in the `workspace/` directory, which persists between container restarts.

## Setup on New Machine

```bash
# 1. Clone repository
git clone git@github.com:wguesdon/Bioinformatics_env.git
cd Bioinformatics_env

# 2. Create workspace
mkdir -p workspace/{projects,data,notebooks,scripts,presentations}

# 3. Build and start
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
nano .env  # Set your passwords and tokens
```

Required environment variables:
- `RSTUDIO_PASSWORD`: Password for RStudio Server
- `JUPYTER_TOKEN`: Token for Jupyter Lab access
- `DISABLE_AUTH`: Set to "false" to enable authentication

After setting up the .env file:
```bash
docker-compose up --build -d
```

## Repository Structure

```bash
bioinformatics-docker/
├── Dockerfile              # Docker image definition
├── docker-compose.yml      # Service configuration
├── startup_proper.sh       # Container startup script
├── README.md               # Project documentation
├── QUICK_REFERENCE.md      # Quick reference guide
├── CHANGELOG.md            # Version history
├── Installation_guide.md   # Detailed setup instructions
├── verify_setup.sh         # Setup verification script
├── debug-rstudio.sh        # RStudio debugging tool
├── deploy.sh               # Deployment script
└── workspace/              # Your working directory
```
