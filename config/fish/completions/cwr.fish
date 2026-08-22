# Completions for cwr (bin/cwr). The candidates are the git worktrees created by
# `claude --worktree`, which carry random names; the description shows the branch
# and when the worktree's session was last written, so the right one can be
# picked without opening it first.

complete -c cwr -f
complete -c cwr -n __fish_is_first_arg -a "(cwr --complete)"
complete -c cwr -n __fish_is_first_arg -a list -d "show worktrees and their last session time"
