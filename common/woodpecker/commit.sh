#!/bin/sh

title="$1"
branch="${2:-"pages"}"

git switch --create "$branch" && git branch --set-upstream-to "origin/$branch"
git config --global user.name "$CI_COMMIT_AUTHOR"
git config --global user.email "$CI_COMMIT_AUTHOR_EMAIL"
git add --all && git commit --file - <<EOF
$title

Commit generated by Woodpecker CI:
  * Build #$CI_BUILD_NUMBER
  * Parent build #$CI_BUILD_PARENT
  * CI job #$CI_JOB_NUMBER
EOF
git push --force --quiet --set-upstream origin "$branch"
