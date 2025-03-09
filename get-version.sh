
#!/bin/bash

cat > content/docs/version.md << 'EOF'
---
title: Version
toc: false
weight: 0
---

This documention covers:

[Spaces](https://github.com/work-spaces/spaces) version:

```
EOF

spaces --version >> content/docs/version.md

cat >> content/docs/version.md << 'EOF'
```

[SDK](https://github.com/work-spaces/sdk) version:

```
EOF

git -C ../@star/sdk describe --tags --abbrev=0 >> content/docs/version.md

cat >> content/docs/version.md << 'EOF'
```

[Packages](https://github.com/work-spaces/packages) version:

```
EOF

git -C ../@star/packages describe --tags --abbrev=0 >> content/docs/version.md

cat >> content/docs/version.md << 'EOF'
```
EOF