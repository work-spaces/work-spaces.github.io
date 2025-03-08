---
title: Installing Spaces
toc: true
weight: 3
---

`spaces` is a statically linked binary. Download it in the releases section.

Or install `spaces` at `$HOME/.local/bin`:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/work-spaces/install-spaces/refs/heads/main/install.sh)"
```

The command above requires `curl`, `unzip` and `sed`.

Or install from source using `cargo`:

```sh
git clone https://github.com/work-spaces/spaces
cd spaces
cargo install --path=crates/spaces --root=$HOME/.local --profile=release
```

Use `spaces` in github actions with https://github.com/work-spaces/install-spaces.