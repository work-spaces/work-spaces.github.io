---
title: Adding Run Rules
toc: true
weight: 3
---

Most `spaces` run rules are executed using `run_add_exec()` which executes a command in the shell.

```python
load("//@star/sdk/star/run.star", "run_add_exec", "run_log_level_app")

run_add_exec(
  "show",                         # name of the rule
  command = "ls",                 # command to execute in the shell
  args = ["-alt"],                # arguments to pass to ls
  working_directory = ".",        # execute in the directory where this rule is
                                  #   default is to execute at the workspace root
  deps = [":another_rule"],       # another rule in the same module file
  log_level = run_log_level_app() # show the output of the rule to the user
)
```

Running `spaces run :show` in the same directory as this rule will execute the `show` rule after all dependencies have completed.

## Rule Types

The SDK provides convenience functions for adding rules as dependencies to built-in rules:

| Function | Built-in Rule | Purpose |
|---|---|---|
| `run_add_exec()` | — | General-purpose rule. Only runs when named explicitly or pulled in as a dependency. |
| `run_add_exec()` with `type = run_type_all()` | `//:all` | Runs with `spaces run`. |
| `run_add_exec_setup()` | `//:setup` | One-time setup tasks. Runs once and all other rules depend on it. |
| `run_add_exec_test()` | `//:test` | Test rules. |
| `run_add_exec_precommit()` | `//:pre-commit` | Pre-commit checks (formatting, linting). |
| `run_add_exec_clean()` | `//:clean` | Cleanup rules. |

By default, `spaces run` executes all rules in `//:all` plus their dependencies:

```sh
spaces run
# equivalent to
spaces run //:all
```

Run a specific rule group:

```sh
spaces run //:test
spaces run //:pre-commit
spaces run //:setup
spaces run //:clean
```

Run a single rule by name:

```sh
spaces run //my-project:build
```

## Controlling When Rules Run

### Dependencies

Use `deps` to ensure rules execute in the correct order. `spaces` builds a dependency graph and runs independent rules in parallel:

```python
run_add_exec(
    "generate",
    command = "python",
    args = ["generate.py"],
    working_directory = "my-project",
)

run_add_exec(
    "build",
    command = "cargo",
    args = ["build"],
    working_directory = "my-project",
    deps = [":generate"],  # waits for generate to finish first
)
```

### Targets

Use `target_files` and `target_dirs` to declare the outputs of a rule. This lets `spaces` track what a rule produces:

```python

load("//@star/sdk/star/deps.star", "deps")

run_add_exec(
    "compile",
    command = "gcc",
    args = ["-o", "build/main", "src/main.c"],
    deps = deps(
        files = ["src/main.c"],
    ),
    working_directory = "my-project",
    target_files = ["my-project/build/main"],
)
```

