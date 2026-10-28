# Tests for shell/claude-sandbox.sh. Run from the repository root with bash or zsh:
#   bash test/test.sh
#   zsh test/test.sh

failures=0

ok() {
  echo "ok   - $1"
}

fail() {
  echo "FAIL - $1"
  failures=$((failures + 1))
}

# check <description> <command...>: command must succeed
check() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then ok "$desc"; else fail "$desc"; fi
}

# check_fail <description> <command...>: command must fail
check_fail() {
  local desc="$1"
  shift
  if "$@" >/dev/null 2>&1; then fail "$desc"; else ok "$desc"; fi
}

# equals <description> <expected> <actual>
equals() {
  if [ "$2" = "$3" ]; then ok "$1"; else fail "$1 (expected '$2', got '$3')"; fi
}

TEST_HOME=$(mktemp -d)
HOME="$TEST_HOME"
unset CLAUDE_CONFIG_DIR CLAUDE_SANDBOX_ROOT
root="$HOME/claude-sandbox"

# Completion registration needs compinit in zsh; not under test here.
if [ -n "${ZSH_VERSION:-}" ]; then compdef() { :; }; fi

# shellcheck source=shell/claude-sandbox.sh
. ./shell/claude-sandbox.sh

# --- create ---
check "-c creates a sandbox" claude-sandbox -c foo
check "sandbox directory exists" test -d "$root/foo"
equals "-c activates the sandbox" "$root/foo" "${CLAUDE_CONFIG_DIR:-}"
check_fail "-c refuses an existing name" claude-sandbox -c foo
claude-sandbox -c bar >/dev/null 2>&1
check "-c without a name creates a date-named sandbox" claude-sandbox -c

# --- switch ---
claude-sandbox foo >/dev/null 2>&1
equals "<name> switches to an existing sandbox" "$root/foo" "${CLAUDE_CONFIG_DIR:-}"
check_fail "<name> fails for a missing sandbox" claude-sandbox nope
equals "failed switch keeps the active sandbox" "$root/foo" "${CLAUDE_CONFIG_DIR:-}"

# --- invalid names (must never touch the filesystem) ---
for bad in "." ".." "-x" "a/b" "a b" ".hidden"; do
  check_fail "-c rejects '$bad'" claude-sandbox -c "$bad"
  check_fail "-d rejects '$bad'" claude-sandbox -d "$bad"
done
check "root survives invalid -d names" test -d "$root/foo"

# --- list ---
list=$(claude-sandbox -l)
case "$list" in *"* foo"*) ok "-l marks the active sandbox" ;; *) fail "-l marks the active sandbox" ;; esac
case "$list" in *"  bar"*) ok "-l lists inactive sandboxes" ;; *) fail "-l lists inactive sandboxes" ;; esac

# --- prompt ---
case "$(claude_sandbox_prompt)" in *"Sandbox: foo"*) ok "prompt shows the active sandbox" ;; *) fail "prompt shows the active sandbox" ;; esac

# --- exit ---
claude-sandbox exit >/dev/null 2>&1
equals "exit unsets CLAUDE_CONFIG_DIR" "" "${CLAUDE_CONFIG_DIR:-}"
equals "prompt is empty outside a sandbox" "" "$(claude_sandbox_prompt)"
check_fail "exit fails when no sandbox is active" claude-sandbox exit

# --- delete ---
claude-sandbox -d bar >/dev/null 2>&1 <<< "n"
check "-d keeps the sandbox when not confirmed" test -d "$root/bar"
claude-sandbox -d bar >/dev/null 2>&1 <<< ""
check "-d keeps the sandbox on empty answer" test -d "$root/bar"
claude-sandbox -d bar >/dev/null 2>&1 <<< "y"
check_fail "-d removes the sandbox when confirmed" test -d "$root/bar"
claude-sandbox foo >/dev/null 2>&1
claude-sandbox -d foo >/dev/null 2>&1 <<< "y"
equals "-d of the active sandbox unsets CLAUDE_CONFIG_DIR" "" "${CLAUDE_CONFIG_DIR:-}"
check_fail "-d of a missing sandbox fails" claude-sandbox -d foo

# --- custom root ---
export CLAUDE_SANDBOX_ROOT="$HOME/other"
claude-sandbox -c baz >/dev/null 2>&1
equals "CLAUDE_SANDBOX_ROOT changes the location" "$HOME/other/baz" "${CLAUDE_CONFIG_DIR:-}"
check "sandbox is created under the custom root" test -d "$HOME/other/baz"

rm -rf "$TEST_HOME"
if [ "$failures" -ne 0 ]; then
  echo "$failures test(s) failed"
  exit 1
fi
echo "all tests passed"
