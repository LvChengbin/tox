#!/bin/bash

mkdir -p "$HOME/.tox" && \
git clone https://github.com/LvChengbin/tox.git ~/.tox && \
echo "source ~/.tox/tox.sh" >> "~/.bashrc" && \
toxc
