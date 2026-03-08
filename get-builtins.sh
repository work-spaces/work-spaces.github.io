#!/bin/bash

cat > content/docs/reference/builtins.md << 'EOF'
---
title: Builtin Functions
toc: true
weight: 2
---

The contents of this page can be generated using:

```sh
spaces docs
```

EOF

spaces docs >> content/docs/reference/builtins.md
