---
title: Understanding Dev Branches
toc: true
weight: 3
---

A `spaces` workspace typically contains multiple repositories — your own project code alongside SDK repos, packages, and other dependencies. Dev branches let `spaces` distinguish between repos you are actively developing and repos that should stay pinned to specific revisions.

## Creating Dev Branches

When you pass `--new-branch` during checkout, `spaces` creates a new git branch in the matching repo(s) and marks them as **dev branches**:

```sh
spaces checkout-repo \
  --url=https://github.com/work-spaces/spaces \
  --rev=main \
  --new-branch=spaces \
  --name=fix-parser-bug
```

This checks out the `spaces` repository at `main`, then creates a new branch called `spaces` in that repo. The workspace folder and new branch are named `fix-parser-bug`.

The `--new-branch` argument accepts a list of `rule-name:branch-name` pairs. When only a branch name is given (no `:`), it applies to the top-level checkout repo. In `co.spaces.toml`, the same concept looks like this:

```toml
[fix-parser-bug.Repo]
url = "https://github.com/work-spaces/spaces"
rev = "main"
new-branch = ["spaces"]
```

Any repo that receives a new branch during checkout is treated as a dev branch for the lifetime of the workspace.

## What Makes Dev Branches Special

Dev branches represent repos where you are doing active work. `spaces` protects them from being modified by automated operations:

- **`spaces sync` skips dev branches.** Your local changes, commits, and branch state are never touched.
- **`spaces sync` skips dirty repos.** Non dev branches are left alone if they have uncommitted changes.
- **Non-dev, clean repos are updated.** Repos that are not dev branches and have no uncommitted changes are checked out to the revision specified in the checkout rules.

## How spaces sync Works

`spaces sync` re-runs the checkout rules for the workspace. For each repository in the workspace, it evaluates the repo's status:

```
For each repo in the workspace:
  if repo is a dev branch → skip
  if repo has uncommitted changes → skip
  otherwise → checkout to the revision specified in the rules
```

### Sync After Rebasing or Merging

Whenever you rebase or merge a dev branch from a remote, the checkout rules in that repo may have changed — new dependencies, updated tool versions, or different pinned revisions. After rebasing or merging, always run:

```sh
spaces sync
```

`spaces sync` re-evaluates the checkout rules and updates any non-dev, clean repos to match. Your dev branches are still skipped, but everything around them is brought up to date with the new state of the rules.

This applies any time the checkout rules change, whether from:

- Rebasing onto an updated `main`
- Merging a remote branch into your dev branch
- Pulling changes that modify `*spaces.star` files

If you skip `spaces sync` after a rebase or merge, your workspace may have stale dependencies that no longer match what the checkout rules specify.
