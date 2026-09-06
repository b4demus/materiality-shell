# Pull the active Material You palette into fish colour vars (e_*), so the prompt
# tracks the expressive scheme. Re-read on every new shell.
status is-interactive; or exit 0

set -l j $HOME/.local/state/expressive/colors.json
if type -q jq; and test -r $j
    for pair in "e_primary primary" "e_secondary secondary" "e_tertiary tertiary" \
                "e_error error" "e_muted onSurfaceVariant" "e_fg onSurface"
        set -l parts (string split ' ' $pair)
        set -l v (jq -r ".dark.$parts[2] // empty" $j 2>/dev/null)
        test -n "$v"; and set -g $parts[1] $v
    end
end
