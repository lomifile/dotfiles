if status is-interactive
end

function attach_session
    tmux ls
    echo -n 'Attach session'
    set session (read)
    tmux attach -t $session
end

zoxide init fish | source
set -gx PNPM_HOME "/home/f/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
