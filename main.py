import json
import os
import argparse
import subprocess

parser = argparse.ArgumentParser(description='tmux session creator')
parser.add_argument('path')
args = parser.parse_args()
path = args.path


def load_config(path):
    with open(path, 'r') as f:
        return json.load(f)


def create_session(session_name, windows: list):
    print(f"creating session {session_name}")
    os.system(f"tmux new-session -d -s {session_name}")
    for index, win in enumerate(windows):
        create_window(session_name, index == 0, win)


def create_window(session_name: str, firstwindow: bool, window: dict):
    session_name = f"-t {session_name}"
    if not firstwindow:
        print(f"creating window: {window ['windowName']}")
        # Creating new window
        print(f'tmux new-window {session_name} -n {window ["windowName"]}')
        os.system(f'tmux new-window {session_name} -n {window ["windowName"]}')
    print(f"renaming window: {window[ 'windowName' ]}")
    # Renaming window
    os.system(f'tmux rename-window {window ["windowName" ]}')
    os. system(
        f'tmux send-keys {session_name} "{window["panes"][0]["command"]}" C-m')
    for pane in window["panes"][1:]:
        print(f"creating pane {pane['orientation']}")
        # setting up pane
        if pane["size"]:
            option = f"-{pane['orientation'][0]}l {pane['size']}"
            os.system(f"tmux split-window {option} {session_name}")
            os.system(
                f'tmux send-keys {session_name} "{pane ["command"]}" C-m')


def main():
    layouts = load_config("/home/ttehri/projects/tmux-sess/layouts.json")
    os.chdir(path)
    layout_names = "\n".join([n for n, _ in layouts.items()])

    echo_ps = subprocess.Popen(
        ['echo', f'{layout_names}'], stdout=subprocess.PIPE, text=True)
    fzf_ps = subprocess.Popen(
        ['fzf'], stdin=echo_ps.stdout, stdout=subprocess.PIPE, text=True)

    output, e = fzf_ps.communicate()
    layout = layouts[str(output).strip()]
    print(layout)

    session_name = os.path.realpath(path).split('/')[-1]
    create_session(session_name, layout["windows"])
    os.system(f"tmux attach-session -t {session_name}")


if __name__ == "__main__":
    main()
