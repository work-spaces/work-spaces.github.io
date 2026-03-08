---
title: Checkout Evaluation Order
toc: true
weight: 6
---

`spaces` has two ways of checking out a workspace:

- `spaces checkout-repo`: uses `git clone` to checkout out a repo and evaulates the spaces modules it contains. This is the recommended way for most use cases.
- `spaces checkout` (workflow): uses workflows scripts as the input files.

## Checkout Evaluation Order

During `checkout`, `spaces` evaluates all modules in a precise order.

- Checkout-Repo: `spaces` evaluates the modules in lexicographical order, depth first. 
- Checkout (workflow): `spaces` evaluates the modules in the order they are provided on the command line. Each module is evaluated in depth-first order, meaning that any repos checked out by a module are evaluated before moving on to the next module from the command line.

`spaces` only looks for checkout rules in the root directory of the repo.

The `load()` function never has any files available to it while the first module is evaluated. The job of the first module is to use the built-in `checkout.add_repo()` to add the spaces starlark SDK, or a suitable alternative, to the workspace.

After the first module is evaluated, `load()` can find useful modules to load.

### Checkout-Repo Example Evaluation Order

```
spaces checkout-repo --url=https://github.com/my-org/my-repo ...
```

And `my-repo` has: 

- `0.checkout.spaces.star`: this is evaluated first. If it uses `checkout.add_repo()` the repos will be checked out and evaluated before moving to the next module in `my-repo`.
- `1.checkout.spaces.star`: this is evaluated after `0.checkout.spaces.star` and any repos checked out by `0.checkout.spaces.star`.
- `spaces.star`: this is evaluated next.

### Checkout (Workflow) Example

```
spaces checkout --script=workflows/sdk.spaces.star --script=workflows/my-repo.spaces.star ...
```

The local file located at `workflows/sdk.spaces.star` is evaluated first. Then any repos checked out by `workflows/sdk.spaces.star` are evaluated, followed by `workflows/my-repo.spaces.star`, plus any repos checked out by `workflows/my-repo.spaces.star`.
