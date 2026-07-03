---
title: Checkout Evaluation Order
toc: true
weight: 6
---

`spaces` has two ways of checking out a workspace:

- {{< badge content="Checkout Repo" >}}: uses `git clone` to checkout out a repo and evaulates the spaces modules it contains. This is the recommended way for most use cases.
- {{< badge content="Specify Workflow Modules" >}} `spaces checkout` (workflow): uses workflows scripts as the input files.

## Checkout Evaluation Order

During `checkout`, `spaces` evaluates all modules in a precise order.

- Checkout-Repo: `spaces` evaluates the modules in lexicographical order, depth first. 
- Checkout (workflow): `spaces` evaluates the modules in the order they are provided on the command line. Each module is evaluated in depth-first order, meaning that any repos checked out by a module are evaluated before moving on to the next module from the command line.

{{< callout type="warning" >}}

`spaces` only looks for checkout rules in `[*.]spaces.star` files the root directory of the repo.

{{< /callout >}}

The `load()` function always has the `//@star/prelude/**` files available.

### Checkout-Repo Example Evaluation Order

```sh
spaces checkout-repo --url=https://github.com/my-org/my-repo ...
```

And `my-repo` has: 

{{% steps %}}

### `0.checkout.spaces.star`

This is evaluated first. If it uses `checkout.add_repo()` the repos will be checked out and evaluated before moving to `1.checkout.spaces.star`.

### `1.checkout.spaces.star`

This is evaluated after `0.checkout.spaces.star` and any repos checked out by `0.checkout.spaces.star`.

### `spaces.star`

This is evaluated next.

{{% /steps %}}

### Checkout (Workflow) Example

```
spaces checkout --script=workflows/sdk.spaces.star --script=workflows/my-repo.spaces.star ...
```

{{% steps %}}

### `workflows/sdk.spaces.star`

This is evaluated first. Any repos that are checked out will be scanned for `[*.]spaces.star` files in the root directory and those checkout rules executed before moving on to `workflows/my-repo.spaces.star`

### `workflows/my-repo.spaces.star`

This is evaluated after `workflows/sdk.spaces.star` and all transitive modules it pulls in.

{{% /steps %}}



The local file located at `workflows/sdk.spaces.star` is evaluated first. Then any repos checked out by `workflows/sdk.spaces.star` are evaluated, followed by `workflows/my-repo.spaces.star`, plus any repos checked out by `workflows/my-repo.spaces.star`.
