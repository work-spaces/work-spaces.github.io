"""
Spaces
"""

load("//@star/packages/star/package.star", "package_add")
load(
    "//@star/sdk/star/checkout.star",
    "checkout_add_which_asset",
    "checkout_update_asset",
)
load("//@star/sdk/star/run.star", "run_add_exec")
load("//@star/sdk/star/shell.star", "shell")
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

checkout_add_which_asset(
    "which_spaces",
    which = "spaces",
    destination = "sysroot/bin/spaces",
)

run_add_exec(
    "stardoc",
    command = "spaces",
    args = [
        "inspect",
        "--stardoc={}/content/docs/stardoc".format(CHECKOUT_PATH),
    ],
    inputs = []
)

shell(
    "apidoc",
    script = "spaces docs > content/api.md",
    working_directory = "."
)

run_add_exec(
    "build",
    command = "hugo",
    args = [
        "build",
    ],
    working_directory = ".",
    deps = ["stardoc", "apidoc"]
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
