alias em="emacs -nw"
alias make="make -j8"
alias gcd="cd (ghq root)/(ghq list | peco)"
alias gh="hub browse (ghq list | peco | cut -d '/' -f 2,3)"


set -x GOPATH $HOME/dev/go
set -x GO111MODULE auto
mkdir -p $GOPATH/bin
set -x PATH $GOPATH/bin $PATH

if test -e /opt/brew/bin
  set -x PATH /opt/brew/bin $PATH
end

if test -e $HOME/.rbenv/shims
  set -x PATH  $HOME/.rbenv/shims $PATH
end

if test -e $HOME/.pyenv
  . (pyenv init - | psub)
end

if test -e $HOME/.rbenv
  # $HOME/.rbenv/bin/rbenv init - | source
end

if test -e $HOME/.cargo/env
  . $HOME/.cargo/env
end

if test -e /usr/local/texlive/2018/bin/x86_64-darwin
  set -x PATH /usr/local/texlive/2018/bin/x86_64-darwin $PATH
end

if test -e $HOME/local/bin
  set -x PATH $HOME/local/bin $PATH
end

if test -e $HOME/.local/bin
  set -x PATH $HOME/.local/bin $PATH
end

set -g fish_user_paths "/opt/brew/opt/terraform@0.11/bin" $fish_user_paths
