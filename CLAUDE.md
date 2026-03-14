# Poco - Claude Code Instructions

## Project
Mac用メニューバー常駐型TODOメモアプリ "Poco"

## Specs
- See docs/requirements.md for requirements
- See docs/spec.md for functional specification

## Superpowers Skills
Skills are available at: /Users/hyunosuk-server/Projects/superpowers/skills/

Use these skills as appropriate:
- writing-plans: when creating implementation plans
- test-driven-development: for TDD approach
- executing-plans: when implementing from a plan
- systematic-debugging: for debugging issues
- verification-before-completion: before marking tasks done
- finishing-a-development-branch: when finalizing work

## Tech Stack
- Swift + SwiftUI
- Core Data (local storage)
- CGEventTap (global shortcut)
- NSStatusItem (menu bar)

## Key Constraints
- macOS 13+ target
- No iCloud sync
- No Dock icon (LSUIElement = YES)
- Sticky note window level: .desktopIcon + 1

## Git Workflow
Always work on a branch, open a PR, and merge via review. Never commit directly to `main`.

### Branch Naming
Format: `prefix/issue_<number>/short-description` (omit issue part if no issue)
- All English, lowercase, hyphen `-` or underscore `_` as separator

| prefix | use |
|--------|-----|
| feature | new feature |
| fix | bug fix |
| update | improvement to existing feature |
| refactor | refactoring |
| chore | config/dependency tasks |
| docs | documentation changes |

Examples:
- `feature/issue_234/custom-notification-timing`
- `fix/issue_12/milestone-sort-layout`
- `chore/add-cursor-rules`

### Commit Messages
Format: `prefix: short description` (single line only, no body or footer)
- English only

| prefix | use |
|--------|-----|
| feat | new feature |
| fix | bug fix |
| update | improvement to existing feature |
| refactor | code improvement without behavior change |
| style | formatting (no behavior impact) |
| docs | documentation only |
| test | add/fix tests |
| chore | build config, dependency updates |
| del | delete file/feature |
| perf | performance improvement |
| ci | CI/CD config changes |

Examples:
- `feat: add custom notification timing setting`
- `fix: correct notification schedule time offset`
- `chore: add cursor rules`

### Pull Request Template
When creating a PR, use this format:

```
## 概要
（この PR で何をしたか、1〜2 文で）

## 変更内容
- 変更点1
- 変更点2

## 変更理由
- なぜこの変更が必要か

## 動作確認方法
1. 手順1
2. 手順2

## 備考（任意）
- 補足事項があれば
```
