# Desktop notification (with a kaomoji) when a long command finishes — handy for
# builds / long jobs when the terminal isn't focused.
function __e_notify --on-event fish_postexec
    set -l st $status
    test -n "$CMD_DURATION"; and test $CMD_DURATION -gt 45000; or return
    type -q notify-send; or return

    set -l cmd (string sub -l 72 -- $argv[1])
    set -l k (__e_kaomoji $st)
    if test $st -eq 0
        notify-send -a fish -- "$k  finished in "(__e_fmt_ms $CMD_DURATION) "$cmd"
    else
        notify-send -a fish -u critical -- "$k  exit $st after "(__e_fmt_ms $CMD_DURATION) "$cmd"
    end
end
