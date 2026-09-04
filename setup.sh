#!/bin/bash
set -e

# Get the directory where the script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config/tmux-sess"
CONFIG_FILE="$CONFIG_DIR/tmux-sess.json"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"

log_error() {
    printf "[ERROR] %s\n" "$1"
}

log_info() {
    printf "[INFO] %s\n" "$1"
}

log_warn() {
    printf "[WARN] %s\n" "$1"
}

# Detect which multiplexer to set up
SETUP_MODE=""
if [ "$1" == "--herdr" ]; then
    SETUP_MODE="herdr"
    log_info "Setting up for herdr"
elif [ "$1" == "--tmux" ]; then
    SETUP_MODE="tmux"
    log_info "Setting up for tmux"
elif [ "$1" == "--both" ]; then
    SETUP_MODE="both"
    log_info "Setting up for both tmux and herdr"
else
    # Ask user via fzf prompt
    SETUP_MODE=$(printf "Both\nTmux\nHerdr" | fzf --prompt "Select setup mode: " --preview-window hidden --margin 10% --border rounded)

    if [ -z "$SETUP_MODE" ]; then
        log_error "No setup mode selected. Exiting."
        exit 1
    fi

    # Convert to lowercase for consistency
    SETUP_MODE=$(echo "$SETUP_MODE" | tr '[:upper:]' '[:lower:]')
    log_info "Setting up for $SETUP_MODE"
fi

# Check for dependencies
log_info "Checking dependencies..."
MISSING_DEPS=0

# Common dependencies
for cmd in jq fzf; do
    if ! command -v "$cmd" &>/dev/null; then
        log_error "$cmd is not installed."
        MISSING_DEPS=1
    else
        log_info "Found $cmd"
    fi
done

# Check for bc (needed for ratio calculation)
if ! command -v bc &>/dev/null; then
    log_error "bc is not installed."
    MISSING_DEPS=1
else
    log_info "Found bc"
fi

# Check multiplexer-specific dependencies
if [ "$SETUP_MODE" == "tmux" ] || [ "$SETUP_MODE" == "both" ]; then
    if ! command -v tmux &>/dev/null; then
        log_error "tmux is not installed."
        MISSING_DEPS=1
    else
        log_info "Found tmux"
    fi
fi

if [ "$SETUP_MODE" == "herdr" ] || [ "$SETUP_MODE" == "both" ]; then
    if ! command -v herdr &>/dev/null; then
        log_error "herdr is not installed."
        MISSING_DEPS=1
    else
        log_info "Found herdr"
    fi
fi

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
    ALIASES_ADDED=0

    # Setup tmux-sess alias
    if [ "$SETUP_MODE" == "tmux" ] || [ "$SETUP_MODE" == "both" ]; then
        if grep -q "alias tt=" "$ZSHRC"; then
            log_info "Alias 'tt' already exists in $ZSHRC"
        else
            TMUX_MAIN="$SCRIPT_DIR/tmux-sess.sh"
            {
                echo ""
                echo "# tmux-sess alias"
                echo "alias tt='$TMUX_MAIN'"
            } >>"$ZSHRC"
            log_info "Added alias 'tt' to $ZSHRC"
            ALIASES_ADDED=1
        fi
    fi

    # Setup herdr-sess alias
    if [ "$SETUP_MODE" == "herdr" ] || [ "$SETUP_MODE" == "both" ]; then
        if grep -q "alias hh=" "$ZSHRC"; then
            log_info "Alias 'hh' already exists in $ZSHRC"
        else
            HERDR_MAIN="$SCRIPT_DIR/herdr-sess.sh"
            {
                echo ""
                echo "# herdr-sess alias"
                echo "alias hh='$HERDR_MAIN'"
            } >>"$ZSHRC"
            log_info "Added alias 'hh' to $ZSHRC"
            ALIASES_ADDED=1
        fi
    fi

    if [ $ALIASES_ADDED -eq 1 ]; then
        log_info "Please run 'source ~/.zshrc' to apply changes."
    fi
else
    log_warn ".zshrc not found at $ZSHRC. Please manually add aliases:"
    if [ "$SETUP_MODE" == "tmux" ] || [ "$SETUP_MODE" == "both" ]; then
        echo "alias tt='$SCRIPT_DIR/tmux-sess.sh'"
    fi
    if [ "$SETUP_MODE" == "herdr" ] || [ "$SETUP_MODE" == "both" ]; then
        echo "alias hh='$SCRIPT_DIR/herdr-sess.sh'"
    fi
fi

log_info "Setup completed successfully!"
