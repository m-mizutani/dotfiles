alias em="emacs -nw"
alias make="make -j8"

if test -e $HOME/.rbenv
  # rbenv init - | source
end

if test -e $HOME/.pyenv
  set -x PATH $HOME/.pyenv/shims $PATH
  . (pyenv init - | psub)
end

set -x GOPATH $HOME/dev/go
mkdir -p $GOPATH/bin
set -x PATH $GOPATH/bin $PATH

if test -e /opt/brew/bin
  set -x PATH /opt/brew/bin $PATH
end
