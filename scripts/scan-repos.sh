#!/bin/bash
# Scan directories for git repos and output JSON
# Usage: ./scripts/scan-repos.sh ~/Documents/workspace ~/code ~/projects

if [ $# -eq 0 ]; then
    # Default directories
    DIRS=("$HOME/Documents/workspace" "$HOME/code" "$HOME/projects" "$HOME/work")
else
    DIRS=("$@")
fi

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        continue
    fi
    # Find .git directories
    while IFS= read -r git_dir; do
        repo_dir=$(dirname "$git_dir")
        # Get repo info
        remote=$(git -C "$repo_dir" remote get-url origin 2>/dev/null || echo "")
        branch=$(git -C "$repo_dir" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        last_commit=$(git -C "$repo_dir" log -1 --format="%H" 2>/dev/null || echo "")
        last_date=$(git -C "$repo_dir" log -1 --format="%Y-%m-%d" 2>/dev/null || echo "")
        total_commits=$(git -C "$repo_dir" rev-list --count HEAD 2>/dev/null || echo "0")
        name=$(basename "$repo_dir")

        if [ -n "$remote" ] || [ "$total_commits" -gt 0 ]; then
            echo "{\"name\":\"$name\",\"path\":\"$repo_dir\",\"remote\":\"$remote\",\"branch\":\"$branch\",\"last_commit\":\"$last_commit\",\"last_date\":\"$last_date\",\"total_commits\":\"$total_commits\"}"
        fi
    done < <(find "$dir" -name ".git" -type d 2>/dev/null)
done
