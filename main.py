import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

PACKAGE_CONFIG_PATH = str(Path("~/projects/tmux-sess/layouts.json").expanduser())


def parse_arguments():
    parser = argparse.ArgumentParser(
        prog="tmux-sess",
        description="Helps create tmux session",
    )
    parser.add_argument("dir", help="Path to the project directory")
    parser.add_argument("--config", help="Path to the config file", default="")
    args = parser.parse_args()
    dir_path = args.dir
    config_path = args.config

    if config_path.strip() == "":
        config_path = Path("~/.config/tmux-sess/tmux-sess.json").expanduser()
    elif Path(config_path).exists():
        config_path = Path(config_path).expanduser()
    else:
        print("Invalid Config path")
        sys.exit(1)
    return config_path, dir_path


def load_config(config_path: Path):
    if not config_path.parent.exists():
        config_path.parent.mkdir()
    if not config_path.exists():
        shutil.copy2(PACKAGE_CONFIG_PATH, str(config_path))

    with Path.open(config_path) as f:
        return json.load(f)


def create_session(session_name, windows: list):
    print(f"creating session {session_name}")
    subprocess.run(check=False, args=["tmux", "new-session", "-d", "-s", session_name])
    for index, win in enumerate(windows):
        create_window(session_name, window=win, firstwindow=(index == 0))


def create_window(session_name: str, window: dict, *, firstwindow: bool):
    # session_name = f"-t {session_name}"
    if not firstwindow:
        print(f"creating window: {window['windowName']}")
        # Creating new window
        subprocess.run(
            check=False,
            args=["tmux", "new-window", "-t", session_name, "-n", window["windowName"]],
        )
    # Renaming window
    print(f"renaming window: {window['windowName']}")
    subprocess.run(check=False, args=["tmux", "rename-window", window["windowName"]])
    subprocess.run(
        check=False,
        args=[
            "tmux",
            "send-keys",
            "-t",
            session_name,
            window["panes"][0]["command"],
            "C-m",
        ],
    )
    for pane in window["panes"][1:]:
        # setting up pane
        print(f"creating pane {pane['orientation']}")
        if pane["size"]:
            option = f"-{pane['orientation'][0]}l {pane['size']}"
            subprocess.run(
                check=False,
                args=["tmux", "split-window", option, session_name],
            )
            subprocess.run(
                check=False,
                args=["tmux", "send-keys", "-t", session_name, pane["command"], "C-m"],
            )


def get_user_choice(options: list) -> str:
    opts_str = "\n".join(options)

    echo_executable = shutil.which("echo")
    if echo_executable is None:
        raise FileNotFoundError("echo executable not found.")

    echo_ps = subprocess.Popen(
        [echo_executable, f"{opts_str}"],
        stdout=subprocess.PIPE,
        text=True,
    )
    fzf_executable = shutil.which("fzf")
    if fzf_executable is None:
        raise FileNotFoundError("fzf executable not found. Please install fzf.")

    fzf_ps = subprocess.Popen(
        [fzf_executable],
        stdin=echo_ps.stdout,
        stdout=subprocess.PIPE,
        text=True,
    )

    output, _ = fzf_ps.communicate()
    return str(output).strip()


def main():
    # get arguments
    config_path, dir_path = parse_arguments()
    # load config
    layouts = load_config(config_path)
    # create project directory if not exists
    proj_path = Path(dir_path)
    if not proj_path.exists():
        proj_path.mkdir()
    # change dir to project directory
    os.chdir(dir_path)
    # ask user to select layout if multiple available in config
    if len(layouts) != 1:
        chosen_layout = get_user_choice(list(layouts.keys()))
        layout = layouts[chosen_layout]
    else:
        layout = next(iter(layouts.values()))
    # get session name and create session
    session_name = os.path.realpath(dir_path).split("/")[-1]
    session_name = session_name.replace(".", "_")
    create_session(session_name, layout["windows"])
    subprocess.run(check=False, args=["tmux", "attach-session", "-t", session_name])


if __name__ == "__main__":
    main()
