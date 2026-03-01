---
title: Getting Started
toc: false
weight: 1
---

Quickly checkout the spaces source and and stand-up a Rust toolchain specific to the workspace.

```sh
spaces checkout-repo \
  --url=https://github.com/work-spaces/spaces \
  --rev=main \
  --new-branch=spaces \
  --name=issue-x-fix-something
cd issue-x-fix-something
spaces run //spaces:check
```
