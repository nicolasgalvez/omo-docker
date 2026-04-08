# Source this file or symlink it into ~/.config/fish/conf.d/

set -q OPENCODE_COMPOSE_FILE; or set -gx OPENCODE_COMPOSE_FILE (status dirname)/../docker-compose.yml

function opencode
    docker compose -f "$OPENCODE_COMPOSE_FILE" run --rm opencode $argv
end

function __opencode_completions
    set -l tokens (commandline -opc)
    docker compose -f "$OPENCODE_COMPOSE_FILE" run --rm -T opencode --get-yargs-completions $tokens (commandline -ct) 2>/dev/null
end

complete -c opencode -f -a '(__opencode_completions)'
