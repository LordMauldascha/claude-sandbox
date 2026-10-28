# claude-sandbox

Try out [Claude Code](https://claude.com/claude-code) plugins, skills, hooks and settings without touching your real configuration.

`claude-sandbox` points `CLAUDE_CONFIG_DIR` at a throwaway directory, so everything Claude Code reads and writes (settings, plugins, skills, history, credentials) stays inside that sandbox. Leave it, delete it, and your real setup is exactly as you left it.

```console
$ claude-sandbox -c plugin-test
Created sandbox 'plugin-test'.
(Sandbox: plugin-test) $ claude          # fresh config, nothing from ~/.claude
(Sandbox: plugin-test) $ claude-sandbox exit
Left sandbox.
$ claude                                 # back to your real config
```

- Works in **bash** (3.2+, so also stock macOS), **zsh** and **fish**
- Runs on **macOS and Linux**
- Sandbox is active **in the current shell only**; other terminals are unaffected
- Tab completion for sandbox names and options
- Optional prompt segment that shows which sandbox is active

## Installation

`claude-sandbox` is a shell function, not a standalone program. A child process cannot change its parent shell's environment, so the function has to be loaded into your shell (the same reason `nvm` or `conda activate` work this way).

### Quick install

```sh
curl -fsSL https://raw.githubusercontent.com/LordMauldascha/claude-sandbox/main/install.sh | sh
```

This installs the latest release to `~/.local/share/claude-sandbox` and prints the one line you need to add to your shell startup file. Nothing outside the install directory is touched unless you add `--modify-rc`, which appends that line for you (for fish it links the file into `~/.config/fish/conf.d`). It is safe to run again to update:

```sh
curl -fsSL https://raw.githubusercontent.com/LordMauldascha/claude-sandbox/main/install.sh | sh -s -- --modify-rc
```

Other options: `--version <tag>` pins a release (or `main` for the development version) and `--shell bash|zsh|fish` overrides the detected shell. If you would rather read the script first, it is [`install.sh`](install.sh).

### Manual install

Clone the repository once:

```sh
git clone https://github.com/LordMauldascha/claude-sandbox ~/.local/share/claude-sandbox
```

Then load it from your shell's startup file.

### bash

```sh
echo 'source ~/.local/share/claude-sandbox/shell/claude-sandbox.sh' >> ~/.bashrc
```

(On macOS, Terminal opens login shells; use `~/.bash_profile` if you do not already source `~/.bashrc` from it.)

### zsh

```sh
echo 'source ~/.local/share/claude-sandbox/shell/claude-sandbox.sh' >> ~/.zshrc
```

Completion needs `compinit`. If your `.zshrc` has not run it yet at that point, the script runs it for you.

Plugin managers work too, since the repository ships a `claude-sandbox.plugin.zsh`:

```sh
antidote bundle LordMauldascha/claude-sandbox   # antidote
zinit light LordMauldascha/claude-sandbox       # zinit
```

### fish

```fish
ln -s ~/.local/share/claude-sandbox/shell/claude-sandbox.fish ~/.config/fish/conf.d/claude-sandbox.fish
```

Open a new terminal afterwards (or `source` the file) to start using it.

## Usage

```
claude-sandbox <name>        Switch to the existing sandbox <name>
claude-sandbox -c [name]     Create sandbox [name] and switch to it (default: current date/time)
claude-sandbox exit          Leave the active sandbox
claude-sandbox -l            List sandboxes (* = active)
claude-sandbox -d <name>     Delete sandbox <name> (asks for confirmation)
claude-sandbox -h            Show help
```

Sandbox names may contain `A-Z a-z 0-9 . _ -` and must not start with `-` or `.`. `claude-sandbox <name>` only switches to a sandbox that already exists; use `-c` to create one. `-c` without a name uses the current date and time (for example `2026-10-28_20-45`).

Each sandbox is a plain directory, `<root>/<name>` (default `~/claude-sandbox/<name>`), so you can inspect or copy files in it at any time.

## Show the active sandbox in your prompt

The tool never changes your prompt on its own. Instead it provides `claude_sandbox_prompt`, which prints `(Sandbox: <name>) ` in magenta while a sandbox is active and nothing otherwise. Add it to your prompt once:

**bash**

```sh
PS1='$(claude_sandbox_prompt)'"$PS1"
```

**zsh**

```sh
setopt PROMPT_SUBST
PROMPT='$(claude_sandbox_prompt)'"$PROMPT"
```

**fish**

```fish
functions -c fish_prompt __original_fish_prompt
function fish_prompt
    claude_sandbox_prompt
    __original_fish_prompt
end
```

Put these lines after the `source` line (and, for fish, after any prompt customisation). With a prompt framework such as Starship or Powerlevel10k, add `claude_sandbox_prompt` as a custom segment there instead.

## Configuration

| Variable | Default | Meaning |
| --- | --- | --- |
| `CLAUDE_SANDBOX_ROOT` | `$HOME/claude-sandbox` | Directory that holds the sandboxes |

The variable is read each time you run a command, so just export it in your shell startup file (fish: `set -gx CLAUDE_SANDBOX_ROOT ~/somewhere`).

## How it works

Claude Code reads its configuration from the directory in `CLAUDE_CONFIG_DIR`. `claude-sandbox` creates `<root>/<name>` and exports that variable in your current shell; `exit` unsets it again. Nothing else is modified, and no files outside the sandbox directory are touched. Deleting a sandbox only ever removes `<root>/<name>` for a validated name (no slashes, no leading `.` or `-`).

## Repository layout

```
claude-sandbox.plugin.zsh     zsh plugin-manager entry point
shell/claude-sandbox.sh       bash + zsh implementation
shell/claude-sandbox.fish     fish implementation
```

## License

[MIT](LICENSE)