Adding targets to a rule will trigger the use of rule caching. All deps to the rule MUST be specified (both files and other rules' targets). If none of the deps have changed, `spaces` restore the `targets` on a cache hit.

## Logging

By default, rule output is captured in `.spaces` log files. Use `log_level` to display output while running:

```python
load("//@star/sdk/star/run.star", "run_add_exec", "run_log_level_app", "run_log_level_passthrough")

# Prefixed output — spaces labels each line with the rule name
run_add_exec(
    "build",
    command = "cargo",
    args = ["build"],
    working_directory = "my-project",
    log_level = run_log_level_app(),
)

# Raw passthrough — output is printed exactly as-is (useful for interactive tools)
run_add_exec(
    "serve",
    command = "hugo",
    args = ["server"],
    working_directory = "docs",
    log_level = run_log_level_passthrough(),
)
```

## Expected Exit Codes

By default, `spaces` expects commands to exit successfully. Use `expect` to change this:

```python
load("//@star/sdk/star/run.star", "run_add_exec_test", "run_expect_failure", "run_expect_any")

# This test verifies that an invalid config is rejected
run_add_exec_test(
    "test_invalid_config_rejected",
    command = "my-tool",
    args = ["--config=invalid.toml"],
    expect = run_expect_failure(),
)

# Don't fail the build regardless of exit code
run_add_exec(
    "optional_lint",
    command = "clippy",
    args = ["--all-targets"],
    working_directory = "my-project",
    expect = run_expect_any(),
)
```

## Grouping Rules

Use `run_add()` or `run_add_to_all()` to group multiple rules under a single name without running a command:

```python
load("//@star/sdk/star/run.star", "run_add_exec", "run_add_to_all", "run_add_target_test")

run_add_exec(
    "build_lib",
    command = "cargo",
    args = ["build", "--lib"],
    working_directory = "my-project",
)

run_add_exec(
    "build_bins",
    command = "cargo",
    args = ["build", "--bins"],
    working_directory = "my-project",
)

# Both build rules run with `spaces run`
run_add_to_all(
    "build",
    deps = [":build_lib", ":build_bins"],
)
```

## Timeouts

Use `timeout` to limit how long a rule can run (in seconds). If the timeout is exceeded, `spaces` sends a kill signal:

```python
run_add_exec_test(
    "slow_test",
    command = "cargo",
    args = ["test", "--test", "slow"],
    working_directory = ".",
    timeout = 120.0,
    help = "Run slow tests with a 2 minute timeout",
)
```

## Environment Variables

All rules will have access to the environment variables set during checkout. Pass environment variables to a command using `env` to augment or override them:

```python
run_add_exec(
    "build_debug",
    command = "cargo",
    args = ["build"],
    working_directory = ".",
    env = {
        "RUST_LOG": "debug",
        "CARGO_INCREMENTAL": "1",
    },
    help = "Build with debug logging enabled",
)
```

## Platform-Specific Rules

Use `platforms` to restrict a rule to specific platforms:

```python
run_add_exec(
    "macos_codesign",
    command = "codesign",
    args = ["--sign", "-", "target/release/my-tool"],
    working_directory = ".",
    deps = [":build"],
    platforms = ["macos-aarch64", "macos-x86_64"],
    help = "Code-sign the binary on macOS",
)
```

## Visibility

Visibility controls which rules are allowed to depend on a given rule. By default, all rules are public — any rule in the workspace can depend on them. As your workspace grows, it's good practice to make rules private by default and only expose the ones that are part of your public API.

Add `workspace.set_default_module_visibility_private()` to every module to make all rules in that module private by default:

```python
load("//@star/sdk/star/run.star", "run_add_exec", "run_add_to_all", "run_log_level_app")
load("//@star/sdk/star/visibility.star", "visibility_public")

workspace.set_default_module_visibility_private()

# This rule is private — only rules in this module can depend on it
run_add_exec(
    "compile",
    command = "cargo",
    args = ["build", "--release"],
    working_directory = ".",
    log_level = run_log_level_app(),
)

# This rule is public — any rule in the workspace can depend on it
run_add_to_all(
    "build",
    deps = [":compile"],
    visibility = visibility_public(),
)
```

For fine-grained control, use `visibility_rules()` to specify exactly which rules are allowed to see a rule:

```python
load("//@star/sdk/star/run.star", "run_add_exec")
load("//@star/sdk/star/visibility.star", "visibility_rules")

workspace.set_default_module_visibility_private()

# Only the "package" rule is allowed to depend on this rule
run_add_exec(
    "compile",
    command = "cargo",
    args = ["build", "--release"],
    working_directory = ".",
    visibility = visibility_rules(["//deploy:package"]),
)
```

## Putting It All Together

Here is a realistic `spaces.star` for a project with build, test, and pre-commit workflows:

```python
load(
    "//@star/sdk/star/run.star",
    "run_add_exec",
    "run_add_exec_test",
    "run_add_exec_precommit",
    "run_add_to_all",
    "run_add_target_test",
    "run_add_target_precommit",
    "run_log_level_app",
    "run_type_all",
)

# --- Build ---

run_add_exec(
    "check",
    command = "cargo",
    args = ["check", "--all-targets"],
    working_directory = ".",
    inputs = ["src/**/*.rs", "Cargo.toml", "Cargo.lock"],
    log_level = run_log_level_app(),
    help = "Check the project for compile errors",
)

run_add_exec(
    "build",
    command = "cargo",
    args = ["build", "--release"],
    working_directory = ".",
    deps = [":check"],
    inputs = ["src/**/*.rs", "Cargo.toml", "Cargo.lock"],
    log_level = run_log_level_app(),
    type = run_type_all(),
    help = "Build the release binary",
)

# --- Tests ---

run_add_exec_test(
    "unit_tests",
    command = "cargo",
    args = ["test", "--lib"],
    working_directory = ".",
    inputs = ["src/**/*.rs"],
    log_level = run_log_level_app(),
    help = "Run unit tests",
)

run_add_exec_test(
    "integration_tests",
    command = "cargo",
    args = ["test", "--test", "integration"],
    working_directory = ".",
    deps = [":build"],
    inputs = ["tests/**/*.rs", "src/**/*.rs"],
    log_level = run_log_level_app(),
    help = "Run integration tests",
)

# --- Pre-commit ---

run_add_exec_precommit(
    "format_check",
    command = "cargo",
    args = ["fmt", "--check"],
    working_directory = ".",
    inputs = ["src/**/*.rs"],
    log_level = run_log_level_app(),
    help = "Check that all Rust files are formatted",
)

run_add_exec_precommit(
    "clippy",
    command = "cargo",
    args = ["clippy", "--all-targets", "--", "-D", "warnings"],
    working_directory = ".",
    inputs = ["src/**/*.rs", "Cargo.toml"],
    log_level = run_log_level_app(),
    help = "Run clippy lints",
)
```

With these rules defined:

```sh
# Build the project (runs :check then :build)
spaces run

# Run all tests
spaces run //:test

# Run pre-commit checks before pushing
spaces run //:pre-commit

# Run a single rule
spaces run :check
```
