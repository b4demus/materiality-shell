function fish_right_prompt
    # the last-command time moved to the left prompt (in place of the clock);
    # the right prompt just carries how long this shell has been open
    set -q __e_session_start; or return
    set -l up (math (date +%s) - $__e_session_start)
    set_color brblack
    echo -n '⧗ '(__e_fmt_s $up)
    set_color normal
end
