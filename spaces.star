"""
Spaces
"""

load("//@star/packages/star/package.star", "package_add")
load(
    "//@star/sdk/star/checkout.star",
    "checkout_add_which_asset",
    "checkout_update_asset",
)

# To get the documentation to generate a function needs to
# be loaded from each file to document
load("//@star/sdk/star/capsule.star", "capsule_get_rule_name")
load("//@star/sdk/star/cmake.star", "cmake_get_default_prefix_paths")
load("//@star/sdk/star/gnu.star", "gnu_add_configure_make_install")
load("//@star/sdk/star/script.star", "script_print")
load("//@star/sdk/star/std/fs.star", "fs_read_directory")
load("//@star/sdk/star/std/hash.star", "hash_compute_sha256_from_file")
load("//@star/sdk/star/std/json.star", "json_loads")
load("//@star/sdk/star/std/time.star", "time_now")

# packages to add to docs
load("//@star/packages/star/ccache.star", "ccache_add")
load("//@star/packages/star/bazelisk.star", "bazelisk_add")
load("//@star/packages/star/cmake.star", "cmake_add")
load("//@star/packages/star/llvm.star", "llvm_add")
load("//@star/packages/star/python.star", "python_add_uv")
load("//@star/packages/star/rust.star", "rust_add")
load("//@star/packages/star/sccache.star", "sccache_add")
load("//@star/packages/star/shfmt.star", "shfmt_add")
load("//@star/packages/star/spaces-cli.star", "spaces_add")

load("//@star/sdk/star/run.star", "run_add_exec", "RUN_EXPECT_ANY")
load("//@star/sdk/star/shell.star", "shell")
load("//@star/sdk/star/oras.star", "oras_add_publish_archive")
load("//@star/sdk/star/process.star", "process_exec")
load("//@star/sdk/star/ws.star", "workspace_get_path_to_checkout")

package_add("github.com", "gohugoio", "hugo", "v0.145.0")
package_add("go.dev", "go", "go", "1.23.3")

CHECKOUT_PATH = workspace_get_path_to_checkout()

checkout_update_asset(
    "vscode_recommendations",
    destination = ".vscode/recommendations.json",
    value = [
        "mhutchie.git-graph",
        "esbenp.prettier-vscode",
        "tamasfe.even-better-toml",
        "budparr.language-hugo-vscode",
    ],
)

#checkout_add_which_asset(
#    "which_spaces",
#    which = "spaces",
#    destination = "sysroot/bin/spaces",
#)

run_add_exec(
    "stardoc",
    command = "spaces",
    args = [
        "inspect",
        "--stardoc={}/content/docs".format(CHECKOUT_PATH),
    ],
    inputs = []
)

run_add_exec(
    "builtins",
    command = "./get-builtins.sh",
    working_directory = "."
)

run_add_exec(
    "help",
    command = "./get-help.sh",
    working_directory = ".",
)


REMOVE_FILES = [
    "@star/sdk/star/_index.md",
    "@star/packages/star/_index.md",
    "env.spaces.md",
    "preload.spaces.md",
    "spaces-docs.spaces.md",
    "work-spaces.github.io/_index.md",
    "work-spaces.github.io/spaces.md",
]

run_add_exec(
    "clean_index_files",
    command = "rm",
    args = ["content/docs/{}".format(file) for file in REMOVE_FILES],
    deps = ["stardoc"],
    working_directory = "."
)

TOUCH_INDEX_FILES = [
    "@star/sdk/_index.md",
    "@star/packages/_index.md",
]

run_add_exec(
    "touch_index_files",
    command = "touch",
    args = ["content/docs/{}".format(file) for file in TOUCH_INDEX_FILES],
    deps = ["stardoc"],
    working_directory = "."
)

run_add_exec(
    "build",
    command = "hugo",
    args = [
        "build",
    ],
    working_directory = ".",
    deps = ["touch_index_files", "clean_index_files", "builtins", "help"]
)


run_add_exec(
    "serve",
    command = "hugo",
    args = [
        "server"
    ],
    deps = ["build"],
    working_directory = "."
)

run_add_exec(
    "hugo",
    command = "hugo",
    working_directory = "."
)
