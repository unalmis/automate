#!/bin/sh
# ------------------------------------------------------------------------------
# @author      Kaya Unalmis
# @license     GNU GPLv3
# @date        2022 November 24
# @command     sh replace.sh
# @description Replace strings within files in the current directory, recursively
# ------------------------------------------------------------------------------

printf  '%s\n' 'Include backslashes before special characters.'
printf 'Enter the regexp to match against: '
read -r regexp
printf 'Enter the replacement string: '
read -r replacement

find . -type f -execdir sed --in-place "s/${regexp}/${replacement}/g" '{}' '+'
