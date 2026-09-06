function fish_prompt
    set -l last $status

    echo ''

    # ── line 1: path + git ─────────────────────────────────────────────
    if set -q e_primary
        set_color -o $e_primary
    else
        set_color -o cyan
    end
    echo -n (prompt_pwd)
    set_color normal

    set -l g (fish_git_prompt 2>/dev/null)
    if test -n "$g"
        set_color brmagenta
        echo -n " ⎇"$g
        set_color normal
    end

    if set -q SSH_TTY
        set_color yellow
        echo -n '  '(prompt_hostname)
        set_color normal
    end
    echo ''

    # ── line 2: kaomoji · time · arrow ─────────────────────────────────
    if test $last -eq 0
        set_color green
    else
        set_color -o red
    end
    echo -n (__e_kaomoji $last)' '
    set_color brblack
    echo -n (date '+%H:%M:%S')' '
    if test $last -eq 0
        set_color green
    else
        set_color -o red
    end
    echo -n '❯ '
    set_color normal
end
