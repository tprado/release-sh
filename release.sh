#! /bin/bash -eu

VERSION_FILE=version.txt
CHANGELOG_FILE=CHANGELOG.md

abort() {
  local msg="${1:?}"

  >&2 echo "error: $msg"
  exit 1
}

no_changelog_entry_for() {
  local version=${1:?}

  ! grep -q "^## \[$version\]" $CHANGELOG_FILE
}

release_version() {
  cat $VERSION_FILE | sed s/-SNAPSHOT//
}

bump_version() {
  local version=${1:?}
  local semantic_versioning="([0-9]+)\.([0-9]+)\.([0-9]+)"

  if [[ $version =~ $semantic_versioning ]]; then
    local major="${BASH_REMATCH[1]}"
    local minor="${BASH_REMATCH[2]}"
    local patch="${BASH_REMATCH[3]}"

    echo "$major.$minor.$((patch + 1))"
  else
    abort 'not using semantic versioning format'
  fi
}

commit_version() {
  local version=${1:?}

  echo $version > $VERSION_FILE
  git add $VERSION_FILE
  git commit -m "Update version $(cat $VERSION_FILE)"
}

release=$(release_version)
snapshot="$(bump_version $release)-SNAPSHOT"

if no_changelog_entry_for $release; then
  abort "no entry found in CHANGELOG for release $release"
fi

git pull --rebase origin master

commit_version $release
git tag $release
git push --tags origin master

commit_version $snapshot
git push origin master
