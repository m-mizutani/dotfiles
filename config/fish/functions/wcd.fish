function wcd --description "cd to git worktree selected by peco"
    set -l selected (git worktree list | peco)
    if test -z "$selected"
        return
    end
    set -l dir (echo $selected | awk '{print $1}')
    cd $dir
end
