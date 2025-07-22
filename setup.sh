#!/bin/bash

pushd `dirname $0` > /dev/null
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )"
popd > /dev/null

mkdir -p $HOME/.config/fish
ln -s $SCRIPTPATH/config/fish/config.fish $HOME/.config/fish/config.fish

mkdir -p $HOME/.emacs.d
ln -s $SCRIPTPATH/emacs.d/init.el $HOME/.emacs.d/init.el

mkdir -p $HOME/.hammerspoon
ln -s $SCRIPTPATH/hammerspoon/init.lua $HOME/.hammerspoon/init.lua

ln -s $SCRIPTPATH/tmux.conf $HOME/.tmux.conf
ln -s $SCRIPTPATH/bashrc $HOME/.bashrc
ln -s $SCRIPTPATH/hyper.js $HOME/.hyper.js

ln -s $SCRIPTPATH/gitconfig $HOME/.gitconfig

mkdir -p $HOME/.config/git
ln -s $SCRIPTPATH/gitignore $HOME/.config/git/ignore

ln -s $SCRIPTPATH/wezterm.lua $HOME/.wezterm.lua

mkdir -p $HOME/.claude
ln -s $SCRIPTPATH/claude/commands $HOME/.claude/commands
