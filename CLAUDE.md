# brave-core-tools

Developer tools, best practices, and Claude Code skills for brave-core development.

## Best Practices

Before making changes to brave-core, read the relevant best practices:

- **[BEST-PRACTICES.md](./BEST-PRACTICES.md)** - Index of all best practices (testing, coding standards, architecture, build system, chromium_src). Read the sub-docs relevant to your work.
- **[SECURITY.md](./SECURITY.md)** - Security guidelines

## Skills

14 developer-facing skills are in `.claude/skills/`. After running `./setup.sh`, they're available as slash commands when working in `src/brave/`.

## Scripts

- `scripts/check-upstream-flake.py` — Check LUCI Analysis for upstream Chromium test flakiness
- `scripts/top-crashers.py` — Query Backtrace crash reporting data
- `scripts/manage-bp-ids.py` — Manage stable IDs in best-practice documents
