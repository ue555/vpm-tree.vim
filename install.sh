#!/bin/bash

# vpm-tree.vim installation script
# This script builds the CLI binary and installs the Vim plugin

set -e

BIN_DIR="bin"

echo "========================================="
echo "  vpm-tree.vim Installation"
echo "========================================="
echo ""

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "Error: Go is not installed"
    echo "Please install Go >= 1.25 from https://go.dev/dl/"
    exit 1
fi

# Require the minimum version declared in go.mod.
GO_VERSION="$(go env GOVERSION)"
if [[ ! "$GO_VERSION" =~ ^go([0-9]+)\.([0-9]+) ]] ||
   (( BASH_REMATCH[1] < 1 || (BASH_REMATCH[1] == 1 && BASH_REMATCH[2] < 25) )); then
    echo "Error: Go >= 1.25 is required (found $GO_VERSION)"
    exit 1
fi

# go env GOEXE is ".exe" on Windows (cmd.exe cannot run extension-less files)
BINARY_NAME="vpm-tree$(go env GOEXE)"

# Build binary
echo "[1/3] Building CLI binary..."
mkdir -p "$BIN_DIR"
go build -o "$BIN_DIR/$BINARY_NAME" ./cmd/vpm-tree
echo "✓ Binary built: $BIN_DIR/$BINARY_NAME"
echo ""

# Install binary
echo "[2/3] Installing binary..."
# Default to ~/.local/bin (no sudo required)
mkdir -p ~/.local/bin
cp "$BIN_DIR/$BINARY_NAME" ~/.local/bin/
echo "✓ Binary installed to ~/.local/bin/$BINARY_NAME"
echo ""
echo "  Note: Make sure ~/.local/bin is in your PATH:"
echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
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
echo "IMPORTANT: Add ~/.local/bin to your PATH"
echo ""
echo "For Bash users, run:"
echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.bashrc"
echo "  source ~/.bashrc"
echo ""
echo "For Zsh users, run:"
echo "  echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc"
echo "  source ~/.zshrc"
echo ""
echo "Verify PATH:"
echo "  which vpm-tree"
echo ""
echo "========================================="
echo ""
echo "Usage:"
echo "  Open Vim and run:"
echo "    :VpmTreeToggle"
echo ""
echo "  Or add to your .vimrc:"
echo "    nnoremap ]e :VpmTreeToggle<CR>"
echo ""
