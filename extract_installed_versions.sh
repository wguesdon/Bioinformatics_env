#!/bin/bash

# Script to extract installed R package versions from container

echo "Extracting installed R package versions from container..."

# Check if container is running
if ! podman ps | grep -q bioinformatics-env; then
    echo "Container 'bioinformatics-env' is not running. Starting it..."
    podman-compose up -d
    sleep 5
fi

# Copy the update script to the container
podman cp update_r_packages_versions.R bioinformatics-env:/workspace/

# Copy the current r-packages.txt to the container
podman cp r-packages.txt bioinformatics-env:/workspace/

# Find R executable path first
R_PATH=$(podman exec bioinformatics-env sh -c "which R || find /usr -name R -type f 2>/dev/null | grep -E 'bin/R$' | head -1")
RSCRIPT_PATH=$(podman exec bioinformatics-env sh -c "which Rscript || find /usr -name Rscript -type f 2>/dev/null | grep -E 'bin/Rscript$' | head -1")

if [ -z "$RSCRIPT_PATH" ]; then
    echo "Error: Could not find Rscript in the container"
    echo "Checking if R is installed..."
    podman exec bioinformatics-env sh -c "R --version" || echo "R does not appear to be installed"
    exit 1
fi

echo "Found Rscript at: $RSCRIPT_PATH"

# Run the update script in the container
podman exec bioinformatics-env $RSCRIPT_PATH /workspace/update_r_packages_versions.R

# Copy the updated file back
podman cp bioinformatics-env:/workspace/r-packages-updated.txt ./r-packages-updated.txt

echo ""
echo "Updated package list has been saved to: r-packages-updated.txt"
echo ""
echo "To replace the original file, run:"
echo "  mv r-packages-updated.txt r-packages.txt"
echo ""
echo "Or to see the differences first:"
echo "  diff r-packages.txt r-packages-updated.txt"
