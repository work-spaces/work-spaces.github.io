"""

To update the Spaces docs:

```sh
# run locally to check everything is working.
spaces checkout-repo --url=https://github.com/work-spaces/work-spaces.github.io --rev=main --name=update-spaces-docs
# update the preload versions and spaces version
spaces run //work-spaces.github.io:work-spaces.github.io_archive
```

Commit and push changes to the `main` branch.

Then manually run the action to publish the github pages.

"""

load("//@star/packages/star/bazelisk.star", "bazelisk_add")

# packages to add to docs
load("//@star/packages/star/ccache.star", "ccache_add")
load("//@star/packages/star/cmake.star", "cmake_add")
load("//@star/packages/star/llvm.star", "llvm_add")
load("//@star/packages/star/python.star", "python_add_uv")
load("//@star/packages/star/rust.star", "rust_add")
load("//@star/packages/star/sccache.star", "sccache_add")
load("//@star/packages/star/shfmt.star", "shfmt_add")
load("//@star/prelude/exec/args.star", "args_argv")
load("//@star/prelude/exec/env.star", "env_get")
load("//@star/prelude/exec/fs.star", "fs_read_directory")
load("//@star/prelude/exec/hash.star", "hash_compute_sha256_from_file")
load("//@star/prelude/exec/json.star", "json_loads")
load("//@star/prelude/exec/log.star", "log_set_level")
load("//@star/prelude/exec/path.star", "path_join")
load("//@star/prelude/exec/process.star", "process_stdout_inherit")
load("//@star/prelude/exec/sh.star", "sh_run")
load("//@star/prelude/exec/string.star", "string_trim")
load("//@star/prelude/exec/sys.star", "sys_os")
load("//@star/prelude/exec/text.star", "text_scan_file")
load("//@star/prelude/exec/time.star", "time_now")
load("//@star/prelude/exec/tmp.star", "tmp_dir")
load("//@star/prelude/exec/toml.star", "toml_parse_string")
load("//@star/prelude/exec/yaml.star", "yaml_parse_string")
load(
    "//@star/sdk/star/checkout.star",
    "checkout_add_which_asset",
    "checkout_update_asset",
    "checkout_update_env",
)

# To get the documentation to generate a function needs to
# be loaded from each file to document
load("//@star/sdk/star/cmake.star", "cmake_get_default_prefix_paths")
load("//@star/sdk/star/gh.star", "gh_add_publish_archive")
load("//@star/sdk/star/gnu.star", "gnu_add_configure_make_install")
load("//@star/sdk/star/info.star", "info_set_required_semver")
load("//@star/sdk/star/oras.star", "oras_add_publish_archive")
load("//@star/sdk/star/process.star", "process_exec")
load("//@star/sdk/star/run.star", "run_add", "run_add_exec", "run_expect_any")
load("//@star/sdk/star/script.star", "script_print")

#load("//@star/sdk/star/semver.star", "semver_is_valid_version")
load("//@star/sdk/star/shell.star", "cp")
load("//@star/sdk/star/spaces-env.star", "spaces_working_env")
load("//@star/sdk/star/ws.star", "workspace_get_path_to_checkout")
load("internal/version.star", "SPACES_VERSION")

info_set_required_semver(">0.10, <1.20.1")

CHECKOUT_PATH = workspace_get_path_to_checkout()

run_add_exec(
    "stardoc",
    command = "spaces",
    args = [
        "inspect",
        "--stardoc={}/content/docs/reference".format(CHECKOUT_PATH),
    ],
    inputs = [],
)

run_add_exec(
    "builtins",
    command = "./scripts/get-builtins.exec.star",
    working_directory = ".",
)

run_add_exec(
    "help",
    command = "./scripts/get-help.exec.star",
    working_directory = ".",
)

run_add_exec(
    "version",
    command = "./scripts/get-version.exec.star",
    working_directory = ".",
)

REMOVE_FILES = [
    "reference/@star/sdk/star/_index.md",
    "reference/@star/packages/star/_index.md",
    "reference/env.spaces.md",
    "reference/checkout.spaces.md",
    "reference/work-spaces.github.io/0.checkout.spaces.md",
    "reference/work-spaces.github.io/1.checkout.spaces.md",
    "reference/work-spaces.github.io/internal/_index.md",
    "reference/work-spaces.github.io/internal/version.md",
    "reference/spaces-docs.spaces.md",
    "reference/work-spaces.github.io/_index.md",
    "reference/work-spaces.github.io/spaces.md",
]

run_add_exec(
    "clean_index_files",
    command = "rm",
    args = ["-f"] + ["content/docs/{}".format(file) for file in REMOVE_FILES],
    deps = ["stardoc"],
    working_directory = ".",
)

OVERLAY_FILES = {
    "overlays/prelude_index.md": "content/docs/reference/@star/prelude/_index.md",
    "overlays/sdk_index.md": "content/docs/reference/@star/sdk/_index.md",
    "overlays/packages_index.md": "content/docs/reference/@star/packages/_index.md",
}

overlay_deps = []
for source, destination in OVERLAY_FILES.items():
    name = "overlay_files_" + source
    overlay_deps.append(name)
    run_add_exec(
        name,
        command = "cp",
        args = ["-lf", source, destination],
        deps = ["stardoc"],
        working_directory = ".",
    )

run_add(
    "overlay_files",
    deps = overlay_deps,
)

BUILD_DEPS = [
    "clean_index_files",
    "overlay_files",
    "builtins",
    "help",
    "version",
]

run_add_exec(
    "build",
    command = "hugo",
    args = [
        "build",
    ],
    working_directory = ".",
    deps = BUILD_DEPS,
)

run_add_exec(
    "build_release",
    command = "hugo",
    args = [
        "build",
        "--minify",
        "--logLevel=debug",
        "--baseURL=https://work-spaces.github.io/",
    ],
    working_directory = ".",
    log_level = "Passthrough",
    deps = BUILD_DEPS,
    help = "Build the release version of the site for deployment",
)

cp(
    "cp_release_public",
    source = "work-spaces.github.io/public",
    destination = "public",
    options = ["-rf"],
    deps = ["build_release"],
)

gh_add_publish_archive(
    "work-spaces.github.io",
    input = "public",
    version = "{}".format(SPACES_VERSION),
    deploy_repo = "https://github.com/work-spaces/work-spaces.github.io",
    deps = ["cp_release_public"],
    suffix = "tar.gz",
)

run_add_exec(
    "serve",
    command = "hugo",
    args = [
        "server",
    ],
    log_level = "Passthrough",
    deps = [":build"],
    working_directory = ".",
    help = "Serve the site locally",
)

run_add_exec(
    "hugo",
    command = "hugo",
    working_directory = ".",
    help = "This is useful for debugging hugo commands with `spaces run hugo -- --help`",
)
