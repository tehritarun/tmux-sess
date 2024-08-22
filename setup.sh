configdir= $HOME/.config/tmux-sess
if [ -d $configdir ]; then
	mkdir $configdir
else
	echo "configuration folder is already present"
fi

if [ -f $configdir/tmux-sess.json ]; then
	echo "./layouts.json on $configdir/tmux-sess.json"
	cp ./layouts.json $configdir/tmux-sess.json
else
	echo "configuration is already present"
fi

projectdir=$PWD/main.py
echo "alias tt='python3 $projectdir'" >> $HOME/.zshrc
