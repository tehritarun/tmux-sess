# check and create folder if not present
configdir="$HOME/.config/tmux-sess"
if [ -d "$configdir" ]; then
    echo "Configuration folder is already present"
else
    mkdir "$configdir"
    echo "Configuration folder created.."
fi

# check and crete configuration if not present
if [ -f "$configdir"/tmux-sess.json ]; then
    echo "Configuration is already present"
else
    echo "./layouts.json on $configdir/tmux-sess.json"
    cp ./layouts.json "$configdir"/tmux-sess.json
    echo "Example configuration created"
fi

# check and create zshrc entry is not present
sessEntry=$(grep "tmux-sess" < ~/.zshrc)
echo "$sessEntry"

if [ -z "$sessEntry" ]; then
    projectdir=$PWD/main.py
    echo "alias tt='python3 $projectdir'" >> "$ZDOTDIR"/.zshrc
    echo "Entry added in zshrc"
else
    echo "zshrc entry is already available"
fi
