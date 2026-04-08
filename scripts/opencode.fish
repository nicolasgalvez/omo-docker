# Source this file or symlink it into ~/.config/fish/conf.d/

set -q OPENCODE_SCRIPT_DIR; or set -gx OPENCODE_SCRIPT_DIR (status dirname)

function opencode
    $OPENCODE_SCRIPT_DIR/opencode-run.sh $argv
end

function __opencode_completions
    set -l tokens (commandline -opc)
    $OPENCODE_SCRIPT_DIR/opencode-run.sh --get-yargs-completions $tokens (commandline -ct) 2>/dev/null
end

complete -c opencode -f -a '(__opencode_completions)'
