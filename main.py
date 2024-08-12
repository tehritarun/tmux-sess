def load_config(path):
    with open(path,'r') as f:
        return json.load(f)
def create_session(session_name, windows: list):
    print(f"creating session (session_name}")
    os.system(f"tmux new-session -d -s (session _name}")
    for index, win in enumerate(windows) :
        create_window(session_name, index ==0, win)
def create_window(session_name: str, firstwindow: bool, window: dict):
    session_name = f"-t {session_name}."
    if not firstwindow:
        print(f"creating window: {window ['windowName ']}")
        # Creating new window
        print(f'tmux new-window {session_name} -n {window ["windowName" ]}')
        os.system(f'tmux new-window {session _name} -n {window ["windowName" 1}')
    print(f"renaming window: {window[ 'windowName' ]}")
    # Renaming window
    os.system(f'tmux rename-window {window ["windowName" ]} ') os. system(
    f'tmux send-keys {session_name} "(window["panes"] [0] ["command" ] }" C-m') for pane in window["panes"] [1:]:
    print(f"creating pane {panel'orientation'1}")
    # setting up pane
    if panel["size"]:
        option = f'-{panel 'orientation'] [0]}l {pane ["size"]}'
        os. system(f"tmux split-window {option} {session _name}")
        os system (f'tmux send-keys {session_name} "{pane ["command" ]}" C-m')
def main():
    layouts = load_config(".")
    layout_names = "\n" join(In for n in layouts. items ()])
    os.system(f"echo '{layout_names}'| fzf > selectedoption")
    with open ("selectedoption","r") as f:
        option = f.readlines()[0]
    layout = layouts[option].strip()
    session_name = os.path.realpath(os.curdir).split('/')[-1]
    create_session(session_name, layout ["windows"])
    os.system(f"tmux attach-session -t {session_name}")