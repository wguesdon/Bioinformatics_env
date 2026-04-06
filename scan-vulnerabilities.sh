#!/bin/bash
# Local vulnerability scan using Trivy
# Scans the container image, Containerfile, and Python dependencies
#
# Prerequisites: trivy installed (https://trivy.dev)
#   Install: curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
#
# Usage:
#   ./scan-vulnerabilities.sh          # Scan everything
#   ./scan-vulnerabilities.sh image    # Scan container image only
#   ./scan-vulnerabilities.sh config   # Scan Containerfile only
#   ./scan-vulnerabilities.sh deps     # Scan Python dependencies only

set -e

SEVERITY="CRITICAL,HIGH"
IMAGE_NAME="bioinformatics-env:scan"

if ! command -v trivy &> /dev/null; then
    echo "Error: trivy is not installed."
    echo "Install it with:"
    echo "  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b ~/.local/bin"
    exit 1
fi

scan_config() {
    echo ""
    echo "=== Scanning Containerfile and configuration ==="
    echo ""
    trivy config --severity "$SEVERITY" .
}

scan_deps() {
    echo ""
    echo "=== Scanning Python dependencies ==="
    echo ""
    trivy fs --severity "$SEVERITY" --scanners vuln .
}

scan_image() {
    echo ""
    echo "=== Building container image ==="
    echo ""
    podman build -f Containerfile -t "$IMAGE_NAME" .

    echo ""
    echo "=== Scanning container image ==="
    echo ""
    trivy image --severity "$SEVERITY" "$IMAGE_NAME"
}

MODE="${1:-all}"

case "$MODE" in
    config)
        scan_config
        ;;
    deps)
        scan_deps
        ;;
    image)
        scan_image
        ;;
    all)
        scan_config
        scan_deps
        scan_image
        ;;
    *)
        echo "Usage: $0 [config|deps|image|all]"
        exit 1
        ;;
esac

echo ""
echo "Scan complete."
