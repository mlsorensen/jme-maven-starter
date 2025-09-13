#!/usr/bin/env bash
set -euo pipefail

# --- helper functions -------------------------------------------------------
lower() { echo "$1" | tr '[:upper:]' '[:lower:]'; }

# sanitize a package segment: lowercase, replace non a-z0-9 and leading/trailing dots with _
sanitize_pkg_segment() {
  local s="$1"
  s="$(lower "$s")"
  # replace characters invalid in java package segments with underscore (keep dots for group)
  # for artifactId we expect no dots, but this is generic
  s="$(printf '%s' "$s" | sed -E 's/[^a-z0-9.]+/_/g; s/^\.+//; s/\.+$//')"
  echo "$s"
}

escape_for_sed() {
  # escape dots and slashes and ampersand for use in sed regex replacement
  printf '%s' "$1" | sed -e 's/\./\\./g' -e 's/\//\\\//g' -e 's/&/\\&/g'
}

# --- user prompts -----------------------------------------------------------
read -rp "Enter new groupId (e.g., com.example): " INPUT_NEW_GROUPID
read -rp "Enter new artifactId (e.g., mygame): " INPUT_NEW_ARTIFACTID
read -rp "Enter new version (e.g., 0.1.0): " NEW_VERSION

NEW_GROUPID="$(sanitize_pkg_segment "$INPUT_NEW_GROUPID")"
# artifact part should be a valid segment (no dots). convert dots to underscores if present.
NEW_ARTIFACT_SEGMENT="$(printf '%s' "$INPUT_NEW_ARTIFACTID" | sed 's/\./_/g')"
NEW_ARTIFACT_SEGMENT="$(sanitize_pkg_segment "$NEW_ARTIFACT_SEGMENT")"

NEW_PACKAGE="$NEW_GROUPID.$NEW_ARTIFACT_SEGMENT"
NEW_MAINCLASS="$NEW_PACKAGE.App"

echo
echo "Will customize project to:"
echo "  groupId:    $NEW_GROUPID"
echo "  artifactId: $NEW_ARTIFACT_SEGMENT"
echo "  version:    $NEW_VERSION"
echo "  mainClass:  $NEW_MAINCLASS"
echo

# --- discover old coordinates / package ------------------------------------
# Try to detect the package used in sources first
DETECTED_OLD_PACKAGE="$(grep -RhoP '^[[:space:]]*package[[:space:]]+\K[a-zA-Z0-9_.]+' src/main/java 2>/dev/null | head -n1 || true)"

if [ -n "$DETECTED_OLD_PACKAGE" ]; then
  OLD_PACKAGE="$DETECTED_OLD_PACKAGE"
  echo "Detected existing Java package: $OLD_PACKAGE"
else
  # fallback: read first <groupId> and <artifactId> from pom.xml (first occurrence)
  OLD_GROUPID="$(grep -m1 -oP '(?<=<groupId>).*?(?=</groupId>)' pom.xml || true)"
  OLD_ARTIFACTID="$(grep -m1 -oP '(?<=<artifactId>).*?(?=</artifactId>)' pom.xml || true)"
  if [ -z "$OLD_GROUPID" ] || [ -z "$OLD_ARTIFACTID" ]; then
    echo "Warning: couldn't auto-detect existing package or pom coordinates. Using defaults."
    OLD_GROUPID="com.mlsorensen"
    OLD_ARTIFACTID="jme-maven-starter"
  fi
  OLD_ARTIFACT_SEGMENT="$(printf '%s' "$OLD_ARTIFACTID" | sed 's/\./_/g' | sed -E 's/[^a-zA-Z0-9]+/_/g' | tr '[:upper:]' '[:lower:]')"
  OLD_PACKAGE="${OLD_GROUPID}.${OLD_ARTIFACT_SEGMENT}"
  echo "Fallback old package: $OLD_PACKAGE"
fi

# Also detect old groupId for fallback replacements
OLD_GROUPID_FROM_POM="$(grep -m1 -oP '(?<=<groupId>).*?(?=</groupId>)' pom.xml || true)"
[ -n "$OLD_GROUPID_FROM_POM" ] && OLD_GROUPID="$OLD_GROUPID_FROM_POM"

