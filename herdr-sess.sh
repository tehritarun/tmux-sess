#!/bin/bash

layout=$(cat ~/.config/tmux-sess/tmux-sess.json)
DIRECTORY=""
WORKSPACE_NAME=""
WORKSPACE_ID=""
DEBUG=1

debug() {
    if [[ "$DEBUG" -eq 1 ]]; then
        echo "[DEBUG] $1"
    fi
}

# Check herdr workspace
check-herdr-workspace() {
    WORKSPACE_NAME=$(basename "$DIRECTORY")
    WORKSPACE_NAME=${WORKSPACE_NAME//./-}
    debug "Checking herdr workspace $WORKSPACE_NAME"

    # Check if workspace with this label exists
    WORKSPACE_ID=$(herdr workspace list | jq -r '.result.workspaces.[] | select(.label == "'"$WORKSPACE_NAME"'") | .workspace_id')

    if [[ ! -z "$WORKSPACE_ID" ]]; then
        prompt="Herdr workspace with name $WORKSPACE_NAME already exists."
        debug "$prompt"
        choice=$(printf "Focus\nCreate New\nCancel" | fzf --prompt "$prompt" --preview-window hidden --margin 10% --border rounded)
        if [[ "$choice" == "Focus" ]]; then
            # Extract workspace ID and focus
            herdr workspace focus "$WORKSPACE_ID"
            exit 0
        elif [[ "$choice" == "Cancel" ]]; then
            exit 0
        elif [[ ! "$choice" == "Create New" ]]; then
            echo "Invalid selection"
            exit 1
        fi
    fi
}

open-pane() {
    pane_cmd=$(echo "$1" | jq -r '.command')
    pane_index=$2
    parent_pane=$3

    if [[ $pane_index -eq 0 ]]; then
        # First pane - use the initial pane from workspace/tab creation
        current_pane="$parent_pane"
    else
        # Split from the parent pane
        orient=$(echo "$1" | jq -r '.orientation')
        pane_size=$(echo "$1" | jq -r '.size')

        # Convert orientation to herdr direction
        if [[ "$orient" == "horizontal" ]]; then
            direction="down"
        else
            direction="right"
        fi

        # Calculate ratio (herdr uses 0.0-1.0)
        if [[ ! -z "$pane_size" ]] && [[ "$pane_size" != "null" ]]; then
            ratio=$(echo "scale=2; $pane_size / 100" | bc)
        else
            ratio="0.5"
        fi

        debug "Splitting pane in direction $direction with ratio $ratio"
        split_output=$(herdr pane split "$parent_pane" --direction "$direction" --ratio "$ratio" --cwd "$DIRECTORY" --focus 2>&1)

        # Extract pane ID from output
        current_pane=$(echo "$split_output" | grep -oE 'pane_[a-zA-Z0-9]+' | head -1)

        if [[ -z "$current_pane" ]]; then
            debug "Warning: Could not extract pane ID from split output"
            current_pane="$parent_pane"
        fi
    fi

    # Send command to pane
    if [[ ! -z "$pane_cmd" ]] && [[ "$pane_cmd" != "null" ]]; then
        debug "Running command in pane: $pane_cmd"
        herdr pane run "$current_pane" "$pane_cmd" 2>/dev/null || true
    fi

    echo "$current_pane"
}

create-tab() {
    tab_name=$(echo "$1" | jq -r '.windowName')
    tab_index=$2

    if [[ $tab_index -eq 0 ]]; then
        # First tab - already created with workspace, just get the initial pane
        debug "Using initial workspace tab"
        tab_output=$(herdr tab list --workspace "$WORKSPACE_ID" 2>&1)
        tab_id=$(echo "$tab_output" | jq -r '.result.tabs.[0].tab_id')

        herdr tab rename "$tab_id" "$tab_name"

        # Get first pane from this tab
        # pane_output=$(herdr pane list --workspace "$WORKSPACE_ID" 2>&1)
        # first_pane=$(echo "$pane_output" | grep -oE 'pane_[a-zA-Z0-9]+' | head -1)
    else
        debug "Creating new tab: $tab_name"
        tab_output=$(herdr tab create --workspace "$WORKSPACE_ID" --label "$tab_name" --cwd "$DIRECTORY" --focus 2>&1)
        tab_id=$(echo "$tab_output" | jq '.result.tab.tab_id')

        # Get the pane from the new tab
        sleep 0.2 # Brief delay to ensure tab is created
        # pane_output=$(herdr pane list --workspace "$WORKSPACE_ID" 2>&1)
        # first_pane=$(echo "$pane_output" | grep -oE 'pane_[a-zA-Z0-9]+' | tail -1)
    fi

    debug "Tab ID: $tab_id"

    # Create all panes for this tab
    pane_count=$(echo "$1" | jq '.panes | length')

    for ((j = 0; j < pane_count; j++)); do
        pane=$(echo "$1" | jq ".panes[$j]")
        parent_pane=$(open-pane "$pane" $j "$parent_pane")
    done
}

create-herdr-workspace() {
    debug "Creating herdr workspace: $WORKSPACE_NAME"
    workspace_output=$(herdr workspace create --label "$WORKSPACE_NAME" --no-focus 2>&1)
    WORKSPACE_ID=$(echo "$workspace_output" | jq -r '.result.workspace.workspace_id' 2>&1)

    if [[ -z "$WORKSPACE_ID" ]]; then
        echo "Failed to create workspace. Output: $workspace_output"
        exit 1
    fi

    debug "Created workspace with ID: $WORKSPACE_ID"

    # Select layout
    number_of_layouts=$(echo "$layout" | jq -r 'keys | length')
    if [[ "$number_of_layouts" -eq 1 ]]; then
        selected_layout=$(echo "$layout" | jq -r 'keys[]')
    else
        selected_layout=$(echo "$layout" | jq -r 'keys[]' | fzf --preview-window hidden --margin 10% --border rounded)
    fi

    if [[ -z "$selected_layout" ]]; then
        echo "No Layout selected."
        exit 1
    fi

    debug "Selected Layout: $selected_layout"
    selected_layout=$(echo "$layout" | jq ".$selected_layout")

    # Create tabs (windows)
    window_count=$(echo "$selected_layout" | jq '.windows | length')
    for ((i = 0; i < window_count; i++)); do
        win=$(echo "$selected_layout" | jq ".windows[$i]")
        create-tab "$win" $i
    done

    # Focus on the first tab
    herdr workspace focus "$WORKSPACE_ID"
}

# MAIN PROGRAM EXECUTION
# Validate input parameter and folder
if [[ $# -eq 0 ]]; then
    debug "No parameter provided. Continuing in current directory"
    DIRECTORY=$(pwd)
elif [[ "$1" == "." ]]; then
    debug "Continuing in current directory"
    DIRECTORY=$(pwd)
else
    if [[ -d "$1" ]]; then
        DIRECTORY=$(realpath "$1")
    elif [[ -f "$1" ]]; then
        debug "File path provided. Continuing with its parent directory"
        DIRECTORY=$(dirname "$(realpath "$1")")
    else
        debug "Creating new directory"
        DIRECTORY=$1
        if ! mkdir -p "$DIRECTORY"; then
            echo "Unable to create new directory. Please enter valid input"
            exit 1
        fi
        DIRECTORY=$(realpath "$DIRECTORY")
    fi
fi

check-herdr-workspace

# Create herdr workspace
create-herdr-workspace

echo "Herdr workspace '$WORKSPACE_NAME' created successfully!"
