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


def load_config(projdir: Path):
    if not projdir.parent.exists():
        projdir.parent.mkdir()
    if not projdir.exists():
        shutil.copy2(PACKAGE_CONFIG_PATH, str(projdir))

    with open(projdir, "r") as f:
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


def main():
    layouts = load_config(CONFIG_PATH)
    if not os.path.exists(projdir):
        os.makedirs(projdir)
    os.chdir(projdir)
    if len(layouts) != 1:
        layout_names = "\n".join(list(layouts.keys()))

        echo_ps = subprocess.Popen(
            ["echo", f"{layout_names}"], stdout=subprocess.PIPE, text=True
        )
        fzf_ps = subprocess.Popen(
            ["fzf"], stdin=echo_ps.stdout, stdout=subprocess.PIPE, text=True
        )

        output, e = fzf_ps.communicate()
        layout = layouts[str(output).strip()]
    else:
        layout = layouts[list(layouts.keys())[0]]

    session_name = os.path.realpath(projdir).split("/")[-1]
    create_session(session_name, layout["windows"])
    subprocess.run(args=["tmux", "attach-session", "-t", session_name])


if __name__ == "__main__":
    main()
