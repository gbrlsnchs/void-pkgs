#!/bin/sh

title="$1"
branch="${2:-"pages"}"

git config --global user.name "$CI_COMMIT_AUTHOR"
git config --global user.email "$CI_COMMIT_AUTHOR_EMAIL"

git switch --orphan prepare-ci
git add --all && git commit --file - <<EOF
$title

Commit generated by Woodpecker CI:
  * Build #$CI_BUILD_NUMBER
  * Parent build #$CI_BUILD_PARENT
  * CI job #$CI_JOB_NUMBER
EOF
git switch "$branch"
git merge --allow-unrelated-histories prepare-ci
git push --quiet --set-upstream origin "$branch"
