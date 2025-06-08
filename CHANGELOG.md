# Changelog

## [2.0.0] - 2025-06-08

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

## [1.0.0] - Initial Release

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
