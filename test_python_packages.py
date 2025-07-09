#!/usr/bin/env python3
"""
Unit tests to verify Python package versions match pyproject.toml
"""

import sys
import importlib.metadata
import tomllib
from pathlib import Path

def parse_pyproject():
    """Parse pyproject.toml and extract package requirements"""
    # Try multiple locations for pyproject.toml
    possible_paths = [
        Path("/tmp/pyproject.toml"),  # During Docker build
        Path(__file__).parent / "pyproject.toml",  # In workspace
        Path("pyproject.toml")  # Current directory
    ]
    
    pyproject_path = None
    for path in possible_paths:
        if path.exists():
            pyproject_path = path
            break
    
    if not pyproject_path:
        raise FileNotFoundError("Could not find pyproject.toml in any expected location")
    
    with open(pyproject_path, "rb") as f:
        data = tomllib.load(f)
    
    dependencies = data["project"]["dependencies"]
    
    # Parse package names and versions from dependency strings
    packages = {}
    for dep in dependencies:
        # Remove comments
        dep = dep.split("#")[0].strip()
        if not dep:
            continue
            
        # Parse package==version format
        if "==" in dep:
            name, version = dep.split("==")
            packages[name.strip()] = version.strip()
        else:
            # Handle other version specifiers if needed
            print(f"Warning: Skipping non-exact version specifier: {dep}")
    
    return packages

def get_installed_version(package_name):
    """Get the installed version of a package"""
    try:
        # Handle package name mappings
        import_name = package_name
        if package_name == "scikit-learn":
            import_name = "scikit_learn"
        
        return importlib.metadata.version(import_name)
    except importlib.metadata.PackageNotFoundError:
        return None

def test_python_packages():
    """Test that all Python packages are installed with correct versions"""
    print("=" * 60)
    print("Testing Python Package Versions")
    print("=" * 60)
    
    expected_packages = parse_pyproject()
    
    failed_tests = []
    passed_tests = []
    
    for package, expected_version in expected_packages.items():
        installed_version = get_installed_version(package)
        
        if installed_version is None:
            failed_tests.append({
                'package': package,
                'expected': expected_version,
                'actual': 'NOT INSTALLED',
                'status': 'MISSING'
            })
            print(f"❌ {package}: NOT INSTALLED (expected {expected_version})")
        elif installed_version != expected_version:
            failed_tests.append({
                'package': package,
                'expected': expected_version,
                'actual': installed_version,
                'status': 'VERSION MISMATCH'
            })
            print(f"❌ {package}: {installed_version} (expected {expected_version})")
        else:
            passed_tests.append(package)
            print(f"✅ {package}: {installed_version}")
    
    print("\n" + "=" * 60)
    print(f"Summary: {len(passed_tests)} passed, {len(failed_tests)} failed")
    print("=" * 60)
    
    if failed_tests:
        print("\nFailed tests:")
        for failure in failed_tests:
            print(f"  - {failure['package']}: {failure['status']}")
            print(f"    Expected: {failure['expected']}")
            print(f"    Actual: {failure['actual']}")
    
    return len(failed_tests) == 0

if __name__ == "__main__":
    success = test_python_packages()
    sys.exit(0 if success else 1)