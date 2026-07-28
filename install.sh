#!/bin/bash

# vpm-tree.vim installation script
# This script builds the CLI binary and installs the Vim plugin

set -e

BINARY_NAME="vpm-tree"
BIN_DIR="bin"

echo "========================================="
echo "  vpm-tree.vim Installation"
echo "========================================="
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed"
    echo "Please install Go >= 1.21 from https://go.dev/dl/"
    exit 1
fi

# Build binary
echo "[1/3] Building CLI binary..."
mkdir -p "$BIN_DIR"
go build -o "$BIN_DIR/$BINARY_NAME" ./cmd/vpm-tree
echo "✓ Binary built: $BIN_DIR/$BINARY_NAME"
echo ""

# Install binary
echo "[2/3] Installing binary..."
if [ -w "/usr/local/bin" ]; then
    # No sudo needed
    cp "$BIN_DIR/$BINARY_NAME" /usr/local/bin/
    echo "✓ Binary installed to /usr/local/bin/$BINARY_NAME"
elif command -v sudo &> /dev/null; then
    # Use sudo
    sudo cp "$BIN_DIR/$BINARY_NAME" /usr/local/bin/
    echo "✓ Binary installed to /usr/local/bin/$BINARY_NAME"
else
    # Install to ~/.local/bin
    mkdir -p ~/.local/bin
    cp "$BIN_DIR/$BINARY_NAME" ~/.local/bin/
    echo "✓ Binary installed to ~/.local/bin/$BINARY_NAME"
    echo ""
    echo "  Note: Make sure ~/.local/bin is in your PATH:"
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
fi
echo ""

# Install Vim plugin
echo "[3/3] Installing Vim plugin..."
VIM_PLUGIN_DIR="$HOME/.vim/pack/vpm-tree/start/vpm-tree.vim"
mkdir -p "$VIM_PLUGIN_DIR"
cp -r plugin autoload "$VIM_PLUGIN_DIR/"
echo "✓ Vim plugin installed to $VIM_PLUGIN_DIR"
echo ""

echo "========================================="
echo "  Installation Complete!"
echo "========================================="
echo ""
echo "Usage:"
echo "  Open Vim and run:"
echo "    :VpmTreeToggle"
echo ""
echo "  Or add to your .vimrc:"
echo "    nnoremap ]e :VpmTreeToggle<CR>"
echo ""
