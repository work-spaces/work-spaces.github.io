
#!/bin/bash

# Method 1: Using a here document (EOF)
cat > content/docs/help.md << 'EOF'
## Spaces Help

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



