# CLAUDE.md

This project makes setting up Claude Code on Windows easier. See [README.md](README.md) for full installation instructions.

## Single Workflow Principle

All scripts in this project are designed around a single, powerful, successful workflow: **an elevated PowerShell prompt**.

Scripts detect when they are run from the wrong environment (e.g., double-clicked from Explorer, run from cmd.exe, or run without admin privileges) and redirect the user to the correct workflow rather than attempting to work around limitations. This avoids partial installs, confusing errors, and divergent paths.

## Project Structure

- `bin/install-claude-code.bat` — Main installer. Installs Chocolatey, Windows Terminal, Claude Code, and configures Git identity.
- `bin/configure-git-windows.bat` — Configures Git for cross-platform compatibility.
- `bin/install-gh.bat` — Installs the GitHub CLI.
