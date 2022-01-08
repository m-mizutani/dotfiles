alias em="emacs -nw"
alias make="make -j8"
alias gcd="cd (ghq root)/(ghq list | sort | peco)"
alias jpp="pbpaste | jq | bat -l json"
alias jp="bat -l json"
alias jpi="pbpaste | jid"
alias bpp="pbpaste | base64 -D"
alias less="less -r"
alias l="less -r"
alias pb="pbpaste | pbcopy"
alias h="fish -c \"(history | peco)\""

function fish_user_key_bindings
  bind \cr 'peco_select_history (commandline -b)'
end

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
if test -e /opt/homebrew/bin/
  set -x PATH /opt/homebrew/bin/ $PATH
end

if test -e $HOME/Library/Python/3.9/bin
  set -x PATH $HOME/Library/Python/3.9/bin $PATH
end

if test -e $HOME/.rbenv/shims
  status --is-interactive; and source (rbenv init -|psub)
  set -x PATH  $HOME/.rbenv/shims $PATH
end

if test -e $HOME/.pyenv
  . (pyenv init - | psub)
end

if test -e $HOME/.rbenv
  # $HOME/.rbenv/bin/rbenv init - | source
end

set -x GOPATH $HOME/.go
set -x PATH $GOPATH/bin $PATH

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

set -x GCLOUD_CONFIG $HOME/.gcloud/google-cloud-sdk/path.fish.inc
if test -e $GCLOUD_CONFIG
  source $GCLOUD_CONFIG
end


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mizutani/.google-cloud-sdk/path.fish.inc' ]; . '/Users/mizutani/.google-cloud-sdk/path.fish.inc'; end
