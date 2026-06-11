# AGENTS.md

This is a git-based project tracker. All project metadata, notes, and docs
are stored here in Markdown files — visible on GitHub.

## Structure

- `projects/<slug>/MAP.md` — status, role, repo URL, tags
- `projects/<slug>/README.md` — rich project description
- `projects/<slug>/docs/` — internal documentation
- `projects/<slug>/tasks/` — task tracking
- `projects/<slug>/notes/` — private notes
- `computers/<mac-id>.md` — registered machines and local paths

## Helper Scripts

```bash
./scripts/get-computer-id.sh          # Get this machine's ID
./scripts/scan-repos.sh ~/code        # Scan for git repos
./scripts/analyze-repo.sh /path/repo  # Analyze a single repo
```

## Config

This computer's config is at `~/.projectz.yaml`.
To reset: delete `~/.projectz.yaml` and run `/projectz init`.
