#!/bin/bash

set -xe

if [ -d /build ]; then
  BUILD_ROOT=/build
elif [ ! -z "$HOME" ]; then
  BUILD_ROOT=$HOME
else
  BUILD_ROOT=/tmp
fi

sudo apt -y install \
  z3 \
  opam \

# No, Rust is not really needed, we only
# need isla sail plugin which is in OCaml
# sudo apt -y install \
#   rustc


#
# Initialize OPAM.
#
opam env || opam init -n
eval $(opam env)

#
# Download and compile SAIL
#

SAIL_URL=https://github.com/rems-project/sail
SAIL_BRANCH=91dd8783f45d291a1917ea6eb2df2b080cd85030
SAIL_DIR=$BUILD_ROOT/sail

pushd $(dirname "$SAIL_DIR")
  if [ ! -d "$SAIL_DIR" ]; then
    git clone --depth=1  $SAIL_URL "$SAIL_DIR"
  fi
  pushd "$SAIL_DIR"
    opam install . --yes --deps-only
    make install
  popd
popd

#
# Download and compile ISLA
#

ISLA_URL=https://github.com/rems-project/isla
ISLA_BRANCH=ce5cd98a8b497e8fce52b146ab93bc492f75ada4
ISLA_DIR=$BUILD_ROOT/isla

pushd $(dirname "$ISLA_DIR")
  if [ ! -d "$ISLA_DIR" ]; then
    git clone --depth=1 $ISLA_URL "$ISLA_DIR"
  fi
  pushd "$ISLA_DIR/isla-sail"
    make
    dune install
  popd
popd