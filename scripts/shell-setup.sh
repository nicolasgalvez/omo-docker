#!/bin/sh
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Detect shell and set config paths
detect_shell() {
  shell="$(basename "$SHELL")"
  case "$shell" in
    fish)
      RC_FILE="$HOME/.config/fish/conf.d/opencode.fish"
      SHELL_NAME="fish"
      ;;
    zsh)
      RC_FILE="$HOME/.zshrc"
      SHELL_NAME="zsh"
      ;;
    bash)
      RC_FILE="$HOME/.bashrc"
      SHELL_NAME="bash"
      ;;
    *)
      echo "Unsupported shell: $shell"
      echo "Supported: bash, zsh, fish"
      exit 1
      ;;
  esac
}

install_fish() {
  mkdir -p "$(dirname "$RC_FILE")"
  if [ -e "$RC_FILE" ] && [ "$(readlink "$RC_FILE" 2>/dev/null)" = "$SCRIPT_DIR/opencode.fish" ]; then
    echo "Already installed in $RC_FILE"
    return
  fi
  ln -sf "$SCRIPT_DIR/opencode.fish" "$RC_FILE"
  echo "Symlinked $RC_FILE -> $SCRIPT_DIR/opencode.fish"
}

uninstall_fish() {
  if [ ! -e "$RC_FILE" ]; then
    echo "Not found: $RC_FILE"
    return
  fi
  rm "$RC_FILE"
  echo "Removed $RC_FILE"
}

install_posix() {
  SOURCE_LINE="source \"$SCRIPT_DIR/opencode.sh\""
  if grep -qF "$SOURCE_LINE" "$RC_FILE" 2>/dev/null; then
    echo "Already installed in $RC_FILE"
    return
  fi
  printf '\n# oh-my-opencode\n%s\n' "$SOURCE_LINE" >> "$RC_FILE"
  echo "Added to $RC_FILE"
  echo "Run: source $RC_FILE"
}

uninstall_posix() {
  SOURCE_LINE="source \"$SCRIPT_DIR/opencode.sh\""
  if ! grep -qF "$SOURCE_LINE" "$RC_FILE" 2>/dev/null; then
    echo "Not found in $RC_FILE"
    return
  fi
  tmp="$(mktemp)"
  sed '/^# oh-my-opencode$/d' "$RC_FILE" | sed "\|^${SOURCE_LINE}$|d" > "$tmp"
  mv "$tmp" "$RC_FILE"
  echo "Removed from $RC_FILE"
  echo "Run: source $RC_FILE"
}

install() {
  case "$SHELL_NAME" in
    fish)  install_fish ;;
    *)     install_posix ;;
  esac
}

uninstall() {
  case "$SHELL_NAME" in
    fish)  uninstall_fish ;;
    *)     uninstall_posix ;;
  esac
}

usage() {
  echo "Usage: $0 {install|uninstall}"
}

case "${1:-}" in
  install)   detect_shell; install ;;
  uninstall) detect_shell; uninstall ;;
  *)         usage; exit 1 ;;
esac
