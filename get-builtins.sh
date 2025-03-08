
#!/bin/bash

cat > content/docs/builtins.md << 'EOF'
---
title: Builtin Functions
toc: true
weight: 7
---

The contents of this page can be generated using:

```sh
spaces docs
```

EOF

spaces docs >> content/docs/builtins.md