---
title: Using Spaces Co
toc: true
weight: 4
---

First, create a "workspaces" directory where you want to store all the workspaces you will checkout using `spaces`.

Inside your "workspaces" folder add a `co.spaces.toml` file with the list of workspaces you want to checkout.

```toml
[spaces-dev.Repo]
url = "https://github.com/work-spaces/spaces"
rev = "main"
new-branch = ["spaces"]
```

Then check it out:

```sh
spaces co spaces-dev the-name-of-the-workspace
cd the-name-of-the-workspace
spaces run //spaces:check
```
