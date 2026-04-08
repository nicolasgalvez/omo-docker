# Source this file in your .zshrc or .bashrc:
#   source /path/to/omo-docker/scripts/opencode.sh

OPENCODE_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-${(%):-%x}}")" && pwd)"

opencode() {
  "$OPENCODE_SCRIPT_DIR/opencode-run.sh" "$@"
}

# Bash completion
if [ -n "$BASH_VERSION" ]; then
  _opencode_completions() {
    local cur_word="${COMP_WORDS[COMP_CWORD]}"
    local args=("${COMP_WORDS[@]}")
    mapfile -t type_list < <("$OPENCODE_SCRIPT_DIR/opencode-run.sh" --get-yargs-completions "${args[@]}" 2>/dev/null)
    mapfile -t COMPREPLY < <(compgen -W "$(printf '%q ' "${type_list[@]}")" -- "$cur_word")
  }
  complete -o bashdefault -o default -F _opencode_completions opencode
fi

# Zsh completion
if [ -n "$ZSH_VERSION" ]; then
  _opencode_completions() {
    local completions
    completions=($("$OPENCODE_SCRIPT_DIR/opencode-run.sh" --get-yargs-completions "${words[@]}" 2>/dev/null))
    compadd -- $completions
  }
  compdef _opencode_completions opencode
fi
