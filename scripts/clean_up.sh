#!/bin/sh

git switch ci
commit_index="$(cat next_index)"

git switch --orphan tmp_ci
echo "$commit_index" > commit_index
git commit --message "Reset commit index"

git switch ci
git reset --hard tmp_ci
git push --force

git switch --orphan tmp_pre
git commit --allow-empty --allow-empty-message
git switch pre
git reset --hard tmp_pre
git push --force
