# tmux-sess

`tmux-sess` is a Python-based tool designed to automate the creation of `tmux` sessions with predefined layouts. It allows you to easily set up your development environment with specific windows and panes for different projects.

## Quick Start

1.  Clone the repository:
    ```bash
    git clone https://github.com/tehritarun/tmux-sess.git
    cd tmux-sess
    ```
2.  Run the setup script:
    ```bash
    ./setup.sh
    ```
3.  Reload your shell configuration:
    ```bash
    source ~/.zshrc
    ```
4.  Start a session:
    ```bash
    tt ~/path/to/your/project
    ```

## Features

- **Automated Session Creation**: Create `tmux` sessions with a single command.
- **Custom Layouts**: Define complex window and pane layouts using a JSON configuration file.
- **Interactive Selection**: Use `fzf` to select from multiple defined layouts (if available).
- **Project-Based**: Associates sessions with specific project directories.

## Prerequisites

Before using `tmux-sess`, ensure you have the following installed:

- **Python 3**: The script is written in Python.
- **tmux**: The terminal multiplexer.
- **fzf**: (Optional but recommended) A command-line fuzzy finder, used for selecting layouts interactively.

## Installation

### Automated Setup

The easiest way to install is using the provided setup script.

1.  Clone this repository:

    ```bash
    git clone https://github.com/tehritarun/tmux-sess.git
    cd tmux-sess
    ```

2.  Run the setup script:

    ```bash
    chmod +x setup.sh
    ./setup.sh
    ```

    This script will:

    - Check for dependencies (`python3`, `tmux`, `fzf`).
    - Create the configuration directory `~/.config/tmux-sess`.
    - Copy the default `layouts.json` configuration.
    - Add an alias `tt` to your `.zshrc`.

3.  Reload your shell:
    ```bash
    source ~/.zshrc
    ```

### Manual Installation

1.  Clone the repository.
2.  Ensure dependencies are installed.
3.  Create `~/.config/tmux-sess` and copy `layouts.json` to `~/.config/tmux-sess/tmux-sess.json`.
4.  Add an alias to your shell configuration (e.g., `.bashrc` or `.zshrc`):
    ```bash
    alias tt='python3 /path/to/tmux-sess/main.py'
    ```

## Usage

Run the script by providing the path to your project directory:

```bash
tt <project_directory> [options]
```

(Assuming you have set up the `tt` alias)

### Arguments

- `dir`: **(Required)** Path to the project directory. The session name will be derived from the directory name.
- `--config`: **(Optional)** Path to a custom JSON configuration file. If not provided, it defaults to `~/.config/tmux-sess/tmux-sess.json`.

### Example

```bash
tt ~/projects/tmux-sess
```

## Configuration

The layouts are defined in a JSON file. By default, the script looks for `~/.config/tmux-sess/tmux-sess.json`. If it doesn't exist, it will be created using the default `layouts.json` provided in the package.

### Structure

The configuration file should contain a JSON object where keys are layout names and values are layout definitions.

```json
{
  "LayoutName": {
    "windows": [
      {
        "windowName": "Window Name",
        "panes": [
          {
            "orientation": "vertical",
            "name": "pane_name",
            "size": null,
            "command": "command_to_run"
          },
          {
            "orientation": "horizontal",
            "size": "50%",
            "command": "another_command"
          }
        ]
      }
    ]
  }
}
```

- **LayoutName**: A unique name for the layout (e.g., "Development", "Server").
- **windows**: A list of window objects.
  - **windowName**: The name of the tmux window.
  - **panes**: A list of pane objects. The first pane is the main pane of the window. Subsequent panes are splits from the previous one.
    - **orientation**: `vertical` or `horizontal`. Determines how the split is created relative to the previous pane.
    - **name**: (Optional) A name for the pane (currently not used in `tmux` commands but good for documentation).
    - **size**: (Optional) Size of the pane (e.g., "50%", "20"). If `null`, it uses default sizing.
    - **command**: The command to run in the pane upon creation.

### Example Configuration

```json
{
  "Development": {
    "windows": [
      {
        "windowName": "Editor",
        "panes": [
          {
            "orientation": "vertical",
            "name": "vim",
            "size": null,
            "command": "nvim ."
          }
        ]
      },
      {
        "windowName": "Terminal",
        "panes": [
          {
            "orientation": "vertical",
            "name": "shell",
            "size": null,
            "command": "ls -la"
          }
        ]
      }
    ]
  }
}
```

## Troubleshooting

### "command not found: tt"

Ensure you have run `source ~/.zshrc` after running the setup script. If you use a different shell (bash, fish), you need to manually add the alias.

### "tmux: command not found"

Install tmux using your package manager (e.g., `sudo apt install tmux` or `brew install tmux`).

### "fzf executable not found"

Install fzf using your package manager (e.g., `sudo apt install fzf` or `brew install fzf`).
