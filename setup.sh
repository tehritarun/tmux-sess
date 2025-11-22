#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/tmux-sess"
CONFIG_FILE="$CONFIG_DIR/tmux-sess.json"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

# Check for dependencies
log_info "Checking dependencies..."
MISSING_DEPS=0
for cmd in python3 tmux fzf; do
    if ! command -v "$cmd" &> /dev/null; then
        log_error "$cmd is not installed."
        MISSING_DEPS=1
    else
        log_info "Found $cmd"
    fi
done

if [ $MISSING_DEPS -eq 1 ]; then
    log_error "Please install missing dependencies and try again."
    exit 1
fi

# Create configuration directory
if [ -d "$CONFIG_DIR" ]; then
    log_info "Configuration folder exists at $CONFIG_DIR"
else
    mkdir -p "$CONFIG_DIR"
    log_info "Created configuration folder at $CONFIG_DIR"
fi

# Create default configuration
if [ -f "$CONFIG_FILE" ]; then
    log_info "Configuration file exists at $CONFIG_FILE"
else
    if [ -f "$SCRIPT_DIR/layouts.json" ]; then
        cp "$SCRIPT_DIR/layouts.json" "$CONFIG_FILE"
        log_info "Created default configuration at $CONFIG_FILE"
    else
        log_warn "layouts.json not found in $SCRIPT_DIR. Skipping default config creation."
    fi
fi

# Add alias to .zshrc
if [ -f "$ZSHRC" ]; then
    if grep -q "alias tt=" "$ZSHRC"; then
        log_info "Alias 'tt' already exists in $ZSHRC"
    else
        PROJECT_MAIN="$SCRIPT_DIR/main.py"
        {
            echo ""
            echo "# tmux-sess alias"
            echo "alias tt='python3 $PROJECT_MAIN'"
        } >> "$ZSHRC"
        log_info "Added alias 'tt' to $ZSHRC"
        log_info "Please run 'source ~/.zshrc' to apply changes."
    fi
else
    log_warn ".zshrc not found at $ZSHRC. Please manually add the alias:"
    echo "alias tt='python3 $SCRIPT_DIR/main.py'"
fi

log_info "Setup completed successfully!"
