#!/bin/bash

OUTPUT="project_dump.txt"

echo "📦 Dumping project structure and contents..." > $OUTPUT
echo "" >> $OUTPUT

# 1. Show tree
echo "===== PROJECT TREE =====" >> $OUTPUT
tree -I node_modules >> $OUTPUT
echo "" >> $OUTPUT

# 2. Dump all files (except heavy folders)
echo "===== FILE CONTENTS =====" >> $OUTPUT

# List of folders to ignore
IGNORE_DIRS="node_modules|stripe|backups|monitoring|tests|dist|build"

# Loop through all files except ignored ones
find . -type f | grep -Ev "$IGNORE_DIRS" | while read FILE; do
    echo "" >> $OUTPUT
    echo "---------------------------------------------" >> $OUTPUT
    echo "FILE: $FILE" >> $OUTPUT
    echo "---------------------------------------------" >> $OUTPUT
    echo "" >> $OUTPUT
    cat "$FILE" >> $OUTPUT
    echo "" >> $OUTPUT
done

echo "✅ DONE. Output saved into $OUTPUT"
