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
alias tffmt=" git diff --name-only| grep \.tf | sed -e 's@\(.*\)@terraform fmt \1@g' | bash"
alias brclean="git branch --merged | grep -v ' main' | xargs git branch -d"
alias cid='git rev-parse HEAD | tr -d "\n" | pbcopy && pbpaste'
alias pn='pbpaste | tr "\n" " " | pbcopy'
alias ge='echo "masayoshi.mizutani+$(date +%Y%m%d%H%M%S)@dr-ubie.com" | pbcopy'
alias gnew='git co main && git pull && git cob'
alias gt='go tool'
alias gtt='go tool task'
alias ghc='gh browse -n -c'
alias cc='claude --dangerously-skip-permissions'

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

if test -e /usr/local/go/bin
  set -x PATH /usr/local/go/bin $PATH
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

set -x GCLOUD_CONFIG $HOME/.gcloud/google-cloud-sdk/path.fish.inc
if test -e $GCLOUD_CONFIG
  source $GCLOUD_CONFIG
end

if test -e $HOME/Library/Python/3.9/bin
  set -x PATH $HOME/Library/Python/3.9/bin $PATH
end

if test -e $HOME/.ubie-bin
  set -x PATH $HOME/.ubie-bin $PATH
end
set -x CLOUDSDK_PYTHON_SITEPACKAGES 1

# source /Users/mizutani/.docker/init-fish.sh || true # Added by Docker Desktop

if test -e /opt/homebrew/bin//direnv
  direnv hook fish | source
end

if test -e $HOME/.rd
  set -x PATH $HOME/.rd/bin $PATH
#  set -x DOCKER_HOST unix://$HOME/.rd/docker.sock
end

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
set --export --prepend PATH "/Users/mizutani/.rd/bin"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mizutani/.gcloud/google-cloud-sdk/path.fish.inc' ]; . '/Users/mizutani/.gcloud/google-cloud-sdk/path.fish.inc'; end
if [ -f '/Users/mizutani/.google-cloud-sdk/path.fish.inc' ]; . '/Users/mizutani/.google-cloud-sdk/path.fish.inc'; end

# Tailscale
if [ -f '/Applications/Tailscale.app/Contents/MacOS/Tailscale' ]
  alias tailscale='/Applications/Tailscale.app/Contents/MacOS/Tailscale'
end  
