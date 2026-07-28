.PHONY: build install clean test fmt help
.DEFAULT_GOAL := help

BINARY_NAME=vpm-tree
BIN_DIR=bin
INSTALL_PATH=/usr/local/bin

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

build: ## Build the CLI binary
	@echo "Building $(BINARY_NAME)..."
	@mkdir -p $(BIN_DIR)
	@go build -o $(BIN_DIR)/$(BINARY_NAME) ./cmd/vpm-tree
	@echo "Binary built: $(BIN_DIR)/$(BINARY_NAME)"

install: build ## Install binary and Vim plugin
	@echo "Installing $(BINARY_NAME) to $(INSTALL_PATH)..."
	@sudo cp $(BIN_DIR)/$(BINARY_NAME) $(INSTALL_PATH)/
	@echo "Binary installed successfully!"
	@echo "Installing Vim plugin..."
	@mkdir -p ~/.vim/pack/vpm-tree/start/vpm-tree.vim
	@cp -r plugin autoload ~/.vim/pack/vpm-tree/start/vpm-tree.vim/
	@echo "Vim plugin installed to ~/.vim/pack/vpm-tree/start/vpm-tree.vim/"
	@echo "Installation complete!"

install-local: build ## Install binary to ~/.local/bin (no sudo required)
	@echo "Installing $(BINARY_NAME) to ~/.local/bin..."
	@mkdir -p ~/.local/bin
	@cp $(BIN_DIR)/$(BINARY_NAME) ~/.local/bin/
	@echo "Binary installed successfully!"
	@echo "Installing Vim plugin..."
	@mkdir -p ~/.vim/pack/vpm-tree/start/vpm-tree.vim
	@cp -r plugin autoload ~/.vim/pack/vpm-tree/start/vpm-tree.vim/
	@echo "Vim plugin installed to ~/.vim/pack/vpm-tree/start/vpm-tree.vim/"
	@echo "Installation complete!"
	@echo ""
	@echo "Make sure ~/.local/bin is in your PATH:"
	@echo "  export PATH=\"\$$HOME/.local/bin:\$$PATH\""

clean: ## Remove build artifacts
	@echo "Cleaning build artifacts..."
	@rm -rf $(BIN_DIR)
	@echo "Clean complete!"

fmt: ## Format Go code
	@echo "Formatting code..."
	@go fmt ./...
	@echo "Format complete!"

test: ## Run tests
	@echo "Running tests..."
	@go test -v ./...

run: build ## Run the CLI with current directory
	@./$(BIN_DIR)/$(BINARY_NAME) -pretty

example: build ## Run example with test directory
	@./$(BIN_DIR)/$(BINARY_NAME) -root . -pretty -depth 2
