# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a workshop preparation repository for teaching engineers how to use Claude Code effectively. The main deliverable is `claude-code-guide.html`, a comprehensive, self-contained operational manual covering all Claude Code features.

## Main File

**`claude-code-guide.html`** - Complete Claude Code operational manual
- Self-contained single HTML file with embedded CSS (no external dependencies)
- Designed with "Terminal Elegance" aesthetic (dark theme, JetBrains Mono + Cormorant Garamond fonts, terminal-inspired UI)
- Sections: Core Tools, Subagents, Skills, LSP, Memory, Slash Commands, Hooks, Workflows, Best Practices, Quick Reference
- Can be opened directly in any browser for workshop presentations

## Viewing the Guide

```bash
# Open in default browser (Windows)
start claude-code-guide.html

# Or use any browser directly
chrome claude-code-guide.html
firefox claude-code-guide.html
```

## Design Philosophy

The HTML guide follows these principles:
- **Terminal Elegance aesthetic**: Dark theme with cyan/amber/green accents, animated noise texture, terminal-inspired elements
- **Production-grade styling**: CSS variables, responsive design, accessibility support (prefers-reduced-motion)
- **No external dependencies**: All fonts loaded via Google Fonts CDN, all styles embedded
- **Interactive elements**: Hover effects, animated cards, sticky navigation, smooth transitions

## Workshop Context

This repository was created to prepare materials for a 45-minute Claude Code workshop for senior engineers. The HTML guide serves as both:
1. A reference during the workshop
2. A take-home resource for attendees

## Installed Claude Code Plugins

The following plugins are configured in this environment (see `.claude/settings.local.json` for permissions):

- `agent-sdk-dev` - Build custom agents
- `code-review` - Code quality analysis
- `commit-commands` - Git commit workflow
- `frontend-design` - UI/UX design skill (used to create the guide's aesthetic)
- `hookify` - Create and manage hooks
- `plugin-dev` - Develop plugins
- `pr-review-toolkit` - PR review automation
- `typescript-lsp` - TypeScript/JavaScript language server

TypeScript language server is installed globally: `typescript-language-server` and `typescript` v5.9.3

## Permissions

Pre-approved bash commands (configured in `.claude/settings.local.json`):
- `claude plugin *` - Plugin management commands
- `typescript-language-server *` - LSP operations
- `tsc *` - TypeScript compilation
- `npm install *` - Package installation
