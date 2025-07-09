#!/bin/bash

# Main test runner script to verify all package installations

set -e

echo "======================================================================"
echo "                    Package Version Verification Tests                 "
echo "======================================================================"
echo ""

# Track overall test status
OVERALL_STATUS=0

# Determine the correct path for test scripts
if [ -f "/workspace/test_python_packages.py" ]; then
    PYTHON_TEST="/workspace/test_python_packages.py"
else
    PYTHON_TEST="test_python_packages.py"
fi

if [ -f "/workspace/test_r_packages.R" ]; then
    R_TEST="/workspace/test_r_packages.R"
else
    R_TEST="test_r_packages.R"
fi

# Run Python package tests
echo "Running Python package tests..."
echo ""
if python3 $PYTHON_TEST; then
    PYTHON_STATUS=0
    echo ""
    echo "✅ Python package tests PASSED"
else
    PYTHON_STATUS=1
    echo ""
    echo "❌ Python package tests FAILED"
    OVERALL_STATUS=1
fi

echo ""
echo "----------------------------------------------------------------------"
echo ""

# Run R package tests
echo "Running R package tests..."
echo ""
if Rscript $R_TEST; then
    R_STATUS=0
    echo ""
    echo "✅ R package tests PASSED"
else
    R_STATUS=1
    echo ""
    echo "❌ R package tests FAILED"
    OVERALL_STATUS=1
fi

echo ""
echo "======================================================================"
echo "                           Test Summary                               "
echo "======================================================================"
echo ""

if [ $PYTHON_STATUS -eq 0 ]; then
    echo "✅ Python packages: ALL TESTS PASSED"
else
    echo "❌ Python packages: TESTS FAILED"
fi

if [ $R_STATUS -eq 0 ]; then
    echo "✅ R packages: ALL TESTS PASSED"
else
    echo "❌ R packages: TESTS FAILED"
fi

echo ""
echo "======================================================================"

if [ $OVERALL_STATUS -eq 0 ]; then
    echo "✅ OVERALL: ALL TESTS PASSED"
    echo "======================================================================"
    exit 0
else
    echo "❌ OVERALL: SOME TESTS FAILED"
    echo "======================================================================"
    exit 1
fi