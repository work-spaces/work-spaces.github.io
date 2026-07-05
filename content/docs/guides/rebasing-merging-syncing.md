---
title: Rebasing, Merging, and Syncing
toc: true
weight: 4
---

Use `spaces sync` to keep your workspace up to date.

{{< callout type="info" >}}
`spaces sync` updates [dev-branches](/docs/explainers/understanding-dev-branches/) by rebasing them on their target upstream branch (or merging if configured). You do **not** need to manually run `git fetch` + `git rebase` before syncing. But you can if you want to.
{{< /callout >}}

{{% steps %}}

### Create a Workspace with a **dev-branch**

```sh
spaces co my-project fix-the-bug --new-branch=my-project
cd fix-the-bug
```

See [Using spaces co](/docs/guides/using-co/) for details on `co.spaces.toml`.

### Develop Normally

Make changes, commit, and push on your dev branch.

### Sync to Integrate with Upstream Changes

```sh
spaces sync
```

If you have local uncommitted changes, use:

```sh
spaces sync --stash
```

If you want to start development on another repo in the workspace, use:

```sh
spaces sync --new-branch=my-repo-in-workspace
```

### Develop as Usual

```sh
spaces run //my-project:build
spaces run //:test
```

{{% /steps %}}


For detailed sync behavior and advanced options, see [Repo Checkout and Sync](/docs/explainers/repo-checkout-and-sync/).

## Multiple Dev Branches

You can create [dev branches](/docs/explainers/understanding-dev-branches/#creating-dev-branches) in multiple repos within the same workspace. Pass multiple entries in `new-branch`:

```sh
spaces checkout-repo \
  --url=https://github.com/my-org/my-workspace \
  --rev=main \
  --new-branch=my-lib \
  --new-branch=my-app \
  --name=cross-cutting-change
```

Or in `co.spaces.toml`:

```toml
[cross-cutting.Repo]
url = "https://github.com/my-org/my-workspace"
rev = "main"
new-branch = ["my-lib", "my-app"]
```

Both `my-lib` and `my-app` are treated as dev branches and are updated during `spaces sync` (rebase by default, or merge if configured).

## Promoting a Repo to a Dev Branch

Run `spaces sync --dev-branch=<path to the repo in the workspace>` to promote a repo to a dev branch. Use `spaces sync --new-branch=<path to the repo in the workspace>` if you haven't already created a local branch.

After promotion, `spaces sync` will treat that repo as a **dev-branch** and include it in ***dev-branch** sync behavior (rebase by default, or merge if configured).
