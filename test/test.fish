# Tests for shell/claude-sandbox.fish. Run from the repository root:
#   fish test/test.fish

set -g failures 0

function ok
    echo "ok   - $argv[1]"
end

function fail
    echo "FAIL - $argv[1]"
    set -g failures (math $failures + 1)
end

# check <description> <command...>: command must succeed
function check
    set -l desc $argv[1]
    if $argv[2..-1] >/dev/null 2>&1
        ok $desc
    else
        fail $desc
    end
end

# check_fail <description> <command...>: command must fail
function check_fail
    set -l desc $argv[1]
    if $argv[2..-1] >/dev/null 2>&1
        fail $desc
    else
        ok $desc
    end
end

# equals <description> <expected> <actual>
function equals
    if test "$argv[2]" = "$argv[3]"
        ok $argv[1]
    else
        fail "$argv[1] (expected '$argv[2]', got '$argv[3]')"
    end
end

set -g test_home (mktemp -d)
set -gx HOME $test_home
set -e CLAUDE_CONFIG_DIR
set -e CLAUDE_SANDBOX_ROOT
set root $HOME/claude-sandbox

source shell/claude-sandbox.fish

# --- create ---
check "-c creates a sandbox" claude-sandbox -c foo
check "sandbox directory exists" test -d $root/foo
equals "-c activates the sandbox" $root/foo "$CLAUDE_CONFIG_DIR"
check_fail "-c refuses an existing name" claude-sandbox -c foo
claude-sandbox -c bar >/dev/null 2>&1
check "-c without a name creates a date-named sandbox" claude-sandbox -c

# --- switch ---
claude-sandbox foo >/dev/null 2>&1
equals "<name> switches to an existing sandbox" $root/foo "$CLAUDE_CONFIG_DIR"
check_fail "<name> fails for a missing sandbox" claude-sandbox nope
equals "failed switch keeps the active sandbox" $root/foo "$CLAUDE_CONFIG_DIR"

# --- invalid names (must never touch the filesystem) ---
for bad in . .. -x a/b "a b" .hidden
    check_fail "-c rejects '$bad'" claude-sandbox -c "$bad"
    check_fail "-d rejects '$bad'" claude-sandbox -d "$bad"
end
check "root survives invalid -d names" test -d $root/foo

# --- list ---
set -l list (claude-sandbox -l)
if contains -- "* foo" $list
    ok "-l marks the active sandbox"
else
    fail "-l marks the active sandbox"
end
if contains -- "  bar" $list
    ok "-l lists inactive sandboxes"
else
    fail "-l lists inactive sandboxes"
end

# --- prompt ---
if string match -q "*Sandbox: foo*" (claude_sandbox_prompt | string collect)
    ok "prompt shows the active sandbox"
else
    fail "prompt shows the active sandbox"
end

# --- exit ---
claude-sandbox exit >/dev/null 2>&1
equals "exit unsets CLAUDE_CONFIG_DIR" "" "$CLAUDE_CONFIG_DIR"
equals "prompt is empty outside a sandbox" "" (claude_sandbox_prompt | string collect)
check_fail "exit fails when no sandbox is active" claude-sandbox exit

# --- delete ---
echo n | claude-sandbox -d bar >/dev/null 2>&1
check "-d keeps the sandbox when not confirmed" test -d $root/bar
echo "" | claude-sandbox -d bar >/dev/null 2>&1
check "-d keeps the sandbox on empty answer" test -d $root/bar
echo y | claude-sandbox -d bar >/dev/null 2>&1
check_fail "-d removes the sandbox when confirmed" test -d $root/bar
claude-sandbox foo >/dev/null 2>&1
echo y | claude-sandbox -d foo >/dev/null 2>&1
equals "-d of the active sandbox unsets CLAUDE_CONFIG_DIR" "" "$CLAUDE_CONFIG_DIR"
check_fail "-d of a missing sandbox fails" claude-sandbox -d foo

# --- custom root ---
set -gx CLAUDE_SANDBOX_ROOT $HOME/other
claude-sandbox -c baz >/dev/null 2>&1
equals "CLAUDE_SANDBOX_ROOT changes the location" $HOME/other/baz "$CLAUDE_CONFIG_DIR"
check "sandbox is created under the custom root" test -d $HOME/other/baz

rm -rf $test_home
if test $failures -ne 0
    echo "$failures test(s) failed"
    exit 1
end
echo "all tests passed"
