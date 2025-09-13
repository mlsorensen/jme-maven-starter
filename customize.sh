#!/usr/bin/env bash
# --------------------------------------------------------------
# customize.sh
#   1️⃣ Prompt for Maven coordinates and Java package
#   2️⃣ Rewrite pom.xml (groupId, artifactId, version, mainClass)
#   3️⃣ Move the starter source file into the new package tree
#   4️⃣ Replace README.md with a simple header + boiler‑plate
# --------------------------------------------------------------

set -euo pipefail

# ---------- 1️⃣ USER INPUT ----------
read -rp "Maven groupId (e.g. com.mycompany): " GID
read -rp "Maven artifactId (e.g. awesome-game): " AID
read -rp "Project version (e.g. 0.1.0‑SNAPSHOT): " VER
read -rp "Java package for your code (e.g. com.mycompany.game): " PKG

PKG_PATH=${PKG//./\/}                # com.mycompany.game -> com/mycompany/game
MAIN_CLASS="${PKG}.Main"             # fully‑qualified main class name

# ---------- 2️⃣ UPDATE pom.xml ----------
POM="pom.xml"

if command -v xmlstarlet >/dev/null 2>&1; then
    xmlstarlet ed -L \
        -u "/project/groupId"    -v "$GID" \
        -u "/project/artifactId" -v "$AID" \
        -u "/project/version"    -v "$VER" \
        -u "/project/properties/mainClass" -v "$MAIN_CLASS" \
        "$POM"
else
    # simple sed fallback – works for the typical starter pom.xml
    sed -i \
        -e "s|<groupId>.*</groupId>|<groupId>${GID}</groupId>|" \
        -e "s|<artifactId>.*</artifactId>|<artifactId>${AID}</artifactId>|" \
        -e "s|<version>.*</version>|<version>${VER}</version>|" \
        -e "s|<mainClass>.*</mainClass>|<mainClass>${MAIN_CLASS}</mainClass>|" \
        "$POM"
fi

echo "✔ pom.xml updated."

# ---------- 3️⃣ RE‑ARRANGE SOURCE ----------
# locate the starter java file (first .java under src/main/java)
SRC_ROOT="src/main/java"
OLD_FILE=$(find "$SRC_ROOT" -type f -name "*.java" | head -n1)

if [[ -z "$OLD_FILE" ]]; then
    echo "❌ No Java source file found under $SRC_ROOT. Abort."
    exit 1
fi

# destination directory / file
NEW_DIR="${SRC_ROOT}/${PKG_PATH}"
NEW_FILE="${NEW_DIR}/Main.java"

mkdir -p "$NEW_DIR"
mv "$OLD_FILE" "$NEW_FILE"

# fix package line
sed -i "s|^package .*;|package ${PKG};|g" "$NEW_FILE"
# rename class to Main (if it wasn't already)
sed -i "s|public class .* {|public class Main {|g" "$NEW_FILE"

echo "✔ Source moved to $NEW_FILE and package updated."

# ---------- 4️⃣ REWRITE README.md ----------
cat > README.md <<EOF
# $AID

This is a jMonkeyEngine game.

## Build & run

```bash
mvn compile exec:java
```

EOF

echo "✔ README.md rewritten."

echo "All done! Your project is now customised."
