# Claude Windows Setup

Scripts to set up [Claude Code](https://docs.anthropic.com/en/docs/claude-code) on Windows with minimal friction.

## Quick Start

1. Open **PowerShell as Administrator** (press Win+X, then select "Terminal (Admin)")
2. Paste and run:
   ```powershell
   irm https://raw.githubusercontent.com/kitaekatt/claude-windows-setup/main/setup.ps1 | iex
   ```
3. When prompted, press Enter to accept the default install directory (`%USERPROFILE%\claude-windows-setup`) or type a custom path.

This will download the project, then install Chocolatey (if needed), Node.js (if needed), Claude Code, and configure your Git identity (if not already set). No Git or GitHub account required.

Once complete, run `claude` to start Claude Code.

## Additional Scripts

These scripts are available in the install directory after running the Quick Start above.

### bin\configure-git-windows.bat

Configures Git for cross-platform compatibility. Run from an elevated PowerShell prompt:

```
.\bin\configure-git-windows.bat
```

This applies the following settings:

- **Line endings**: `core.autocrlf input` — converts CRLF to LF on commit
- **Long paths**: `core.longpaths true` + OS-level registry key
- **Case sensitivity**: `core.ignorecase false` — tracks filename case changes
- **File permissions**: `core.filemode false` — ignores Unix permission bits
- **Symlinks**: `core.symlinks true` — enables symlink support
- **Developer Mode**: Enables Windows Developer Mode (required for symlinks)

### bin\install-gh.bat

Installs the [GitHub CLI](https://cli.github.com/) via Chocolatey. Run from an elevated PowerShell prompt:

```
.\bin\install-gh.bat
```

After installation, authenticate with `gh auth login`.

## Requirements

- Windows 10 or 11
- All scripts must be run from an **elevated PowerShell** prompt
