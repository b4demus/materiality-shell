function fish_right_prompt
    set -l sep (set_color brblack)' · '(set_color normal)
    set -l parts

    # time the last command took (only when it's worth mentioning)
    if test -n "$CMD_DURATION"; and test $CMD_DURATION -gt 1500
        set -a parts (set_color yellow)'⏱ '(__e_fmt_ms $CMD_DURATION)(set_color normal)
    end

    # how long this shell session has been open
    if set -q __e_session_start
        set -l up (math (date +%s) - $__e_session_start)
        set -a parts (set_color brblack)'⧗ '(__e_fmt_s $up)(set_color normal)
    end

    string join "$sep" $parts
end
