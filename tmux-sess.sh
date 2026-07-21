#!/bin/bash

layout=$(cat ~/.config/tmux-sess/tmux-sess.json)
DIRECTORY=""
SESSION_NAME=""
DEBUG=1

debug() {
    if [[ "$DEBUG" -eq 1 ]]; then
        echo "[DEBUG] $1"
    fi
}

# Check tmux session
check-tmux-session() {
    SESSION_NAME=$(basename "$DIRECTORY")
    debug "Checking tmux session $SESSION_NAME"
    tmux_out=$(tmux ls | grep "$SESSION_NAME")
    if [[ ! -z "$tmux_out" ]]; then
        prompt="Tmux session with name $SESSION_NAME already exists."
        debug "$prompt"
        choice=$(printf "Attach\nCreate New\nCancel" | fzf --prompt "$prompt" --preview-window hidden --margin 10% --border rounded)
        if [[ "$choice" == "Attach" ]]; then
            tmux attach-session -t "$SESSION_NAME"
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
    if [[ ! $2 -eq 0 ]]; then
        orient=$(echo "$1" | jq -r '.orientation')
        orient=${orient:0:1}
        pane_size=$(echo "$1" | jq -r '.size')
        pane_option="-${orient}"

        if [[ ! -z "$pane_size" ]]; then
            printf -v pane_option "-${orient}l ${pane_size}%"
        fi

        debug "Spliting windows in panes"
        tmux split-window "$pane_option" -t "$SESSION_NAME"
    fi

    debug "Sending commands"
    tmux send-keys -t "$SESSION_NAME" "$pane_cmd" C-m
}

create-window() {
    window_name=$(echo "$1" | jq -r '.windowName')
    if [[ ! "$2" -eq 0 ]]; then
        debug "Creating New window"
        tmux new-window -t "$SESSION_NAME" -n "$window_name"
    fi

    debug "Renaming windows $window_name"
    tmux rename-window "$window_name"

    pane_count=$(echo "$1" | jq '.panes | length')
    for ((j = 0; j < pane_count; j++)); do
        pane=$(echo "$1" | jq ".panes[$j]")
        open-pane "$pane"
    done
}

create-tmux-session() {
    tmux new-session -d -s "$SESSION_NAME"
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

    debug "Selected Layout $selected_layout"
    selected_layout=$(echo "$layout" | jq ".$selected_layout")

    window_count=$(echo "$selected_layout" | jq '.windows | length')
    for ((i = 0; i < window_count; i++)); do
        win=$(echo "$selected_layout" | jq ".windows[$i]")
        create-window "$win" $i
    done
}

# MAIN PROGRAM EXECUTION
# Validate input parameter and folder
if [[ $# -eq 0 ]]; then
    debug "No parameter provided. Continuing in current directory"
    DIRECTORY=$(pwd)
elif [[ "$1" == "." ]]; then
    DIRECTORY=$(pwd)
else
    if [[ -d "$1" ]]; then
        DIRECTORY=$1
    elif [[ -f "$1" ]]; then
        DIRECTORY=$(dirname "$1")
    else
        DIRECTORY=$1
        if [[ ! $(mkdir -p "$DIRECTORY") -eq 0 ]]; then
            echo "Enable to create new directory. Please enter valid input"
            exit 1
        fi
    fi
fi

check-tmux-session

# Cd into directory
cd "$DIRECTORY" || exit 1

# Create tmux session
create-tmux-session

# Attach to tmux session
tmux attach-session -t "$SESSION_NAME"
