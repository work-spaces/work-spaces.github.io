"""
Add tools to the workspace
"""

load("//@star/packages/star/package.star", "package_add")
load(
    "//@star/packages/star/spaces-cli.star",
    "spaces_add_devutils",
    "spaces_add_star_formatter",
)
load("//@star/packages/star/starship.star", "starship_add_bash")
load("//@star/prelude/rules/checkout.star", "checkout_add_env_vars")
load("//@star/prelude/rules/env.star", "env_inherit")
load("internal/version.star", "SPACES_VERSION")

spaces_add_devutils(
    "spaces0",
    "v" + SPACES_VERSION,
    "devutils-v0.1.14",
    system_paths = ["/usr/bin", "/bin"],
)
spaces_add_star_formatter("spaces_formatter", configure_zed = True, deps = [":spaces0"])

if info.is_ci():
    checkout_add_env_vars(
        "ci_github_token",
        vars = [env_inherit("GITHUB_TOKEN", help = "Inform spaces of github token in CI")],
    )
else:
    starship_add_bash("starship_bash", shortcuts = {})

package_add("github.com", "gohugoio", "hugo", "v0.152.2")
package_add("github.com", "cli", "cli", "v2.68.1")
package_add("go.dev", "go", "go", "1.23.3")
