#!/bin/sh
# ------------------------------------------------------------------------------
# @author       Kaya Unalmis
# @license      GNU GPLv3
# @date         2022 October 23
# @command      sh mitosis.sh
# @description  Back up (restore) files to (from) your archive
# ------------------------------------------------------------------------------

case "$(uname -s)" in
    Darwin)
        ARCHIVE_PREFIX="/Volumes/"
        ;;
    *)
        # Some Linux systems mount drives under '/media' instead of '/run/media'.
        if [ -d "/run/media/${USER}" ]; then
            ARCHIVE_PREFIX="/run/media/${USER}/"
        else
            ARCHIVE_PREFIX="/media/${USER}/"
        fi
        ;;
esac

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

# ensure user understands what the back up and restore options do
show_warning() {
    cat <<MESSAGE

    I think the path to the archive is: ${CYAN}${2}${NORMAL}
    The path should not be enclosed in quotes.
    Please ${GREEN}confirm${NORMAL} this is correct.

    The source will be replicated at the destination.
    Files in the destination are deleted if they are not in the source.

    Two options:
    Back up
            source:      ${CYAN}${1}/example${NORMAL}
            destination: ${CYAN}${2}/example${NORMAL}
    Restore
            source:      ${CYAN}${2}/example${NORMAL}
            destination: ${CYAN}${1}/example${NORMAL}

    After selecting an option, you will be asked whether to perform a dry run.
    Dry runs do not make any changes.
    Dry runs only print to the terminal what would have happened.
    Please do a dry run if you have not used this program before.

MESSAGE
}

# recursively archive files in the 1st directory to the 2nd directory
archive() {
    # deletes files in the 2nd directory if they don't exist in the 1st
    # remove '--delete-excluded' to avoid this
    # note that --include='.git' should always be paired with --delete
    if rsync --help 2>/dev/null | grep -q -- '--info='; then
        progress='--info=progress2'
    else
        progress='--progress'
    fi

    if reply_yes 'Dry run?'; then
        rsync --dry-run --verbose --itemize-changes \
            --archive --no-D --prune-empty-dirs \
            --delete-excluded --include='.git' --exclude='.*' \
            --human-readable -- "$1" "$2"
    else
        rsync --archive --no-D --prune-empty-dirs \
            --delete-excluded --include='.git' --exclude='.*' \
            "$progress" --human-readable -- "$1" "$2"
    fi
}

clear
printf 'Enter the name (without enclosing quotes) of your archive: '
read -r name
archive_path="${ARCHIVE_PREFIX}${name}"
show_warning "$HOME" "$archive_path"

if reply_yes 'Back up?'; then
    src="$HOME"
    dst="$archive_path"
    [ -d "$dst" ] || exit 1
    archive "${src}/Documents/" "${dst}/Documents"
elif reply_yes 'Restore?'; then
    src="$archive_path"
    dst="$HOME"
    [ -d "$src" ] || exit 1
    archive "${src}/Documents/" "${dst}/Documents"
fi
# archive "${src}/Music/" "${dst}/Music"
# archive "${src}/Pictures/" "${dst}/Pictures"
# archive "${src}/Videos/" "${dst}/Videos"
