# expressive — fish shell config
status is-interactive; or exit 0

# no greeting banner
set -g fish_greeting

# per-shell session clock (used by the right prompt)
set -q __e_session_start; or set -g __e_session_start (date +%s)

# eagerly load the long-command notifier so its fish_postexec handler is bound
functions -q __e_notify

# git prompt bits shown in fish_prompt
set -g __fish_git_prompt_showdirtystate 1
set -g __fish_git_prompt_showuntrackedfiles 1
set -g __fish_git_prompt_showupstream informative
set -g __fish_git_prompt_char_dirtystate '✗'
set -g __fish_git_prompt_char_stagedstate '±'
set -g __fish_git_prompt_char_untrackedfiles '…'
set -g __fish_git_prompt_char_cleanstate ''
set -g __fish_git_prompt_char_upstream_ahead ' ↑'
set -g __fish_git_prompt_char_upstream_behind ' ↓'
set -g __fish_git_prompt_char_upstream_prefix ''
