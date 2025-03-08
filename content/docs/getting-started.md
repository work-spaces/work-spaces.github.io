---
title: Getting Started
toc: false
weight: 1
---

Quickly create a `python3.11` virtual environment usinv `uv`.

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/work-spaces/install-spaces/refs/heads/main/install.sh)"
export PATH=$HOME/.local/bin:$PATH
git clone https://github.com/work-spaces/workflows/
spaces checkout --workflow=workflows:lock,preload,python-sdk --name=python-quick-test
cd python-quick-test
spaces run
source ./env
python -c "print('hello')"
```