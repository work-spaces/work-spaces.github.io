#!/bin/bash

cat > content/docs/reference/help.md << 'EOF'
---
title: Help Reference
toc: true
weight: 3
---

```sh
spaces --help
```

```
EOF

spaces --help >> content/docs/reference/help.md

cat >> content/docs/reference/help.md << 'EOF'
```

### Checkout Help

```sh
spaces checkout --help
```

```
EOF

spaces checkout --help >> content/docs/reference/help.md

cat >> content/docs/reference/help.md << 'EOF'
```

### Run Help

```sh
spaces run --help
```

```
EOF

spaces run --help >> content/docs/reference/help.md

cat >> content/docs/reference/help.md << 'EOF'
```

### Inspect Help

```sh
spaces inspect --help
```

```
EOF

spaces inspect --help >> content/docs/reference/help.md

cat >> content/docs/reference/help.md << 'EOF'
```
EOF
