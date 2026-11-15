#!/usr/bin/env bash
# Symlink dots/ into $HOME. Works from wherever the repo is cloned.
stow -d "$(dirname "$(realpath "$0")")" -t ~ dots
