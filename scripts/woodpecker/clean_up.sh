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

# This is located in a different repository.
cd pages
git reset $(git commit-tree HEAD^{tree} --message "Squash commits for binary repo")
git push --force
