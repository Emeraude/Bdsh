#!/bin/bash

file="sh.db"
displayKey=0

function printusage() {
cat <<EOT
    bdsh.sh [-k] [-f <db_file>] (put (<key> | $<key>) (<value> | $<key>) |
                                del (<key> | $<key>) [<value> | $<key>] |
                                select [<expr> | $<key>] )
    Emulate simples functionalities of a database.
    The database is basically contained in the sh.db file.

    [-f <db_file>]    Specify a custom db file.
    [-k]              On display commands, if this option is on, the key is shown as <key>=<value>
EOT
}
while getopts :f:k option
do
    case "$option" in
        f) file="$OPTARG" ;;
        k) displayKey=1 ;;
        :) echo "Syntaxe error :"; printusage; exit 1 ;;
        ?)  echo "Syntaxe error :"; printusage; exit 1 ;;
    esac
done
echo "$file"
echo "$displayKey"

echo "${0##*/}"
