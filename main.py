import json
import os
import argparse
import subprocess
from pathlib import Path
import shutil

parser = argparse.ArgumentParser(
    prog="tmux-sess", description="Helps create tmux session")
parser.add_argument("dir", help="Path to the project directory")
parser.add_argument(
    "--config", help="Path to the config file", default="")
args = parser.parse_args()
projdir = args.dir
CONFIG_PATH = args.config

PACKAGE_CONFIG_PATH = str(
    Path("~/projects/tmux-sess/layouts.json").expanduser())
if CONFIG_PATH.strip() == "":
    CONFIG_PATH = Path("~/.config/tmux-sess/tmux-sess.json").expanduser()
elif Path(CONFIG_PATH).exists():
    CONFIG_PATH = Path(CONFIG_PATH).expanduser()
else:
    print("Invalid Config path")
    exit(1)


def load_config(config_path: Path):
    if not config_path.parent.exists():
        config_path.parent.mkdir()
    if not config_path.exists():
        shutil.copy2(PACKAGE_CONFIG_PATH, str(config_path))

    with open(config_path, "r") as f:
        return json.load(f)


def create_session(session_name, windows: list):
    print(f"creating session {session_name}")
    subprocess.run(args=["tmux", "new-session", "-d", "-s", session_name])
    for index, win in enumerate(windows):
        create_window(session_name, index == 0, win)


def create_window(session_name: str, firstwindow: bool, window: dict):
    # session_name = f"-t {session_name}"
    if not firstwindow:
        print(f"creating window: {window ['windowName']}")
        # Creating new window
        subprocess.run(
            args=["tmux", "new-window", "-t",
                  session_name, "-n", window["windowName"]]
        )
    # Renaming window
    print(f"renaming window: {window[ 'windowName' ]}")
    subprocess.run(args=["tmux", "rename-window", window["windowName"]])
    subprocess.run(
        args=[
            "tmux",
            "send-keys",
            "-t",
            session_name,
            window["panes"][0]["command"],
            "C-m",
        ]
    )
    for pane in window["panes"][1:]:
        # setting up pane
        print(f"creating pane {pane['orientation']}")
        if pane["size"]:
            option = f"-{pane['orientation'][0]}l {pane['size']}"
            subprocess.run(args=["tmux", "split-window", option, session_name])
            subprocess.run(
                args=["tmux", "send-keys", "-t",
                      session_name, pane["command"], "C-m"]
            )


def get_user_choice(options: list) -> str:
    opts_str = "\n".join(options.keys())

    echo_ps = subprocess.Popen(
        ["echo", f"{opts_str}"], stdout=subprocess.PIPE, text=True
    )
    fzf_ps = subprocess.Popen(
        ["fzf"], stdin=echo_ps.stdout, stdout=subprocess.PIPE, text=True
    )

    output, e = fzf_ps.communicate()
    return str(output).strip()


def main():
    # load config
    layouts = load_config(CONFIG_PATH)
    # create project directory if not exists
    proj_path = Path(projdir)
    if not proj_path.exists():
        proj_path.mkdir()
    # change dir to project directory
    os.chdir(projdir)
    # ask user to select layout if multiple available in config
    if len(layouts) != 1:
        chosen_layout = get_user_choice(list(layouts.keys()))
        layout = layouts[chosen_layout]
    else:
        layout = layouts[list(layouts.keys())[0]]
    # get session name and create session
    session_name = os.path.realpath(projdir).split("/")[-1]
    create_session(session_name, layout["windows"])
    subprocess.run(args=["tmux", "attach-session", "-t", session_name])


if __name__ == "__main__":
    main()
