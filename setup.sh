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
