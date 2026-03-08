---
title: Adding Checkout Rules
toc: true
weight: 2
---

A good pattern for checkout rules is to create two checkout modules:

- `0.checkout.spaces.star`: adds the spaces starlark SDK and packages repositories to the workspace.
- `1.checkout.custom.star`: adds custom repositories/assets/archives to the workspace.

## Bootstrapping the Workspace

In the [first module evaluated](/docs/explainers/checkout-evaluation-order/) (usually `0.checkout.spaces.star`), no files are available to [`load()`](/docs/explainers/labels-and-paths/#load-paths). Rules must use the starlark [built-ins](/docs/reference/builtins/).

Here is an example of a `0.checkout.spaces.star` module that adds the spaces starlark SDK and packages repositories to the workspace:

```python
# checkout.add_repo() is a built-in function.
# checkout_add_repo() in sdk/star/checkout.star is a convenience wrapper.
checkout.add_repo(
    rule = {"name": "@star/sdk"},
    repo = {
        "url": "https://github.com/work-spaces/sdk",
        "rev": "v0.3.5",
        "checkout": "Revision",
        "clone": "Default"
    }
)

checkout.add_repo(
    rule = {"name": "@star/packages"},
    repo = {
        "url": "https://github.com/work-spaces/packages",
        "rev": "v0.2.5",
        "checkout": "Revision",
        "clone": "Default"
    }
)
```

## Adding tools, archives, assets, and repos

Once the SDK and packages repos are available, subsequent modules (e.g. `1.checkout.custom.star`) can [`load()`](/docs/explainers/labels-and-paths/#load-paths) functions from the workspace.

### Tools

The easiest way to add platform tools is with `package_add()` from `@star/packages`. This downloads the correct binary for the host platform and hard-links it into the workspace `sysroot`.

```python
load("//@star/packages/star/package.star", "package_add")

# Add ninja and jq to sysroot/bin
package_add("github.com", "ninja-build", "ninja", "v1.12.1")
package_add("github.com", "jqlang", "jq", "jq-1.7.1")
```

For tools that require additional setup (environment variables, IDE configuration, etc.), packages provide dedicated helper functions:

```python
load("//@star/packages/star/rust.star", "rust_add")
load("//@star/packages/star/cmake.star", "cmake_add")

# Installs the Rust toolchain via rustup and configures CARGO_HOME, RUSTUP_HOME, and VS Code settings
rust_add("rust", "1.80")

# Adds CMake to sysroot and recommends the twxs.cmake VS Code extension
cmake_add("cmake3", "v3.31.2")
```

### Archives

Use `checkout_add_archive()` to download and extract an archive into the workspace. Archives are stored by SHA256 hash in the spaces store and hard-linked into the workspace.

```python
load("//@star/sdk/star/checkout.star", "checkout_add_archive")

# Download a header-only library and place it under sysroot/include
checkout_add_archive(
    "my-headers",
    url = "https://github.com/my-org/my-headers/archive/refs/tags/v1.0.0.tar.gz",
    sha256 = "abc123...",
    strip_prefix = "my-headers-1.0.0",
    add_prefix = "sysroot/include",
)
```

For archives that vary by platform, use `checkout_add_platform_archive()`:

```python
load("//@star/sdk/star/checkout.star", "checkout_add_platform_archive")

checkout_add_platform_archive(
    "my-tool",
    platforms = {
        "macos-aarch64": {
            "url": "https://example.com/my-tool-darwin-arm64.tar.gz",
            "sha256": "aaa...",
            "add_prefix": "sysroot/bin",
            "link": "Hard",
        },
        "linux-x86_64": {
            "url": "https://example.com/my-tool-linux-amd64.tar.gz",
            "sha256": "bbb...",
            "add_prefix": "sysroot/bin",
            "link": "Hard",
        },
    },
)
```

### Assets

Assets create files in the workspace from starlark strings. Use `checkout_add_asset()` to write a file with arbitrary content:

```python
load("//@star/sdk/star/checkout.star", "checkout_add_asset")

# Create a .clang-format file in the workspace root
checkout_add_asset(
    "clang-format-config",
    destination = ".clang-format",
    content = """
BasedOnStyle: LLVM
IndentWidth: 4
ColumnLimit: 120
""",
)
```

Use `checkout_update_asset()` to merge structured content (e.g. JSON) into an existing file. Multiple rules can update the same file:

```python
load("//@star/sdk/star/checkout.star", "checkout_update_asset")

# Add recommended VS Code extensions (merges with any existing content)
checkout_update_asset(
    "vscode-extensions",
    destination = ".vscode/extensions.json",
    format = "json",
    value = {
        "recommendations": ["twxs.cmake", "ms-vscode.cpptools"],
    },
)
```

Use hard or soft link assets to link files already in the workspace:

```python
load("//@star/sdk/star/checkout.star", "checkout_add_hard_link_asset", "checkout_add_soft_link_asset")

# Hard-link a binary under a shorter name
checkout_add_hard_link_asset(
    "shfmt-link",
    source = "sysroot/bin/shfmt_v3.7.0_darwin_arm64",
    destination = "sysroot/bin/shfmt",
)

# Soft-link a system resource into the workspace
checkout_add_soft_link_asset(
    "system-certs",
    source = "/etc/ssl/certs",
    destination = "sysroot/etc/ssl/certs",
)
```

### Repos

The most common way to add source code is using `checkout_add_repo()`:

```python
load("//@star/sdk/star/checkout.star", "checkout_add_repo")

checkout_add_repo(
  "printer",
  url = "https://github.com/work-spaces/spaces-printer",
  rev = "main"
)
```

If you need to checkout the same repo multiple times with different configurations, you can use `checkout_add_repo()` multiple times with different names and configurations.

```python
checkout_add_repo(
  "printer", # will be located at //printer
  url = "https://github.com/work-spaces/spaces-printer",
  rev = "main"
)

checkout_add_repo(
  "printer-debug", # will be located at //printer-debug
  url = "https://github.com/work-spaces/spaces-printer",
  rev = "debug"
)
```
