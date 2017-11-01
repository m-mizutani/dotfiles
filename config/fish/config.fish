alias em="emacs -nw"
alias make="make -j8"
rbenv init - | source
set -g -x GOPATH $HOME/godev
set -x PATH $HOME/.pyenv/shims $PATH
. (pyenv init - | psub)
set -x GOPATH $HOME/dev/go

