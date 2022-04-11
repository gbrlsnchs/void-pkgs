#!/bin/sh

git worktree remove /tmp/ci
git fetch origin ci:ci && git switch ci
commit_index="$(cat next_index)"

git switch --orphan tmp_ci
echo "$commit_index" > commit_index
git add commit_index && git commit --message "Reset commit index"

git switch ci
git reset --hard tmp_ci
git push --force --set-upstream origin ci

git worktree remove pages
git switch --orphan tmp_pages
git fetch origin pages:pages
git cherry-pick pages
git switch pages
git reset --hard tmp_pages
git push --force --set-upstream origin pages
