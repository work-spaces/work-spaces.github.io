"""
Spaces
"""

load("//@star/packages/star/package.star", "package_add")
load(
    "//@star/sdk/star/checkout.star",
    "checkout_add_which_asset",
    "checkout_update_asset",
)
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

shell(
    "builtins",
    script = "spaces docs > content/docs/builtins.md",
    working_directory = "."
)

run_add_exec(
    "help",
    command = "./get_help.sh",
    working_directory = ".",
)


REMOVE_FILES = [
    "@star/sdk/star/_index.md",
    "@star/packages/star/_index.md",
    "_index.md",
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
