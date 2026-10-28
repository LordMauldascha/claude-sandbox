# Security Policy

## Supported versions

Only the latest release receives security fixes.

## Reporting a vulnerability

Please do **not** open a public issue for security problems. Report them privately through GitHub:

**[Report a vulnerability](https://github.com/LordMauldascha/claude-sandbox/security/advisories/new)**

Include what you found, how to reproduce it and which version you tested. This is a small project maintained in spare time, so I will respond as soon as I can and coordinate a fix and disclosure with you.

## What is in scope

claude-sandbox runs in your shell and deletes directories, so these areas matter most:

- `claude-sandbox -d`: deleting anything outside the sandbox root (path traversal, unvalidated names)
- `install.sh`: unintended file changes, unsafe handling of the download or of existing directories
- Command injection through sandbox names, environment variables or paths
