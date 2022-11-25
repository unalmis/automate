#!/bin/sh
# ------------------------------------------------------------------------------
# @author      Kaya Unalmis
# @license     GNU GPLv3
# @date        2022 October 23
# @command     sh linearize.sh
# @description Linearize PDF files in the current directory, recursively
# ------------------------------------------------------------------------------

# output text settings
NORMAL=$(tput sgr0)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)

# return true if the user replies 'yes', false if the user replies 'no'
prompt_yes() {
    printf '%s (%s / %s) ' "$1" "${GREEN}yes${NORMAL}" "${YELLOW}no${NORMAL}"
    read -r REPLY
    case "$REPLY" in
        yes) return 0 ;;
        no) return 1 ;;
    esac
    prompt_yes
}

# ------------------------------------------------------------------------------

# Resource to help understand find: https://mywiki.wooledge.org/UsingFind
# Find all PDF files not inside hidden directories.
# Check if each such file is linearized.
# If it is not, prompt the user to linearize it.
find . -type d -name '.?*' -prune -o \
    -type f -iname '*.pdf' \
    -execdir sh -c '! qpdf "$1" --check-linearization --no-warn 2>/dev/null | grep -q "no linearization errors"' _ '{}' ';' \
    -okdir qpdf --linearize --no-warn --replace-input '{}' ';'

if prompt_yes 'Were any warnings printed?'; then
    cat <<MESSAGE

    PDF files can contain junk objects, missing references, etc.
    Warnings may be printed after attempts to remove them.
    If you see such a warning, compare the output to the original input.

    The original file has ${CYAN}.~qpdf-orig${NORMAL} appended to its name.
    Note that, if there were errors instead of warnings,
    the original file was left untouched.

MESSAGE

    if prompt_yes 'Ignore warnings and remove originals?'; then
        find . -type f '(' -iname '*.pdf.~qpdf-orig' -o -iname '*.pdf.~qpdf-temp#' ')' -delete
    fi
fi
