#!/bin/sh

title="$1"
current_branch="$(git rev-parse --abbrev-ref HEAD)"
target_branch="${2:-"$current_branch"}"

if [ "$target_branch" != "$current_branch" ]; then
	echo "Setting up worktree for branch \"$target_branch\"..."
	git fetch origin "$target_branch":"$target_branch" 
	git worktree add "$target_branch"
	cd "$target_branch"
fi

git remote set-url origin "https://$CI_REPO_OWNER:$ACCESS_TOKEN@codeberg.org/$CI_REPO.git"
git config --global user.name "$CI_COMMIT_AUTHOR"
git config --global user.email "$CI_COMMIT_AUTHOR_EMAIL"

echo "Changes:"
git status --short --ignore-submodules=dirty
git add --all && git commit --file - <<EOF
$title

Commit generated by Woodpecker CI:
  * Build #$CI_BUILD_NUMBER
  * Parent build #$CI_BUILD_PARENT
  * CI job #$CI_JOB_NUMBER
EOF

while : ; do
	git push --quiet --set-upstream origin "$target_branch" && break
	git pull --quiet
done
