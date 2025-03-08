
#!/bin/bash

cat > content/docs/help.md << 'EOF'
---
title: Spaces Help Reference
toc: true
weight: 8
---

```sh
spaces --help
```

```
EOF

spaces --help >> content/docs/help.md

cat >> content/docs/help.md << 'EOF'
```

### Checkout Help

```sh
spaces checkout --help
```

```
EOF

spaces checkout --help >> content/docs/help.md

cat >> content/docs/help.md << 'EOF'
```

### Run Help

```sh
spaces run --help
```

```
EOF

spaces run --help >> content/docs/help.md

cat >> content/docs/help.md << 'EOF'
```

### Inspect Help

```sh
spaces inspect --help
```

```
EOF

spaces inspect --help >> content/docs/help.md

cat >> content/docs/help.md << 'EOF'
```
EOF



