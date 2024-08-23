export PS1="\[\033[38;5;2m\]\h\[$(tput sgr0)\]\[\033[38;5;15m\]:\[$(tput sgr0)\]\[\033[38;5;12m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\] \\$ \[$(tput sgr0)\]"

if [ -e $HOME/.cpad2/profile ]; then
  source $HOME/.cpad2/profile
fi

# added by travis gem
[ -f /Users/mizutani/.travis/travis.sh ] && source /Users/mizutani/.travis/travis.sh

source /Users/mizutani/.docker/init-bash.sh || true # Added by Docker Desktop
