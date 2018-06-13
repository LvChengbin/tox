#!/bin/bash

mkdir -p "$HOME/.tox" && \
curl https://raw.githubusercontent.com/LvChengbin/tox/master/tox.sh -o "$HOME/.tox/tox.sh" && \
[ -f "$HOME/.bashrc" ] || touch "$HOME/.bashrc" && \
echo "source ~/.tox/tox.sh" >> "$HOME/.bashrc" && \
source $HOME/.bashrc && \
toxc
