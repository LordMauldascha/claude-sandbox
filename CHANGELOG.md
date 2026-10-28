# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0](https://github.com/LordMauldascha/claude-sandbox/releases/tag/v0.2.0) - 2026-10.28

### Added

- `install.sh` to install a release with one command (`--version`, `--shell`, `--modify-rc`).

## [0.1.0](https://github.com/LordMauldascha/claude-sandbox/releases/tag/v0.1.0) - 2026-10-28

### Added

- `claude-sandbox <name>` switches the current shell to an existing sandbox by setting `CLAUDE_CONFIG_DIR`.
- `claude-sandbox -c [name]` creates a sandbox and switches to it (default name: current date and time).
- `claude-sandbox exit` leaves the active sandbox.
- `claude-sandbox -l` lists sandboxes and marks the active one.
- `claude-sandbox -d <name>` deletes a sandbox after confirmation.
- `claude_sandbox_prompt` prompt segment that shows `(Sandbox: <name>)` while a sandbox is active.
- Tab completion for sandbox names and options.
- bash (3.2+) and zsh support in `shell/claude-sandbox.sh`, fish support in `shell/claude-sandbox.fish`.
- `claude-sandbox.plugin.zsh` entry point for zsh plugin managers.
- `CLAUDE_SANDBOX_ROOT` to change the sandbox directory (default: `~/claude-sandbox`).
