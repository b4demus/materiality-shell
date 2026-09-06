# __e_fmt_s <seconds>  ->  "45s" / "12m" / "1h 12m"
function __e_fmt_s
    set -l s $argv[1]
    test -n "$s"; or set s 0
    if test $s -lt 60
        printf '%ds' $s
    else if test $s -lt 3600
        printf '%dm' (math -s0 "$s / 60")
    else
        printf '%dh %dm' (math -s0 "$s / 3600") (math -s0 "$s % 3600 / 60")
    end
end
