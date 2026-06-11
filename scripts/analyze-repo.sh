#!/bin/bash
# Analyze a single repo in detail
# Usage: ./scripts/analyze-repo.sh /path/to/repo

REPO_DIR="$1"

if [ -z "$REPO_DIR" ] || [ ! -d "$REPO_DIR/.git" ]; then
    echo "Usage: ./scripts/analyze-repo.sh /path/to/repo"
    exit 1
fi

# Basic info
name=$(basename "$REPO_DIR")
remote=$(git -C "$REPO_DIR" remote get-url origin 2>/dev/null || echo "")
branch=$(git -C "$REPO_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
last_commit=$(git -C "$REPO_DIR" log -1 --format="%H" 2>/dev/null || echo "")
last_date=$(git -C "$REPO_DIR" log -1 --format="%Y-%m-%d" 2>/dev/null || echo "")
last_message=$(git -C "$REPO_DIR" log -1 --format="%s" 2>/dev/null || echo "")
total_commits=$(git -C "$REPO_DIR" rev-list --count HEAD 2>/dev/null || echo "0")

# Count commits by current user
git_email=$(git config user.email 2>/dev/null || echo "")
my_commits=$(git -C "$REPO_DIR" log --author="$git_email" --oneline 2>/dev/null | wc -l | tr -d ' ')

# Detect tech
languages=$(git -C "$REPO_DIR" ls-files 2>/dev/null | sed 's/.*\.//' | sort | uniq -c | sort -rn | head -5)

echo "{\"name\":\"$name\",\"path\":\"$REPO_DIR\",\"remote\":\"$remote\",\"branch\":\"$branch\",\"last_commit\":\"$last_commit\",\"last_date\":\"$last_date\",\"last_message\":\"$last_message\",\"total_commits\":\"$total_commits\",\"my_commits\":\"$my_commits\",\"git_email\":\"$git_email\"}"
echo "Languages:"
echo "$languages"
