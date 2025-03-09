"""
Spaces
"""

load("//@star/packages/star/package.star", "package_add")
load(
    "//@star/sdk/star/checkout.star",
    "checkout_add_which_asset",
    "checkout_update_asset",
    "chekcout_update_env"
)

load("//@star/sdk/star/gh.star", "gh_add_publish_archive")


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
load("//@star/sdk/star/shell.star", "cp")
load("//@star/sdk/star/oras.star", "oras_add_publish_archive")
load("//@star/sdk/star/process.star", "process_exec")
load("//@star/sdk/star/ws.star", "workspace_get_path_to_checkout")

package_add("github.com", "gohugoio", "hugo", "v0.145.0")
package_add("github.com", "cli", "cli", "v2.68.1")
package_add("go.dev", "go", "go", "1.23.3")

CHECKOUT_PATH = workspace_get_path_to_checkout()

if info.is_ci():
    checkout_update_env(
        "ci_github_token",
        inherited_vars = [
            "GITHUB_TOKEN"
        ]
    )

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

SPACES_VERSION = "0.14.6"
spaces_add("spaces0", "v{}".format(SPACES_VERSION))
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

run_add_exec(
    "version",
    command = "./get-version.sh",
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
    args = ["-f"] + ["content/docs/{}".format(file) for file in REMOVE_FILES],
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

BUILD_DEPS = [
        "touch_index_files", 
        "clean_index_files", 
        "builtins", 
        "help", 
        "version"
]

run_add_exec(
    "build",
    command = "hugo",
    args = [
        "build",
    ],
    working_directory = ".",
    deps = BUILD_DEPS
)

run_add_exec(
    "build_release",
    command = "hugo",
    args = [
        "build",
        "--minify",
        "--baseURL=https://work-spaces.github.io/",
    ],
    working_directory = ".",
    deps = BUILD_DEPS,
    help = "Build the release version of the site for deployment"
)

cp(
    "cp_release_public",
    source = "work-spaces.github.io/public",
    destination = "public",
    options = ["-rf"],
    deps = ["build_release"]
)

gh_add_publish_archive(
    "work-spaces.github.io",
    input = "public",
    version = "{}-1".format(SPACES_VERSION),
    deploy_repo = "https://github.com/work-spaces/work-spaces.github.io",
    deps = ["cp_release_public"],
    suffix = "tar.gz",
)

run_add_exec(
    "serve",
    command = "hugo",
    args = [
        "server"
    ],
    deps = ["build"],
    working_directory = ".",
    help = "Serve the site locally"
)

run_add_exec(
    "hugo",
    command = "hugo",
    working_directory = ".",
    help = "This is useful for debugging hugo commands with `spaces run hugo -- --help`"
)
