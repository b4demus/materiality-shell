# __e_fmt_ms <milliseconds>  ->  "450ms" / "2.4s" / "1m 3s" / "1h 4m"
function __e_fmt_ms
    set -l ms $argv[1]
    test -n "$ms"; or set ms 0
    if test $ms -lt 1000
        printf '%dms' $ms
        return
    end
    set -l s (math -s0 "$ms / 1000")
    if test $s -lt 60
        # tenths of a second, locale-independent (no printf %f -> no ru comma)
        set -l ds (math -s0 "($ms + 50) / 100")
        printf '%d.%ds' (math -s0 "$ds / 10") (math -s0 "$ds % 10")
    else if test $s -lt 3600
        printf '%dm %ds' (math -s0 "$s / 60") (math -s0 "$s % 60")
    else
        printf '%dh %dm' (math -s0 "$s / 3600") (math -s0 "$s % 3600 / 60")
    end
end
