#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Function to check if a command is available
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if dpkg is available, if not, try to install it
if ! command_exists dpkg; then
    echo "dpkg is not installed. Attempting to install it..."
    if command_exists apt-get; then
        apt-get update && apt-get install -y dpkg
    elif command_exists yum; then
        yum install -y dpkg
    else
        echo "Unable to install dpkg. No supported package manager found."
        exit 1
    fi
fi

# Function to check if a package is installed
package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

# Function to check if a Python package is installed
python_package_installed() {
    pip show "$1" >/dev/null 2>&1
}

# Update package lists
apt-get update

# List of required system packages
packages=(
    "libglib2.0-0"
    "cmake"
    "build-essential"
    "libopenblas-dev"
    "liblapack-dev"
    "libx11-dev"
    "libgtk-3-dev"
    "libgl1-mesa-glx"
)

# Install system packages if not already installed
for package in "${packages[@]}"; do
    if ! package_installed "$package"; then
        echo "Installing $package..."
        apt-get install -y "$package"
    else
        echo "$package is already installed."
    fi
done

# Set Python user base to home directory to persist installations
export PYTHONUSERBASE=$HOME/.local

# Install Python packages if not already installed
python_packages=(
    "dlib"
    "face-recognition"
)

for package in "${python_packages[@]}"; do
    if ! python_package_installed "$package"; then
        echo "Installing $package..."
        pip install --user "$package"
    else
        echo "$package is already installed."
    fi
done

# Update PATH and LD_LIBRARY_PATH to include user base directories
export PATH=$PYTHONUSERBASE/bin:$PATH
export LD_LIBRARY_PATH=$PYTHONUSERBASE/lib:$LD_LIBRARY_PATH

# Start the Flask app
gunicorn --bind=0.0.0.0 --timeout 1800 app:app
