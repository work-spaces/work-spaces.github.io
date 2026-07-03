"""
Preload script for this workspace.
"""

load("//@star/prelude/rules/checkout.star", "checkout_add_repo")
load("internal/version.star", "PACKAGE_REV", "SDK_REV")

checkout_add_repo(
    "@star/sdk",
    url = "https://github.com/work-spaces/sdk",
    rev = SDK_REV,
)

checkout_add_repo(
    "@star/packages",
    url = "https://github.com/work-spaces/packages",
    rev = PACKAGE_REV,
)
