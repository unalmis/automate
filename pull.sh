#!/bin/sh
# ------------------------------------------------------------------------------
# @author      Kaya Unalmis
# @license     GNU GPLv3
# @date        2022 October 23
# @command     sh pull.sh
# @description Update all local repositories in the current directory, recursively
# ------------------------------------------------------------------------------

# Find hidden directories (those leading with '.') inside the current directory.
# If a match is found, do not continue searching inside it.
# If the name of the match is '.git', update that repository.
find . -type d -name '.?*' -prune -name '.git' \
    -execdir sh -c 'git fetch --prune origin && git pull --ff-only origin "$(git branch --show-current)"' ';'
