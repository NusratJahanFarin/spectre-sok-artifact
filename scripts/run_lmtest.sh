#!/bin/bash

set -e

N=100

echo "=== salsa ==="
./run.sh -p V1 -n $N -c salsa salsa
./run.sh -p V1 -n $N -r salsa salsa
./run.sh -p V4Sized -n $N -c salsa salsa
./run.sh -p V4Sized -n $N -r salsa salsa

echo "=== sha512 ==="
./run.sh -p V1 -n $N -c sha512 sha512
./run.sh -p V1 -n $N -r sha512 sha512
./run.sh -p V4Sized -n $N -c sha512 sha512
./run.sh -p V4Sized -n $N -r sha512 sha512

echo "=== ed25519 ==="
./run.sh -p V1 -n $N -c ed25519 ed25519
./run.sh -p V1 -n $N -r ed25519 ed25519
./run.sh -p V4Sized -n $N -c ed25519 ed25519
./run.sh -p V4Sized -n $N -r ed25519 ed25519

echo "=== streamxor ==="
./run.sh -p V1 -n $N -c streamxor streamxor
./run.sh -p V1 -n $N -r streamxor streamxor
./run.sh -p V4Sized -n $N -c streamxor streamxor
./run.sh -p V4Sized -n $N -r streamxor streamxor

echo "=== secretbox ==="
./run.sh -p V1 -n $N -c secretbox secretbox
./run.sh -p V1 -n $N -r secretbox secretbox
./run.sh -p V4Sized -n $N -c secretbox secretbox
./run.sh -p V4Sized -n $N -r secretbox secretbox

echo "=== poly1305 ==="
./run.sh -p V1 -n $N -c poly1305 poly1305
./run.sh -p V1 -n $N -r poly1305 poly1305
./run.sh -p V4Sized -n $N -c poly1305 poly1305
./run.sh -p V4Sized -n $N -r poly1305 poly1305

echo "=== tea ==="
./run.sh -p V1 -n $N -c tea encipher
./run.sh -p V1 -n $N -r tea encipher
./run.sh -p V4Sized -n $N -c tea encipher
./run.sh -p V4Sized -n $N -r tea encipher

echo "=== spectrev1 (litmus-pht, all cases) ==="
./run.sh -p V1 -n $N -c spectrev1 all
./run.sh -p V1 -n $N -r spectrev1 all

echo "=== spectrev4 (litmus-stl, all cases) ==="
./run.sh -p V4Sized -n $N -c spectrev4 all
./run.sh -p V4Sized -n $N -r spectrev4 all

echo "=== Done. Results written to ./res/ ==="
