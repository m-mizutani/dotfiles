alias em="emacs -nw"
alias make="make -j8"
alias gcd="cd (ghq root)/(ghq list | sort | peco)"
alias gh="hub browse (ghq list | peco | cut -d '/' -f 2,3)"
alias jqc="jq --color-output"
alias less="less -r"
alias l="less -r"
alias pb="pbpaste | pbcopy"


set -x GO111MODULE auto

if test -e $HOME/local/bin
  set -x PATH $HOME/local/bin $PATH
end

if test -e $HOME/.cargo/bin
  set -x PATH $HOME/.cargo/bin $PATH
end

if test -e $HOME/.local/bin
  set -x PATH $HOME/.local/bin $PATH
end

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

if test -e $HOME/.goenv
  set -x GOENV_ROOT $HOME/.goenv
  set -x PATH $GOENV_ROOT/bin $PATH
  status --is-interactive; and source (goenv init -|psub)
  set -x PATH $GOROOT/bin $PATH
  set -x PATH $GOPATH/bin $PATH
end

if test -e $HOME/.cargo/env
  . $HOME/.cargo/env
end

if test -e /usr/local/texlive/2018/bin/x86_64-darwin
  set -x PATH /usr/local/texlive/2018/bin/x86_64-darwin $PATH
end


if test -e $HOME/.cpad2/profile.fish
  . ~/.cpad2/profile.fish
end

