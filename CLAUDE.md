# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a personal dotfiles repository optimized for macOS Sequoia 15.x that manages configuration files for various development tools through symbolic links.

## Key Commands

### Bootstrap and Setup
- **Install dotfiles**: `./scripts/bootstrap/bootstrap-dotfiles.sh` - Creates symbolic links from `configs/` to `~/.config/` locations
- **Install Oh My Zsh**: `./scripts/bootstrap/bootstrap-omz.sh` - Installs and configures Oh My Zsh
- **Install pre-commit hooks**: `pre-commit install` (after bootstrap script completes)

### Fortune Files Management
- **Generate fortune .dat files**: `cd configs/fortune && ./strfile.sh` - Processes all .fortune files in the fortune directory
- **Manual fortune generation**: `strfile <fortune_file>` for individual files
- **Note**: `.dat` files are auto-generated via pre-commit hooks when `.fortune` files are modified

### Package Management
- **Backup/restore packages**: `./scripts/package-managers/manage-krew-brew.sh` - Interactive script for:
  - Option 1: Backup krew plugins to `configs/krew/Krewfile`
  - Option 2: Restore krew plugins from backup
  - Option 3: Create Brewfile with package counts summary

### Git Operations
- **Clone repositories**: `./scripts/git/clone-all.sh`
- **Clean commit history**: `./scripts/git/commit-history-cleaner.sh`

## Architecture

### Configuration Structure
The repository follows a centralized config approach:
- `configs/` contains all dotfile configurations organized by tool
- Bootstrap script creates symbolic links from configs to standard locations (`~/.config/`, `~/.gnupg/`, etc.)
- Each tool has its own subdirectory with tool-specific configurations

### Key Components
- **Bootstrap system**: Automated symbolic link creation with preview and confirmation
- **Fortune management**: Custom fortune files with automated .dat generation via pre-commit hooks
- **Package management**: Unified backup/restore for both Homebrew and kubectl krew
- **Pre-commit automation**: Automatically generates .dat files when .fortune files are modified

### Pre-commit Hook Behavior
The repository uses a local pre-commit hook that:
- Triggers on any .fortune file changes in `configs/fortune/`
- Automatically runs `strfile` to generate corresponding .dat files
- Ensures fortune databases stay synchronized with source files

## File Structure and Linking System

The repository uses a centralized symbolic linking approach where:
- Source configurations live in `configs/<tool>/` 
- The bootstrap script (`./scripts/bootstrap/bootstrap-dotfiles.sh`) creates symlinks to standard locations
- Target locations include `~/.config/`, `~/.gnupg/`, and specific dotfiles like `~/.zshrc`
- The COMPONENTS array in bootstrap-dotfiles.sh:5-17 defines all symlink mappings

## Development Workflow

When modifying configurations:
1. Edit files in `configs/<tool>/` directories (never edit the symlinked versions)
2. For fortune files: Only edit `.fortune` files - `.dat` files are auto-generated
3. Test changes by running the bootstrap script to verify symlinks
4. Use `pre-commit install` after any repository setup to enable automated fortune processing

## Important Notes

- The dotfiles are structured for macOS Sequoia 15.x specifically
- Always run the bootstrap script to properly link configurations
- Fortune .dat files are auto-generated - modify only .fortune source files
- The manage-krew-brew.sh script provides interactive package management workflows
- Never edit symlinked files directly - always edit source files in `configs/`