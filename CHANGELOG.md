# Changelog

## [0.5.0] - 2025-07-09

### Added
- **Package Testing Framework**: Comprehensive testing suite for verifying package installations
  - `test_python_packages.py`: Python package verification script
  - `test_r_packages_flexible.R`: Flexible R package testing with configurable error tolerance
  - `package_test_config.R`: Configuration file for R package testing
  - `test_packages.sh`: Shell script to run all package tests
  - Added test files to Docker build process for immediate verification

### Changed
- **R Package Installation**: Refactored to use dedicated installation script
  - Moved from inline Dockerfile commands to `install_r_packages_v2.R`
  - Improved error handling and package installation reliability
  - Better support for version-specific installations
- **R Package Versions**: Updated multiple packages to latest compatible versions
  - BiocManager: 1.30.22 → 1.30.26
  - data.table: 1.14.10 → 1.17.0
  - knitr: 1.45 → 1.49
  - rmarkdown: 2.25 → 2.29
  - And many more Bioconductor packages updated to version 3.20 compatible releases
- **Docker Build Process**: Streamlined package installation and added verification step
  - Packages are now installed via script rather than inline commands
  - Test files are copied to workspace and run during build
  - Configuration files are preserved in workspace for post-build testing

### Added Scripts
- `install_r_packages_v2.R`: Dedicated R package installation script
- `extract_installed_versions.sh`: Utility to extract installed package versions
- `update_r_packages_versions.R`: Script to update package version information

## [0.4.0] - 2025-07-06

### Added
- **Package Version Pinning**: Implemented comprehensive version pinning for reproducibility
  - Created `pyproject.toml` for Python dependencies with specific versions
  - Created `r-packages.txt` documenting all R package versions
  - Added `VERSIONS.md` documentation for version management
  - Integrated `uv` package manager for faster Python installations
  
### Changed
- **Python Package Management**: Switched from pip to uv for significant speed improvements
  - Replaced multiple pip install commands with single uv install from pyproject.toml
  - Added proper system Python configuration for uv
- **Bioconductor Version**: Updated to version 3.20 (compatible with R 4.4.2)
- **Docker Build Process**: Optimized build with version pinning and faster package installation

### Improved
- **Reproducibility**: All packages now have pinned versions ensuring consistent environments
- **Build Speed**: Using uv reduces Python package installation time significantly
- **Documentation**: Added comprehensive version management documentation

## [0.3.2] - 2025-07-06

### Fixed
- **RStudio Working Directory**: Fixed issue where RStudio was not showing the workspace directory
  - Added `session-default-working-dir` configuration to `/etc/rstudio/rsession.conf`
  - Enhanced `.Rprofile` to automatically set working directory to `/workspace`
  - Created workspace symlink in RStudio home directory for easy navigation
  - RStudio now properly displays and saves files in the `/workspace` directory

## [0.3.1] - 2025-07-06

### Fixed
- **RStudio File Permissions**: Fixed issue where files created in RStudio were not accessible from the host system
  - Updated `startup_proper.sh` to dynamically adjust RStudio user UID/GID to match host user
  - Modified `docker-compose.yml` to use environment variables for USERID and GROUPID
  - Added USERID and GROUPID variables to `.env` and `.env.example` files
  - Files created in RStudio now have proper permissions matching the host user

## [0.3.0] - 2025-06-08

### Added
- **Added more R packages**: ggpubr. rstatix, factominer, factoextra

## [0.2.0] - 2025-06-08

### Fixed
- **RStudio Server Connection Issues**: Fixed "Unable to establish connection" error
- **Permission Errors**: Resolved permission denied errors for `/home/rstudio/.local/share`
- **Jupyter Lab Startup**: Fixed authentication failures and directory creation issues
- **Service Startup Order**: Ensured all services start correctly with proper permissions

### Changed
- **Docker Volumes**: Switched from bind mounts to named volumes for better permission handling
- **Startup Script**: Created `startup_proper.sh` that properly initializes all directories and permissions
- **Container User**: Container now runs as root (required for RStudio Server to function properly)
- **Memory Configuration**: Adjusted default memory limits to be more reasonable (16G/8G)

### Added
- Named volumes for persistent storage:
  - `rstudio-home`: RStudio user home directory
  - `rstudio-local`: Local RStudio data
  - `rstudio-config`: RStudio configuration
  - `rstudio-lib`: RStudio server library data
- Comprehensive startup script that handles all permission setup automatically
- Better error handling and service initialization

### Removed
- `user: "1000:1000"` directive from docker-compose.yml (caused permission issues)
- Manual permission fixes no longer needed

## [0.1.0] - Initial Release

### Features
- RStudio Server with Bioconductor packages
- Jupyter Lab with scientific Python packages
- VSCode Server for code editing
- Quarto for scientific publishing
- Pre-installed bioinformatics packages for R and Python
- Shared workspace directory

### Known Issues (Fixed in 2.0.0)
- RStudio connection errors
- Permission issues with mounted volumes
- Service startup failures
