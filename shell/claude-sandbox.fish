# claude-sandbox for fish. Copy or symlink to ~/.config/fish/conf.d/ (or source it).
#
# claude-sandbox <name> | -c [name] | exit | -l | -d <name> | -h
# Switches CLAUDE_CONFIG_DIR to an isolated sandbox, active in the current shell only.
# Sandboxes live in $CLAUDE_SANDBOX_ROOT (default: $HOME/claude-sandbox).

# Path prefix shared by all sandbox directories (append the sandbox name).
function __claude_sandbox_base
    if test -n "$CLAUDE_SANDBOX_ROOT"
        echo "$CLAUDE_SANDBOX_ROOT/"
    else
        echo "$HOME/claude-sandbox/"
    end
end

# Valid: non-empty, only A-Z a-z 0-9 . _ -, not starting with "-" or "." (so "." and ".." can never match).
function __claude_sandbox_valid_name
    string match -qr '^[A-Za-z0-9_][A-Za-z0-9._-]*$' -- "$argv[1]"
end

# Existing sandbox names, one per line.
function __claude_sandbox_names
    set -l base (__claude_sandbox_base)
    for d in $base*/
        test -d $d; or continue
        string replace -- $base '' (string replace -r '/$' '' -- $d)
    end
end

# Prompt segment: "(Sandbox: <name>) " while a sandbox is active, empty otherwise.
function claude_sandbox_prompt
    set -l base (__claude_sandbox_base)
    string match -q -- "$base*" "$CLAUDE_CONFIG_DIR"; or return 0
    set_color magenta
    printf '(Sandbox: %s) ' (string replace -- $base '' $CLAUDE_CONFIG_DIR)
    set_color normal
end

function claude-sandbox -d "Switch to an isolated Claude Code config"
    set -l base (__claude_sandbox_base)

    switch "$argv[1]"
        case "" -h --help
            echo "Usage: claude-sandbox <name>"
            echo "       claude-sandbox -c [name] | exit | -l | -d <name> | -h"
            echo
            echo "  <name>      Switch to the existing sandbox <name>"
            echo "  -c [name]   Create sandbox [name] (default: current date/time) and switch to it"
            echo "  exit        Leave the active sandbox"
            echo "  -l          List sandboxes (* = active)"
            echo "  -d <name>   Delete sandbox <name> (asks for confirmation)"
            echo "  -h          Show this help"
            echo
            echo "Sandbox = isolated CLAUDE_CONFIG_DIR, active in the current shell only."
            echo "Allowed name characters: A-Z a-z 0-9 . _ -  (must not start with - or .)"

        case exit
            if test -z "$CLAUDE_CONFIG_DIR"
                echo "No sandbox active." >&2
                return 1
            end
            set -e CLAUDE_CONFIG_DIR
            echo "Left sandbox."

        case -l
            for n in (__claude_sandbox_names)
                if test "$base$n" = "$CLAUDE_CONFIG_DIR"
                    echo "* $n"
                else
                    echo "  $n"
                end
            end

        case -d
            set -l name "$argv[2]"
            if not __claude_sandbox_valid_name "$name"
                echo "Usage: claude-sandbox -d <name> (allowed: A-Z a-z 0-9 . _ -)" >&2
                return 1
            end
            set -l dir "$base$name"
            if not test -d "$dir"
                echo "Sandbox '$name' not found." >&2
                return 1
            end
            read -l -P "Delete $dir? [y/N] " reply
            if not contains -- "$reply" y Y
                echo "Aborted."
                return 1
            end
            rm -rf -- "$dir"
            test "$dir" = "$CLAUDE_CONFIG_DIR"; and set -e CLAUDE_CONFIG_DIR
            echo "Deleted sandbox '$name'."

        case -c
            set -l name "$argv[2]"
            test -n "$name"; or set name (date +%Y-%m-%d_%H-%M)
            if not __claude_sandbox_valid_name "$name"
                echo "Invalid name (allowed: A-Z a-z 0-9 . _ -, must not start with - or .)" >&2
                return 1
            end
            set -l dir "$base$name"
            if test -e "$dir"
                echo "Sandbox '$name' already exists. Switch to it with: claude-sandbox $name" >&2
                return 1
            end
            mkdir -p -- "$dir"; or return 1
            set -gx CLAUDE_CONFIG_DIR "$dir"
            echo "Created sandbox '$name'."

        case '*'
            set -l name "$argv[1]"
            if not __claude_sandbox_valid_name "$name"
                echo "Invalid name (allowed: A-Z a-z 0-9 . _ -, must not start with - or .)" >&2
                return 1
            end
            set -l dir "$base$name"
            if not test -d "$dir"
                echo "Sandbox '$name' not found. Create it with: claude-sandbox -c $name" >&2
                return 1
            end
            set -gx CLAUDE_CONFIG_DIR "$dir"
            echo "Switched to sandbox '$name'."
    end
end

# Tab completion: sandbox names and options; only names after -d.
function __claude_sandbox_arg_count
    count (commandline -opc)
end

function __claude_sandbox_after_d
    set -l tokens (commandline -opc)
    test (count $tokens) -eq 2; and test "$tokens[2]" = -d
end

complete -c claude-sandbox -f
complete -c claude-sandbox -n 'test (__claude_sandbox_arg_count) -eq 1' -a exit -d 'Leave the active sandbox'
complete -c claude-sandbox -n 'test (__claude_sandbox_arg_count) -eq 1' -s c -d 'Create a sandbox'
complete -c claude-sandbox -n 'test (__claude_sandbox_arg_count) -eq 1' -s l -d 'List sandboxes'
complete -c claude-sandbox -n 'test (__claude_sandbox_arg_count) -eq 1' -s d -d 'Delete a sandbox'
complete -c claude-sandbox -n 'test (__claude_sandbox_arg_count) -eq 1' -s h -d 'Show help'
complete -c claude-sandbox -n 'test (__claude_sandbox_arg_count) -eq 1; or __claude_sandbox_after_d' -a '(__claude_sandbox_names)' -d Sandbox
