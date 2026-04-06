# Bioinformatics Environment

A container for bioinformatics and data science with R/Bioconductor, Python, RStudio Server, Jupyter Lab, VSCode, and Quarto.

> **Development Platform**: This container was developed and tested on Ubuntu 24.04.2 LTS. Cross platform support for macOS (including Apple Silicon) and Windows is in progress and currently being tested.

## Quick Start

### On Your Server

#### Option 1: Using podman-compose

```bash
git clone https://github.com/wguesdon/Bioinformatics_env.git
cd Bioinformatics_env
cp .env.example .env   # Edit .env to set passwords
podman-compose up --build -d
```

#### Option 2: Using podman run

```bash
# Build the image
podman build -f Containerfile -t bioinformatics-env .

# Run the container
podman run -d --restart unless-stopped --name bioinformatics-env \
  -p 8787:8787 -p 8888:8888 -p 8080:8080 \
  -v ./workspace:/workspace \
  -e RSTUDIO_PASSWORD=your_password \
  -e JUPYTER_TOKEN=your_token \
  -e USERID=$(id -u) \
  -e GROUPID=$(id -g) \
  --shm-size=2g \
  --init \
  bioinformatics-env
```

### Access the tools

| Tool | URL | Username | Password/Token |
|------|-----|----------|----------------|
| **RStudio** | http://localhost:8787 | `rstudio` | `Bioinfo2026` (or value in `.env`) |
| **Jupyter Lab** | http://localhost:8888 | N/A | `Bioinfo2026` (or value in `.env`) |
| **VSCode** | http://localhost:8080 | N/A | No authentication |

To access from another machine on the network, replace `localhost` with the server IP (e.g. `http://192.168.x.x:8787`).

## Platform Specific Setup

### Linux
```bash
# Copy the Linux-specific environment file
cp .env.example.linux .env
# Get your user and group IDs
echo "USERID=$(id -u)" >> .env
echo "GROUPID=$(id -g)" >> .env
```

### macOS (including Apple Silicon M1/M2/M3/M4)
```bash
# Copy the macOS-specific environment file
cp .env.example.macos .env
# Get your user and group IDs (usually 501:20 on macOS)
echo "USERID=$(id -u)" >> .env
echo "GROUPID=$(id -g)" >> .env
```

### Windows
```powershell
# Copy the Windows-specific environment file
copy .env.example.windows .env
# No need to modify USERID/GROUPID - Podman handles permissions
```

**Note for Windows users**:
- Ensure Podman is running
- Use PowerShell or WSL2 for better compatibility
- Line endings in scripts are LF (Unix style)

## What's Included

### R (120+ packages)
- **R 4.4.2** with Bioconductor 3.20
- RNA-seq: DESeq2, edgeR, limma
- Single cell: Seurat 5.3, scater, scran, MAST, slingshot
- Genomics: GenomicRanges, Biostrings, Rsamtools, rtracklayer, VariantAnnotation
- Enrichment: clusterProfiler, enrichplot, fgsea, ReactomePA, pathview
- Epigenomics: ChIPseeker, DiffBind, methylKit
- Visualization: ComplexHeatmap, ggplot2, plotly, pheatmap
- Modeling: tidymodels, caret, glmnet, xgboost, randomForest

### Python
- **Python 3.12** with bioinformatics and data science stack
- Bioinformatics: biopython, pysam, anndata, scanpy, pyranges
- Scientific computing: numpy, pandas, scipy, statsmodels, scikit-learn
- Visualization: matplotlib, seaborn, plotly, bokeh, altair
- Data formats: h5py (HDF5 support)
- R integration: rpy2

### Development Tools
- **RStudio Server** - Full R IDE
- **Jupyter Lab** - Python/R notebooks with IRkernel
- **VSCode** (code-server 4.114.0) - Web based code editor
- **Quarto** (1.9.36, checksum verified) - For presentations and reports

All packages have pinned versions for reproducibility. See `VERSIONS.md` for details.

## Package Version Management

For reproducible environments, all package versions are explicitly pinned:

- **Python packages**: Defined in `pyproject.toml` and installed using `uv`
  - Example: `numpy==1.26.2`, `pandas==2.1.4`, `scanpy==1.10.4`
  - Python 3.12 is provided by the base container image
  
- **R packages**: Listed with versions in `r-packages.txt`
  - Example: `tidyverse@2.0.0`, `DESeq2@1.46.0`, `Seurat@5.3.0`
  - R 4.4.2 via `rocker/verse:4.4.2` base image
  - Bioconductor version 3.20 (compatible with R 4.4.2)

- **Tools**: Quarto and code-server are pinned with checksum verification in the Containerfile

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
podman-compose build
podman-compose up -d

# 4. Verify (optional)
chmod +x verify_setup.sh
./verify_setup.sh
```

## Management

```bash
# Stop services
podman-compose down

# Start services  
podman-compose up -d

# View logs
podman-compose logs -f

# Update
git pull && podman-compose up --build -d
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
podman-compose up --build -d
```

## Repository Structure

```bash
bioinformatics-env/
├── Containerfile           # Container image definition
├── docker-compose.yml      # Service configuration (podman-compose compatible)
├── pyproject.toml          # Python package versions
├── r-packages.txt          # R package versions
├── install_r_packages_v2.R # R package installation script
├── startup_proper.sh       # Container startup script
├── README.md               # Project documentation
├── QUICK_REFERENCE.md      # Quick reference guide
├── CHANGELOG.md            # Version history
├── Installation_guide.md   # Detailed setup instructions
├── VERSIONS.md             # Version management docs
├── verify_setup.sh         # Setup verification script
├── debug-rstudio.sh        # RStudio debugging tool
├── deploy.sh               # Deployment script
└── workspace/              # Your working directory
```
