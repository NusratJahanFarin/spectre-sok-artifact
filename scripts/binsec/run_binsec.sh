#!/bin/bash

set -e

echo "=== litmus-pht ==="
cd litmus-pht && python expes.py; cd ..

echo "=== litmus-stl ==="
cd litmus-stl && python expes.py; cd ..

echo "=== litmus-pht-masked ==="
cd litmus-pht-masked && python expes.py; cd ..

echo "=== tea ==="
cd tea && python expes.py; cd ..

echo "=== secretbox ==="
cd secretbox && python expes.py; cd ..

echo "=== poly1305 ==="
cd poly1305 && python expes.py; cd ..

echo "=== salsa ==="
cd salsa && python expes.py; cd ..

echo "=== sha512 ==="
cd sha512 && python expes.py; cd ..

echo "=== streamxor ==="
cd streamxor && python expes.py; cd ..

echo "=== ed25519 ==="
cd ed25519 && python expes.py; cd ..

echo "=== Done. Check each module's stats/ (or its STAT_FILE) for results. ==="
