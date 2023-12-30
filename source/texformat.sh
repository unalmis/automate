#!/bin/sh
# ------------------------------------------------------------------------------
# @author       Kaya Unalmis
# @license      GNU GPLv3
# @date         2023 December 27
# @command      sh texformat.sh
# @description  Reformat latex files and delete the created auxiliary files.
# ------------------------------------------------------------------------------

# output text settings
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)

# return true if the user replies 'yes', false if the user replies 'no'
reply_yes() {
    printf '%s (%s / %s) ' "$1" "${GREEN}yes${NORMAL}" "${YELLOW}no${NORMAL}"
    read -r REPLY
    case "$REPLY" in
        yes) return 0 ;;
        no) return 1 ;;
    esac
    reply_yes
}

# ------------------------------------------------------------------------------

find . -type f -name '*.tex' -execdir latexindent -w -s '{}' '+'
find . -type f '(' -name '*.bak*' -o -name 'indent.log' ')' -print

if reply_yes 'Delete the printed files?'; then
    find . -type f '(' -name '*.bak*' -o -name 'indent.log' ')' -delete
fi
