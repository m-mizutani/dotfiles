alias em="emacs -nw"
alias make="make -j8"

set -x GOPATH $HOME/dev/go
mkdir -p $GOPATH/bin
set -x PATH $GOPATH/bin $PATH

if test -e /opt/brew/bin
  set -x PATH /opt/brew/bin $PATH
end

if test -e $HOME/.pyenv
  . (pyenv init - | psub)
end

if test -e $HOME/.rbenv
  # $HOME/.rbenv/bin/rbenv init - | source
end

