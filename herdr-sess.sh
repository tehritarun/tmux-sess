#!/bin/bash

layout=$(cat ~/.config/tmux-sess/tmux-sess.json)
DIRECTORY=""
WORKSPACE_NAME=""
WORKSPACE_ID=""
ROOT_PANE_ID=""
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
    output_rep=$(herdr workspace list)

    if [[ ! $? -eq 0 ]]; then
        debug "Herdr server not running. starting a new one."
        herdr &
        sleep 2
    else
        WORKSPACE_ID=$(echo "$output_rep" | jq -r '.result.workspaces.[] | select(.label == "'"$WORKSPACE_NAME"'") | .workspace_id')
    fi

    if [[ ! -z "$WORKSPACE_ID" ]]; then
        prompt="Herdr workspace with name $WORKSPACE_NAME already exists."
        debug "$prompt"
        choice=$(printf "Focus\nCreate New\nCancel" | fzf --prompt "$prompt" --preview-window hidden --margin 10% --border rounded)
        if [[ "$choice" == "Focus" ]]; then
            # Extract workspace ID and focus
            herdr workspace focus "$WORKSPACE_ID"
            herdr
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
        split_output=$(herdr pane split "$parent_pane" --direction "$direction" --ratio "$ratio" --cwd "$DIRECTORY" --focus)

        # Extract pane ID from JSON output
        current_pane=$(echo "$split_output" | jq -r '.result.pane.pane_id')

        if [[ -z "$current_pane" ]] || [[ "$current_pane" == "null" ]]; then
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
        tab_output=$(herdr tab list --workspace "$WORKSPACE_ID")
        tab_id=$(echo "$tab_output" | jq -r '.result.tabs[0].tab_id')

        herdr tab rename "$tab_id" "$tab_name"

        # Get first pane from this tab - it's the root pane from workspace creation
        first_pane="$ROOT_PANE_ID"
    else
        debug "Creating new tab: $tab_name"
        tab_output=$(herdr tab create --workspace "$WORKSPACE_ID" --label "$tab_name" --cwd "$DIRECTORY" --focus)
        tab_id=$(echo "$tab_output" | jq -r '.result.tab.tab_id')

        # Get the root pane from the tab creation response
        first_pane=$(echo "$tab_output" | jq -r '.result.root_pane.pane_id')
    fi

    debug "Tab ID: $tab_id, First pane: $first_pane"

    # Create all panes for this tab
    pane_count=$(echo "$1" | jq '.panes | length')
    parent_pane="$first_pane"

    for ((j = 0; j < pane_count; j++)); do
        pane=$(echo "$1" | jq ".panes[$j]")
        parent_pane=$(open-pane "$pane" $j "$parent_pane")
    done
}

create-herdr-workspace() {
    debug "Creating herdr workspace: $WORKSPACE_NAME"
    workspace_output=$(herdr workspace create --label "$WORKSPACE_NAME" --no-focus)
    WORKSPACE_ID=$(echo "$workspace_output" | jq -r '.result.workspace.workspace_id')
    ROOT_PANE_ID=$(echo "$workspace_output" | jq -r '.result.root_pane.pane_id')

    if [[ -z "$WORKSPACE_ID" ]] || [[ "$WORKSPACE_ID" == "null" ]]; then
        echo "Failed to create workspace. Output: $workspace_output"
        exit 1
    fi

    debug "Created workspace with ID: $WORKSPACE_ID"
    debug "Root pane ID: $ROOT_PANE_ID"

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

    # Focus on the workspace
    herdr workspace focus "$WORKSPACE_ID"
    herdr
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
