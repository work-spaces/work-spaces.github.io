---
title: Starlark
toc: true
weight: 3
---

`spaces` rules are written in `starlark`, a dialect of python. `starlark` symbols originate from three sources:

- The [standard starlark specification](https://github.com/bazelbuild/starlark/blob/master/spec.md)
- [Builtins](/docs/reference/builtins/) that call `rust` functions within the `spaces` binary
  - Built-ins have function wrappers defined in the [SDK](/docs/reference/@star/sdk/)
- `load()` statements that import variables or functions from other starlark scripts
  - `load()` paths can either be relative to the current `star` file or prefixed with `//` to refer to the workspace root