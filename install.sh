#!/bin/sh
# claude-sandbox installer.
#
#   curl -fsSL https://raw.githubusercontent.com/LordMauldascha/claude-sandbox/main/install.sh | sh
#   curl -fsSL https://raw.githubusercontent.com/LordMauldascha/claude-sandbox/main/install.sh | sh -s -- --modify-rc
#
# Downloads a release into the install directory and prints how to load it in
# your shell. Your shell startup file is only changed with --modify-rc.

set -eu

REPO="LordMauldascha/claude-sandbox"
INSTALL_DIR="${CLAUDE_SANDBOX_HOME:-${XDG_DATA_HOME:-$HOME/.local/share}/claude-sandbox}"
VERSION="latest"
SHELL_NAME=""
MODIFY_RC=0

usage() {
  cat <<'EOF'
Usage: install.sh [--version <tag|main>] [--shell bash|zsh|fish] [--modify-rc] [-h]

  --version <v>   Release tag to install (default: latest release), or "main"
  --shell <name>  Shell to set up (default: detected from $SHELL)
  --modify-rc     Add the source line to your shell startup file
                  (fish: symlink into ~/.config/fish/conf.d). Without this
                  flag the command to run is only printed.
  -h, --help      Show this help

Environment: CLAUDE_SANDBOX_HOME overrides the install directory
(default: ${XDG_DATA_HOME:-~/.local/share}/claude-sandbox).
EOF
}

die() {
  echo "install.sh: $*" >&2
  exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    --version) [ $# -ge 2 ] || die "--version needs a value"; VERSION="$2"; shift 2 ;;
    --shell) [ $# -ge 2 ] || die "--shell needs a value"; SHELL_NAME="$2"; shift 2 ;;
    --modify-rc) MODIFY_RC=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 1 ;;
  esac
done

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar >/dev/null 2>&1 || die "tar is required"

if [ -z "$SHELL_NAME" ]; then
  SHELL_NAME="${SHELL##*/}"
fi
case "$SHELL_NAME" in
  bash|zsh|fish) ;;
  *) die "unsupported shell '$SHELL_NAME' (use --shell bash|zsh|fish)" ;;
esac

# Resolve "latest" to a tag by following the releases/latest redirect.
if [ "$VERSION" = "latest" ]; then
  url=$(curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$REPO/releases/latest") \
    || die "could not determine the latest release"
  VERSION="${url##*/}"
  case "$VERSION" in
    ""|latest) die "no release found; install the development version with --version main" ;;
  esac
fi

if [ "$VERSION" = "main" ]; then
  archive="https://github.com/$REPO/archive/refs/heads/main.tar.gz"
else
  archive="https://github.com/$REPO/archive/refs/tags/$VERSION.tar.gz"
fi

# Never replace a directory that is not an earlier claude-sandbox install.
if [ -e "$INSTALL_DIR" ] && [ ! -f "$INSTALL_DIR/shell/claude-sandbox.sh" ]; then
  die "$INSTALL_DIR exists and is not a claude-sandbox install; set CLAUDE_SANDBOX_HOME to another path"
fi

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT INT TERM

echo "Downloading claude-sandbox $VERSION ..."
curl -fsSL "$archive" | tar -xzf - -C "$tmp" --strip-components=1 \
  || die "download failed: $archive"
[ -f "$tmp/shell/claude-sandbox.sh" ] || die "downloaded archive looks wrong"

mkdir -p "$(dirname "$INSTALL_DIR")"
rm -rf "$INSTALL_DIR"
mv "$tmp" "$INSTALL_DIR"
trap - EXIT INT TERM
echo "Installed to $INSTALL_DIR"

case "$SHELL_NAME" in
  bash)
    if [ "$(uname -s)" = "Darwin" ]; then rc="$HOME/.bash_profile"; else rc="$HOME/.bashrc"; fi
    line="source \"$INSTALL_DIR/shell/claude-sandbox.sh\""
    ;;
  zsh)
    rc="${ZDOTDIR:-$HOME}/.zshrc"
    line="source \"$INSTALL_DIR/shell/claude-sandbox.sh\""
    ;;
  fish)
    conf_dir="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d"
    link="$conf_dir/claude-sandbox.fish"
    ;;
esac

if [ "$SHELL_NAME" = "fish" ]; then
  if [ "$MODIFY_RC" -eq 1 ]; then
    mkdir -p "$conf_dir"
    ln -sf "$INSTALL_DIR/shell/claude-sandbox.fish" "$link"
    echo "Linked $link"
  else
    echo
    echo "To finish, run:"
    echo "  mkdir -p \"$conf_dir\" && ln -sf \"$INSTALL_DIR/shell/claude-sandbox.fish\" \"$link\""
  fi
elif [ "$MODIFY_RC" -eq 1 ]; then
  if [ -f "$rc" ] && grep -qF -- "$line" "$rc"; then
    echo "$rc already loads claude-sandbox; nothing to change."
  else
    printf '\n# claude-sandbox\n%s\n' "$line" >> "$rc"
    echo "Added to $rc"
  fi
else
  echo
  echo "To finish, add this line to $rc:"
  echo "  $line"
fi

echo
echo "Open a new terminal, then try: claude-sandbox -c test"
echo "Prompt integration: https://github.com/$REPO#show-the-active-sandbox-in-your-prompt"
