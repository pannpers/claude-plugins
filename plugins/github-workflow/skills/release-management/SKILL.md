---
name: release-management
description: Cut a Semantic Versioning release on GitHub. Choose the version bump from the commits since the last tag, update the version files and changelog, create an annotated tag and a GitHub Release with gh, after checking which CI workflows a tag or release would trigger. Use it only when the user explicitly asks to release, tag a version, cut vX.Y.Z or publish a package ("リリースして", "tag v2.1.0"); not for ordinary commits, and not for discussing version bumps inside a PR.
user-invocable: false
---

# Release

A release is public and hard to take back: once a tag is pushed, people and CI pipelines may already have pulled it. So decide the version carefully, and check what publishing will set off before you push anything.

## 0. Read the repository's release process

Check `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md` and `RELEASING.md` for a documented process (release branches, a release tool such as release-please or changesets, a changelog format). If the repository uses a release tool, use that tool instead of tagging by hand; tagging around it leaves the tool's state wrong.

## 1. Choose the version

Find the latest release tag (`git describe --tags --abbrev=0`) and read every commit since it (`git log <tag>..HEAD --oneline`). Take the highest bump that any commit requires:

| Bump | When |
|---|---|
| MAJOR (`v1.2.3` → `v2.0.0`) | A breaking change: removed or renamed public API, changed signatures or defaults, dropped configuration, data changes that clients must follow. Conventional Commits mark these with `!` or a `BREAKING CHANGE:` footer. |
| MINOR (`v1.2.3` → `v1.3.0`) | New backward-compatible features (`feat`). |
| PATCH (`v1.2.3` → `v1.2.4`) | Only fixes, performance, docs or internal changes. |

Before 1.0.0, many projects put breaking changes in MINOR; follow the project's history. Pre-releases take a suffix (`-alpha.N`, `-beta.N`, `-rc.N`). Never reuse a version number, and do not skip one: tools that resolve versions assume both.

Tell the user the version you chose and the commits that decided it.

## 2. Update version files and the changelog

Bump the version wherever the repository records it (`package.json`, `pyproject.toml`, `Cargo.toml`, a version constant). If there is a `CHANGELOG.md`, add the release in its existing format. Commit this as `chore(release): vX.Y.Z` on the branch the repository releases from, through a PR if that branch is protected.

## 3. Check what a tag or release triggers

Search the workflows for tag and release triggers:

```bash
grep -rnE "tags:|release:|workflow_run" .github/workflows/
```

A workflow that runs on `push: tags` or `release: published` may publish packages (npm, PyPI, a container registry, a schema registry) the moment you push. Tell the user what will run. Unless the user has already said to go ahead with the publish, ask before pushing the tag. A published package version usually cannot be replaced, only deprecated.

## 4. Tag and publish the release

```bash
git tag -a vX.Y.Z -m "vX.Y.Z"
git push origin vX.Y.Z
gh release create vX.Y.Z --verify-tag --title "vX.Y.Z" --generate-notes
```

- `--generate-notes` builds the notes from the merged PRs since the previous tag. To write the notes yourself, put them in a temporary file (`notes=$(mktemp)`) and pass `--notes-file "$notes"` instead.
- Add `--prerelease` for pre-release versions.
- `--verify-tag` stops the release if the tag did not reach the remote.

Confirm with `gh release view vX.Y.Z`, then report the release link, and the status of any publish workflow it started (`gh run list --event push --limit 5`).
