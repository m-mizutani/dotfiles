function fish_title
    if set -q argv[1]
        echo (basename (pwd)) "($argv[1])"
    else
        basename (pwd)
    end
end
