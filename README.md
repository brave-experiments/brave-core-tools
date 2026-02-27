# brave-core-tools

Shared development tools, best practices, and Claude Code skills for [brave-core](https://github.com/AurWoworuntariawan/AurWoworuntariawan-brave-core/) development.

## Setup

Clone into your `brave-browser` directory (as a sibling of `src/`):

```bash
cd brave-browser
git clone https://github.com/brave-experiments/brave-core-tools.git
cd brave-core-tools
./setup.sh
```

This will:
1. Symlink skills to `src/brave/.claude/skills/`
2. Symlink best practices to `src/brave/.claude/rules/best-practices`

## What's Included

### Skills

| Skill | Description |
|-------|-------------|
| `/check-best-practices` | Audit branch changes against best practices |
| `/check-milestones` | Check/fix milestones on PRs and issues |
| `/check-upstream-flake` | Check LUCI Analysis for upstream test flakiness |
| `/clean-branches` | Delete local branches whose PRs are merged |
| `/commit` | Create atomic git commits |
| `/force-push-downstream` | Force-push branch + all downstream branches |
| `/impl-review` | Implement PR review feedback |
| `/make-ci-green` | Re-run failed CI jobs |
| `/pr` | Create a pull request for the current branch |
| `/preflight` | Run all preflight checks (format, build, test) |
| `/rebase-downstream` | Rebase a tree of dependent branches |
| `/review` | Code review (PR or local changes) |
| `/top-crashers` | Query Backtrace for top crash data |
| `/uplift` | Cherry-pick fixes to beta/release branches |

### Best Practices

16 best-practice documents covering coding standards, testing, architecture, build system, Android, iOS, frontend, and more. See [BEST-PRACTICES.md](BEST-PRACTICES.md) for the full index.

### Scripts

- `scripts/check-upstream-flake.py` — Check Chromium LUCI Analysis for upstream test flakiness
- `scripts/top-crashers.py` — Query Backtrace crash reporting
- `scripts/manage-bp-ids.py` — Manage stable IDs in best-practice documents

## Updating

```bash
cd brave-core-tools
git pull origin main
```

Symlinks are stable across updates — no need to re-run setup.
