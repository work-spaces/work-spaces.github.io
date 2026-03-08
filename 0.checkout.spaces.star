"""
Preload script for this workspace.
"""

checkout.add_repo(
    rule = {"name": "@star/sdk"},
    repo = {
        "url": "https://github.com/work-spaces/sdk",
        "rev": "c0934a9c1f8b39b99e2ac653e03b11b3d31fa578",
        "checkout": "Revision",
        "clone": "Default"
    }
)

checkout.add_repo(
    rule = {"name": "@star/packages"},
    repo = {
        "url": "https://github.com/work-spaces/packages",
        "rev": "14d0dec6a8f11e8a20ed0fbeea81058425c98f22",
        "checkout": "Revision",
        "clone": "Default"
    }
)
