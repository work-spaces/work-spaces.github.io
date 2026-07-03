---
title: Understanding Dev Branches
toc: true
weight: 3
---

A `spaces` workspace typically contains multiple repositories — your own project code alongside SDK repos, packages, and other dependencies. Development branches (**dev-branches**) let `spaces` distinguish between repos you are actively developing and repos that should stay pinned to specific revisions (branches/tags/commits).

## Creating Dev Branches

When you pass `--new-branch` during checkout, `spaces` creates a new git branch in the matching repo(s) and marks them as **dev-branches**:

```sh
spaces checkout-repo \
  --url=https://github.com/work-spaces/spaces \
  --rev=main \
  --new-branch=spaces \
  --name=fix-parser-bug
```

This checks out the `spaces` repository at `main`, then creates a new branch in the `spaces` repo. The workspace folder and new branch are named `fix-parser-bug`.

In `co.spaces.toml`, the same concept looks like this:

```toml
[fix-parser-bug.Repo]
url = "https://github.com/work-spaces/spaces"
rev = "main"
new-branch = ["spaces"]
```

Any repo that receives a new branch during checkout is treated as a **dev-branch** for the lifetime of the workspace.

For more information, see [`Repo Checkout and Sync`](/docs/explainers/repo-checkout-and-sync/)
