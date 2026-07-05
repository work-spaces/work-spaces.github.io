---
title: SDK
toc: true
---

The `spaces` starlark SDK API can optionally be checked out from: https://github.com/work-spaces/sdk.

Most functionality of the SDK has been migrated to the [prelude](/docs/reference/@star/prelude). The SDK still contains load forwards for prelude functions. It is recommened to migrate to load the prelude first directly.

```python
load("//@star/sdk/star/run.star", "run_add_exec")
# migrate to
load("//@star/prelude/rules/run.star", "run_add_exec")
```