# --- update pom: only first occurrences of coordinates ----------------------
echo "Updating top-level POM coordinates..."
# replace first occurrences only (safer than global replace)
sed -i "0,/<groupId>.*<\/groupId>/s//<groupId>$NEW_GROUPID<\/groupId>/" pom.xml
sed -i "0,/<artifactId>.*<\/artifactId>/s//<artifactId>$NEW_ARTIFACT_SEGMENT<\/artifactId>/" pom.xml
sed -i "0,/<version>.*<\/version>/s//<version>$NEW_VERSION<\/version>/" pom.xml

# update properties.mainClass (first occurrence)
echo "Updating properties.mainClass to $NEW_MAINCLASS"
sed -i "0,/<mainClass>.*<\/mainClass>/s//<mainClass>$NEW_MAINCLASS<\/mainClass>/" pom.xml

# --- prepare escaped patterns for sed --------------------------------------
OLD_PKG_RE="$(escape_for_sed "$OLD_PACKAGE")"
OLD_GROUP_RE="$(escape_for_sed "$OLD_GROUPID")"
NEW_PKG_RE="$(printf '%s' "$NEW_PACKAGE" | sed -e 's/\./\\./g')"

# --- update package declarations and imports in source files ----------------
echo "Rewriting package declarations and imports in source files..."

# Update package lines (preserve suffixes). Works for lines like:
#   package com.old;                -> package com.new;
#   package com.old.sub.pkg;        -> package com.new.sub.pkg;
for tree in src/main/java src/test/java; do
  if [ -d "$tree" ]; then
    find "$tree" -name "*.java" -print0 | while IFS= read -r -d '' f; do
      # if file contains the old package as prefix in its package declaration -> replace
      # use sed with regex: ^\s*package\s+OLD_PACKAGE(.*);
      sed -E -i "s|^([[:space:]]*package[[:space:]]+)$OLD_PKG_RE(.*;)|\1$NEW_PACKAGE\2|" "$f"
    done
  fi
done

# Update import lines and any fully-qualified references beginning with old package or old group
# Do this globally across all java files under src
if find src -type f -name "*.java" | grep -q .; then
  # replace occurrences of the old package root with the new one
  find src -type f -name "*.java" -print0 | xargs -0 -n1 sed -i "s/$OLD_PKG_RE/$NEW_PACKAGE/g" || true
  # also replace occurrences of the old group id prefix (fallback)
  if [ -n "$OLD_GROUPID" ]; then
    find src -type f -name "*.java" -print0 | xargs -0 -n1 sed -i "s/$OLD_GROUP_RE/$NEW_GROUPID/g" || true
  fi
fi

# --- move files into directories that match updated package declarations -----
echo "Moving Java files so directory structure matches their package declarations..."

for tree in src/main/java src/test/java; do
  if [ -d "$tree" ]; then
    # find java files *after* edits; compute package line and move file
    find "$tree" -name "*.java" -print0 | while IFS= read -r -d '' f; do
      # extract package line (if any)
      new_pkg="$(sed -n 's/^[[:space:]]*package[[:space:]]\+\([a-zA-Z0-9_.]\+\).*/\1/p' "$f" || true)"
      if [ -z "$new_pkg" ]; then
        # if no package, place in the new package root
        new_pkg="$NEW_PACKAGE"
      fi
      target_dir="$tree/${new_pkg//./\/}"
      mkdir -p "$target_dir"
      # move file to target dir (if already there mv will still succeed)
      mv "$f" "$target_dir/" || true
    done
  fi
done

# --- cleanup empty old directories -----------------------------------------
echo "Cleaning up empty directories..."
# remove empty dirs under src
find src -type d -empty -delete || true

# --- rewrite README --------------------------------------------------------
echo "Updating README.md..."
cat > README.md <<EOF
# $NEW_ARTIFACT_SEGMENT

This is a game built with jMonkeyEngine.

## Running

Compile and run using Maven:

\`\`\`bash
mvn compile exec:java
\`\`\`

The main class is:

\`\`\`
$NEW_MAINCLASS
\`\`\`
EOF

echo
echo "Done. Project customized for:"
echo "  $NEW_GROUPID:$NEW_ARTIFACT_SEGMENT:$NEW_VERSION"
echo "Main class: $NEW_MAINCLASS"