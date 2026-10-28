# Contributing

Thanks for your interest in claude-sandbox! Bug reports, fixes and small improvements are welcome.

## Before you start

For anything bigger than a bug fix, please open an issue first so we can agree on the approach. The tool is intentionally small: it switches `CLAUDE_CONFIG_DIR` and nothing more.

## How the code is organised

| File | Purpose |
| --- | --- |
| `shell/claude-sandbox.sh` | bash and zsh implementation (one shared file) |
| `shell/claude-sandbox.fish` | fish implementation |
| `claude-sandbox.plugin.zsh` | entry point for zsh plugin managers |
| `install.sh` | installer (POSIX `sh`) |
| `test/` | tests for each shell |

## Rules for changes

- **Keep the three shells in sync.** A behaviour change in `claude-sandbox.sh` needs the same change in `claude-sandbox.fish`, including help text and completion.
- **bash 3.2 compatibility.** macOS still ships bash 3.2: no associative arrays, no `mapfile`, no `${var,,}`.
- **Sandbox names are validated** (`A-Z a-z 0-9 . _ -`, no leading `-` or `.`). `-d` runs `rm -rf`, so never loosen this check and never build deletion paths from unvalidated input.
- `install.sh` must stay POSIX `sh` and must not modify files outside its install directory unless `--modify-rc` is given.
- Update `CHANGELOG.md` under `[Unreleased]` and the README if behaviour or options change.

## Running the tests

Run from the repository root. You need the shells you want to test:

```sh
bash test/test.sh
zsh test/test.sh
fish test/test.fish
shellcheck -x -s bash shell/claude-sandbox.sh test/test.sh
shellcheck install.sh
```

Tests use a temporary `HOME`, so they never touch your real sandboxes or configuration. The same checks run in GitHub Actions on Linux and macOS for every push and pull request.

## Pull requests

- Keep each pull request focused on one change.
- Add or adjust tests for new behaviour. Test cases in `test/test.sh` and `test/test.fish` mirror each other.
- Make sure CI is green.
