# tmux-sess / herdr-sess

A collection of bash scripts designed to automate the creation of terminal multiplexer sessions with predefined layouts. Supports both `tmux` and `herdr`, allowing you to easily set up your development environment with specific windows/tabs and panes for different projects.

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
    You'll be prompted to select: `Both`, `Tmux`, or `Herdr`

3.  Reload your shell configuration:
    ```bash
    source ~/.zshrc
    ```
4.  Start a session:
    ```bash
    # For tmux
    tt ~/path/to/your/project
    
    # For herdr
    hh ~/path/to/your/project
    ```

## Features

- **Dual Multiplexer Support**: Works with both `tmux` and `herdr` terminal multiplexers.
- **Automated Session Creation**: Create sessions with a single command.
- **Shared Configuration**: Use the same layout configuration for both tmux and herdr.
- **Custom Layouts**: Define complex window/tab and pane layouts using a JSON configuration file.
- **Interactive Selection**: Use `fzf` to select from multiple defined layouts.
- **Project-Based**: Associates sessions with specific project directories.
- **Session Management**: Automatically detects existing sessions and prompts to attach or create new.

## Prerequisites

Before using these scripts, ensure you have the following installed:

- **bash**: The scripts are written in bash.
- **jq**: JSON processor for parsing configuration files.
- **fzf**: Command-line fuzzy finder for interactive selection.
- **bc**: Calculator for ratio calculations (herdr-sess).
- **tmux**: (Required for tmux-sess) The tmux terminal multiplexer.
- **herdr**: (Required for herdr-sess) The herdr terminal multiplexer.

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

    You'll be prompted via `fzf` to select:
    - **Both**: Setup both tmux-sess and herdr-sess
    - **Tmux**: Setup only tmux-sess
    - **Herdr**: Setup only herdr-sess

    Alternatively, skip the prompt by passing a flag:
    ```bash
    ./setup.sh --both   # Setup both
    ./setup.sh --tmux   # Setup only tmux
    ./setup.sh --herdr  # Setup only herdr
    ```

    This script will:

    - Check for dependencies (`jq`, `fzf`, `bc`, and selected multiplexers).
    - Create the configuration directory `~/.config/tmux-sess`.
    - Copy the default `layouts.json` configuration to `~/.config/tmux-sess/tmux-sess.json`.
    - Add aliases to your `.zshrc`:
      - `tt` for tmux-sess
      - `hh` for herdr-sess

3.  Reload your shell:
    ```bash
    source ~/.zshrc
    ```

### Manual Installation

1.  Clone the repository.
2.  Ensure dependencies are installed.
3.  Create `~/.config/tmux-sess` and copy `layouts.json` to `~/.config/tmux-sess/tmux-sess.json`.
4.  Make scripts executable:
    ```bash
    chmod +x tmux-sess.sh herdr-sess.sh
    ```
5.  Add aliases to your shell configuration (e.g., `.bashrc` or `.zshrc`):
    ```bash
    alias tt='/path/to/tmux-sess/tmux-sess.sh'
    alias hh='/path/to/tmux-sess/herdr-sess.sh'
    ```

## Usage

### tmux-sess

Run the script by providing the path to your project directory:

```bash
tt <directory>
```

- If no directory is provided, uses the current directory.
- Pass `.` to explicitly use the current directory.
- If the path is a file, uses its parent directory.
- Creates the directory if it doesn't exist.

### herdr-sess

```bash
hh <directory>
```

Same usage as tmux-sess, but creates herdr workspaces instead of tmux sessions.

### Examples

```bash
# Start tmux session in a project directory
tt ~/projects/my-app

# Start herdr workspace in current directory
hh .

# Create new directory and start session
tt ~/projects/new-project
```

## Configuration

Both scripts share the same configuration file: `~/.config/tmux-sess/tmux-sess.json`

### Structure

The configuration file contains a JSON object where keys are layout names and values are layout definitions.

```json
{
  "LayoutName": {
    "windows": [
      {
        "windowName": "Window Name",
        "panes": [
          {
            "orientation": "vertical",
            "size": 50,
            "command": "command_to_run"
          },
          {
            "orientation": "horizontal",
            "size": 30,
            "command": "another_command"
          }
        ]
      }
    ]
  }
}
```

- **LayoutName**: A unique name for the layout (e.g., "Development", "Server").
- **windows**: A list of window/tab objects.
  - **windowName**: The name of the window (tmux) or tab (herdr).
  - **panes**: A list of pane objects. The first pane is the root pane. Subsequent panes are splits from the previous one.
    - **orientation**: `vertical` or `horizontal`. Determines the split direction.
      - `vertical`: Split left/right
      - `horizontal`: Split top/bottom
    - **size**: (Optional) Size of the pane as a percentage (e.g., `50` for 50%). If omitted or `null`, uses default sizing (50/50 split).
    - **command**: (Optional) The command to run in the pane upon creation.

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
            "size": 70,
            "command": "ls -la"
          },
          {
            "orientation": "horizontal",
            "size": 30,
            "command": "git status"
          }
        ]
      }
    ]
  },
  "Server": {
    "windows": [
      {
        "windowName": "Main",
        "panes": [
          {
            "orientation": "vertical",
            "command": "npm run dev"
          },
          {
            "orientation": "vertical",
            "size": 30,
            "command": "npm run test:watch"
          }
        ]
      }
    ]
  }
}
```

## Key Differences: tmux vs herdr

While both scripts use the same configuration, they map to different concepts:

| Concept | tmux-sess | herdr-sess |
|---------|-----------|------------|
| Top-level | Session | Workspace |
| Container | Window | Tab |
| Split | Pane | Pane |
| Attach/Focus | `tmux attach` | `herdr workspace focus` |

Both scripts handle:
- Session/workspace name collision detection
- Interactive layout selection with fzf
- Automatic directory creation
- Command execution in panes

## Troubleshooting

### "command not found: tt" or "command not found: hh"

Ensure you have run `source ~/.zshrc` after running the setup script. If you use a different shell (bash, fish), you need to manually add the aliases to the appropriate config file.

### "tmux: command not found"

Install tmux using your package manager:
```bash
# macOS
brew install tmux

# Ubuntu/Debian
sudo apt install tmux

# Fedora
sudo dnf install tmux
```

### "herdr: command not found"

Install herdr by following the instructions at [herdr.dev](https://herdr.dev/).

### "fzf: command not found"

Install fzf using your package manager:
```bash
# macOS
brew install fzf

# Ubuntu/Debian
sudo apt install fzf

# Fedora
sudo dnf install fzf
```

### "jq: command not found"

Install jq using your package manager:
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt install jq

# Fedora
sudo dnf install jq
```

### "bc: command not found"

Install bc using your package manager:
```bash
# macOS (usually pre-installed)
brew install bc

# Ubuntu/Debian
sudo apt install bc

# Fedora
sudo dnf install bc
```

### Session/Workspace already exists

Both scripts detect existing sessions/workspaces and prompt you to:
- **Attach/Focus**: Connect to the existing session
- **Create New**: Continue creating a new session with a different name
- **Cancel**: Exit the script

### Pane commands not executing

Ensure your commands are properly quoted in the JSON configuration. Commands with special characters or spaces should be enclosed in quotes.

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License.

## Links

- [tmux](https://github.com/tmux/tmux)
- [herdr](https://herdr.dev/)
- [fzf](https://github.com/junegunn/fzf)
- [jq](https://github.com/jqlang/jq)
