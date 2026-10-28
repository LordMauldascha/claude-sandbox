# claude-sandbox for bash (>= 3.2) and zsh. Source this file; do not execute it.
#
# claude-sandbox <name> | -c [name] | exit | -l | -d <name> | -h
# Switches CLAUDE_CONFIG_DIR to an isolated sandbox, active in the current shell only.
# Sandboxes live in $CLAUDE_SANDBOX_ROOT (default: $HOME/claude-sandbox).

if [ -z "${BASH_VERSION:-}${ZSH_VERSION:-}" ]; then
  echo "claude-sandbox: only bash and zsh are supported by this file (fish: use claude-sandbox.fish)." >&2
  return 1 2>/dev/null
fi

# Path prefix shared by all sandbox directories (append the sandbox name).
_claude_sandbox_base() {
  printf '%s' "${CLAUDE_SANDBOX_ROOT:-$HOME/claude-sandbox}/"
}

# Valid: non-empty, only A-Z a-z 0-9 . _ -, not starting with "-" or "." (so "." and ".." can never match).
_claude_sandbox_valid_name() {
  case "$1" in
    ""|-*|.*|*[!A-Za-z0-9._-]*) return 1 ;;
  esac
}

# Existing sandbox names, one per line.
_claude_sandbox_names() {
  local base d
  base=$(_claude_sandbox_base)
  if [ -n "${ZSH_VERSION:-}" ]; then setopt local_options null_glob; fi
  for d in "$base"*/; do
    [ -d "$d" ] || continue
    d=${d%/}
    printf '%s\n' "${d#"$base"}"
  done
}

# Prompt segment: "(Sandbox: <name>) " while a sandbox is active, empty otherwise.
claude_sandbox_prompt() {
  local base dir="${CLAUDE_CONFIG_DIR:-}"
  base=$(_claude_sandbox_base)
  case "$dir" in
    "$base"*) ;;
    *) return 0 ;;
  esac
  if [ -n "${ZSH_VERSION:-}" ]; then
    printf '%%F{magenta}(Sandbox: %s)%%f ' "${dir#"$base"}"
  else
    # \001/\002 mark the escapes as zero-width for readline.
    printf '\001\033[35m\002(Sandbox: %s)\001\033[0m\002 ' "${dir#"$base"}"
  fi
}

claude-sandbox() {
  local base name dir n reply
  base=$(_claude_sandbox_base)

  case "${1:-}" in
    ""|-h|--help)
      cat <<'HELP'
Usage: claude-sandbox <name>
       claude-sandbox -c [name] | exit | -l | -d <name> | -h

  <name>      Switch to the existing sandbox <name>
  -c [name]   Create sandbox [name] (default: current date/time) and switch to it
  exit        Leave the active sandbox
  -l          List sandboxes (* = active)
  -d <name>   Delete sandbox <name> (asks for confirmation)
  -h          Show this help

Sandbox = isolated CLAUDE_CONFIG_DIR, active in the current shell only.
Allowed name characters: A-Z a-z 0-9 . _ -  (must not start with - or .)
HELP
      ;;

    exit)
      if [ -z "${CLAUDE_CONFIG_DIR:-}" ]; then
        echo "No sandbox active." >&2
        return 1
      fi
      unset CLAUDE_CONFIG_DIR
      echo "Left sandbox."
      ;;

    -l)
      _claude_sandbox_names | while IFS= read -r n; do
        if [ "$base$n" = "${CLAUDE_CONFIG_DIR:-}" ]; then
          echo "* $n"
        else
          echo "  $n"
        fi
      done
      ;;

    -d)
      name="${2:-}"
      if ! _claude_sandbox_valid_name "$name"; then
        echo "Usage: claude-sandbox -d <name> (allowed: A-Z a-z 0-9 . _ -)" >&2
        return 1
      fi
      dir="$base$name"
      if [ ! -d "$dir" ]; then
        echo "Sandbox '$name' not found." >&2
        return 1
      fi
      printf 'Delete %s? [y/N] ' "$dir"
      IFS= read -r reply
      case "$reply" in
        y|Y) ;;
        *) echo "Aborted."; return 1 ;;
      esac
      rm -rf -- "$dir"
      [ "$dir" = "${CLAUDE_CONFIG_DIR:-}" ] && unset CLAUDE_CONFIG_DIR
      echo "Deleted sandbox '$name'."
      ;;

    -c)
      name="${2:-$(date +%Y-%m-%d_%H-%M)}"
      if ! _claude_sandbox_valid_name "$name"; then
        echo "Invalid name (allowed: A-Z a-z 0-9 . _ -, must not start with - or .)" >&2
        return 1
      fi
      dir="$base$name"
      if [ -e "$dir" ]; then
        echo "Sandbox '$name' already exists. Switch to it with: claude-sandbox $name" >&2
        return 1
      fi
      mkdir -p -- "$dir" || return 1
      export CLAUDE_CONFIG_DIR="$dir"
      echo "Created sandbox '$name'."
      ;;

    *)
      name="$1"
      if ! _claude_sandbox_valid_name "$name"; then
        echo "Invalid name (allowed: A-Z a-z 0-9 . _ -, must not start with - or .)" >&2
        return 1
      fi
      dir="$base$name"
      if [ ! -d "$dir" ]; then
        echo "Sandbox '$name' not found. Create it with: claude-sandbox -c $name" >&2
        return 1
      fi
      export CLAUDE_CONFIG_DIR="$dir"
      echo "Switched to sandbox '$name'."
      ;;
  esac
}

# Tab completion: sandbox names and options; only names after -d.
if [ -n "${BASH_VERSION:-}" ]; then
  _claude_sandbox_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}" words=""
    if [ "$COMP_CWORD" -eq 1 ]; then
      words="exit -c -l -d -h $(_claude_sandbox_names)"
    elif [ "$COMP_CWORD" -eq 2 ] && [ "${COMP_WORDS[1]}" = "-d" ]; then
      words="$(_claude_sandbox_names)"
    fi
    # shellcheck disable=SC2207  # mapfile is not available in bash 3.2
    COMPREPLY=($(compgen -W "$words" -- "$cur"))
  }
  complete -F _claude_sandbox_complete claude-sandbox
else
  _claude_sandbox_complete() {
    local n
    if [ "$CURRENT" -eq 2 ]; then
      compadd -- exit -c -l -d -h
    elif [ "$CURRENT" -ne 3 ] || [ "${words[2]}" != "-d" ]; then
      return 0
    fi
    while IFS= read -r n; do compadd -- "$n"; done < <(_claude_sandbox_names)
  }
  # compdef needs compinit; run it if the user's .zshrc has not yet.
  if ! type compdef >/dev/null 2>&1; then
    autoload -Uz compinit && compinit
  fi
  compdef _claude_sandbox_complete claude-sandbox
fi
