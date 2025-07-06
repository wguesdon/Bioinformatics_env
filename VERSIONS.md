# Package Version Management

This document describes how package versions are managed in the Bioinformatics Docker Environment for reproducibility.

## Overview

To ensure reproducible builds, all package versions are now pinned:
- Python packages are managed using `uv` with versions specified in `pyproject.toml`
- R packages have versions listed in `r-packages.txt`
- Base image uses specific R version: `rocker/verse:4.4.2`

## Python Packages

Python dependencies are defined in `pyproject.toml` and installed using `uv` for fast, reliable installation.

Key packages:
- JupyterLab 4.0.9
- NumPy 1.26.2
- Pandas 2.1.4
- Scikit-learn 1.3.2

To update Python packages:
1. Edit `pyproject.toml` with new versions
2. Rebuild the Docker image

## R Packages

R packages are installed with specific Bioconductor version 3.20 (compatible with R 4.4.2).

Key packages:
- Tidyverse 2.0.0
- DESeq2 1.42.0
- Seurat 5.0.1
- ComplexHeatmap 2.18.0

Package versions are documented in `r-packages.txt` for reference.

## Updating Package Versions

### Testing New Versions
1. Create a new branch
2. Update versions in `pyproject.toml` or Dockerfile
3. Build and test thoroughly
4. Submit PR with test results

### Version Compatibility
- Always check R/Bioconductor version compatibility
- Test Python/R integration with rpy2
- Verify Jupyter kernels work correctly

## Lockfile Generation

For even stricter reproducibility, you can generate lockfiles:

### Python (using uv)
```bash
# Inside container
cd /tmp
uv pip compile pyproject.toml -o requirements.lock
```

### R (using renv)
```R
# Inside R session
install.packages("renv")
renv::init()
renv::snapshot()
```

## Version History

See CHANGELOG.md for version update history.