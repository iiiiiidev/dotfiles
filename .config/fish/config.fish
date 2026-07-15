if status is-interactive
    set fish_greeting
set -U fish_user_paths /home/i/.local/bin
end

alias ssh="kitty +kitten ssh "

starship init fish | source
