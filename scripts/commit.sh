#!/bin/sh

title="$1"
current_branch="$(git rev-parse --abbrev-ref HEAD)"
target_branch="${2:-"$current_branch"}"

if [ "$target_branch" != "$current_branch" ]; then
	cd "$target_branch" || exit 1
fi

if [ "$CI_PUBLISH_BINS" = "1" ]; then
	CI_HOST="github.com"
	CI_REPO="void-bins"
	ACCESS_TOKEN="$BINREPO_TOKEN"
	target_branch="$current_branch"
fi

repo_host="${CI_HOST:-"codeberg.org"}"

git remote set-url origin "https://$CI_REPO_OWNER:$ACCESS_TOKEN@$repo_host/$CI_REPO.git"
git config --global user.name "$CI_COMMIT_AUTHOR"
git config --global user.email "$CI_COMMIT_AUTHOR_EMAIL"

echo "Changes:"
git status --short --ignore-submodules=dirty
git add --all || exit 0

if [ -f "$title" ]; then
	git commit --file "$title"
else
	git commit --file - <<EOF
$title

Commit generated by Woodpecker CI:
  * Build #$CI_BUILD_NUMBER
  * CI job #$CI_JOB_NUMBER
EOF
fi

git branch --set-upstream-to origin/"$target_branch"

# Handles parallel jobs trying to commit to the same branch.
while : ; do
	git push --quiet && break
	git pull --rebase --quiet
done
