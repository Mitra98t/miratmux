#!/usr/bin/env bash

set -euo pipefail

die()  { echo "Error: $*" >&2; exit 1; }
ok()   { echo "Ok: $*"; }

SCRIPT_DIR=$(dirname "$0")

plugin_install() {
  "$SCRIPT_DIR/plugins/tpm/scripts/install_plugins.sh" \
    || die "failed to install tmux plugins."
  ok "plugins installed."
}
plugin_update() {
  "$SCRIPT_DIR/plugins/tpm/scripts/update_plugin.sh" \
    || die "failed to run update script from TPM."
  ok "plugins updated."
}
plugin_clear() {
  rm -rf "$SCRIPT_DIR/plugins" \
    || die "failed to remove plugin directory."
  ok "plugin directory cleared."
}

check_secondary_dependencies() {
  local deps=( btm lazygit yazi )
  local names=( Bottom LazyGit Yazi )
  local missing=()

  echo "Secondary dependencies:"
  for i in "${!deps[@]}"; do
    if command -v "${deps[$i]}" &>/dev/null; then
      printf "  [✓] %s\n" "${names[$i]}"
    else
      printf "  [✗] %s\n" "${names[$i]}"
      missing+=( "${names[$i]}" )
    fi
  done

  if (( ${#missing[@]} > 0 )); then
    echo ""
    echo "Missing: ${missing[*]} — install to enable full functionality."
  fi
}

usage() {
  cat <<'EOF'
miratmux config installer

USAGE
  ./installation.sh [OPTIONS]
  (no options)    Install TPM and all plugins, then launch tmux

OPTIONS
  -u    Update all plugins via TPM
  -c    Clear the plugins directory
  -d    Check the secondary dependencies installation
  -h    Show this help message

PLUGINS
  tpm · tmux-sensible · catppuccin · tmux-resurrect · tmux-continuum · tmux-which-key

EOF
}



while getopts "hucd" opt; do
  case ${opt} in
    h)
      usage
      exit 0
      ;;
    u)
      plugin_update 
      exit 0
      ;;
    c)
      plugin_clear
      exit 0
      ;;
    d)
      check_secondary_dependencies 
      exit 0
      ;;
    \?)
      usage
      exit 1
      ;;
    *)
      usage >&2
      exit 1
      ;;
  esac
done
shift $((OPTIND - 1))

if [ $# -gt 0 ]; then
  echo "Error: unexpected argument: '$1'" >&2
  usage >&2
  exit 1
fi

if (( OPTIND == 1 )); then
  command -v git  &>/dev/null || die "git is not installed."
  command -v tmux &>/dev/null || die "tmux is not installed."
  ok "mandatory dependencies found."

  git clone https://github.com/tmux-plugins/tpm "$SCRIPT_DIR/plugins/tpm" \
    || die "failed to clone tmux plugin manager."
  ok "tmux plugin manager installed."

  plugin_install

  check_secondary_dependencies

  for i in 5 4 3 2 1; do
    printf "\rLaunching tmux in %d..." "$i"
    sleep 1
  done
  printf "\r\033[K"

  exec tmux
fi
