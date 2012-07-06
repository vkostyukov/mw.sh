#!/bin/bash

# MediaWiki API client written in bash
# Copyright 2012 Vladimir Kostyukov http://vkostyukov.ru
#
# License: http://www.apache.org/licenses/LICENSE-2.0.html 
# GitHub: https://github.com/vkostyukov/mw.sh

MWSH_NAME="mw.sh"
MWSH_VERSION="0.1"
MWSH_CONFIG=".mwsh"

MWSH_WELCOME="$MWSH_NAME :: MediaWiki API client ver. $MWSH_VERSION written in bash."
MWSH_OPTS="-o a:u:p:sf: -l api:,user:,passwd:,silent,format:"

API=
USER=
PASSWD=
SILENT=false
FORMAT=json

DATA=
RETURN=0

print() {
    if ! $SILENT ; then
        printf "%s" "$@"
    fi
}

main() {
    if [[ -f ~/$MWSH_CONFIG ]]; then
        . ~/$MWSH_CONFIG
    fi

    set -- `getopt -u $MWSH_OPTS -- "$@"`
    while [ $# -gt 0 ]
    do
        case "$1" in
            -a|--api) API="$2" ; shift ;;
            -u|--user) USER="$2" ; shift ;;
            -p|--passwd) PASSWD="$2" ; shift ;;
            -f|--format) FORMAT="$2" ; shift ;;
            -s|--silent) SILENT=true ;;
            (--) shift ; break ;;
            (*) break ;;
        esac
        shift
    done

    case "$1" in
        test) action_test "$@" ;;
        login) action_login "$@" ;;
        logout) action_logout "$@" ;;
        query) action_query "$@" ;;
        parse) action_parse "$@" ;;
        purge) action_purge "$@" ;;
        delete) action_delete "$@" ;;
        move) action_move "$@" ;;
        edit) action_edit "$@" ;;
        upload) action_upload "$@" ;;
        import) action_import "$@" ;;
        watch) action_watch "$@" ;;
        custom) action_custom "$@" ;;
        help|"") action_help ; exit 1 ;;
        *) echo "Can't find '$1' action. Try '$MWSH_NAME help'." ; exit 1 ;;
    esac
}

# actions & helps

action_help() {
    echo $MWSH_WELCOME
    echo
    echo "Usage '$MWSH_NAME <ACTION> [<ARGS>] [-a|--api <API>] [-u|--user <USER>]"
    echo "       [-p|--passwd <PASSWD>] [-f|--format <FORMAT>] [-s| --silent]'"
    echo 
    echo "Global parameters:"
    echo "    -a|--api <API>        URL to MediaWiki API script"
    echo "    -u|--user <USER>      MediaWiki username"
    echo "    -p|--passwd <PASSWD>  User's password"
    echo "    -f|--format <FORMAT>  Sets data format"
    echo "    -s|--silent           Enables silent mode"
    echo
    echo "Availible actions:"
    echo "    test      Tests connection to MediaWiki"
    echo "    login     Logins to MediaWiki"
    echo "    logout    Logouts from MediaWiki"
    echo "    query     Performes standart MediaWiki Query"
    echo "    parse     Parses wikitext and returns parser output"
    echo "    purge     Purges the cache for the given titles"
    echo "    delete    Deletes a page"
    echo "    move      Moves a page"
    echo "    edit      Creates/edites a page"
    echo "    upload    Uploads a file to MediaWiki"
    echo "    import    Imports data to MediaWiki"
    echo "    watch     Adds/removes pages to/from watchlist"
    echo "    custom    Performes custom API action"
    echo "    help      Shows help information"
    echo
    echo "Try '$MWSH_NAME <action> help' for action information."
}

action_test() {
    __pre_action "$@"

    print "Testing connection to '$API' ... "
    local data=$(__get $API)
    if [ -z "$data" ] ; then
        print "disconnected"
        RETURN=1
    else
        print "connected"
    fi

    __post_action "$@"
}

help_test() {
    echo $MWSH_WELCOME
    echo
    echo "Action:      'test'"
    echo "Description: Tests conntection to MediaWiki"
    echo "Usage:       '$MWSH_NAME test'"
}

action_login() {
    __pre_action "$@"

    print "Logging in to '$API' ... "
    local data=$(__post "lgname=test&lgpassword=test&format=xml" $API?action=login)
    echo $data

    __post_action "$@"
}

help_login() {
    echo "help for login"
}

action_logout() {
    echo "Logout"
}

help_logout() {
    echo "help for logout"
}

action_query() {
    echo "Query"
}

help_query() {
    echo "help for query"
}

action_parse() {
    echo "Parse"
}

help_parse() {
    echo "help for parse"
}

action_purge() {
    echo "Purge"
}

help_purge() {
    echo "help for purge"
}

action_delete() {
    echo "Delete"
}

help_delete() {
    echo "help for delete"
}

action_move() {
    echo "Move"
}

help_move() {
    echo "help for move"
}

action_edit() {
    echo "Edit"
}

help_edit() {
    echo "help for edit"
}

action_upload() {
    echo "Upload"
}

help_upload() {
    echo "help for upload"
}

action_import() {
    echo "Import"
}

help_import() {
    echo "help for import"
}

action_watch() {
    echo "Watch"
}

help_watch() {
    echo "help for watch"
}

action_custom() {
    echo "custom"
}

help_custom() {
    echo "help for custom"
}

# routines

__pre_action() {
    if [ "$2" == "help" ] ; then 
        help_"$1"
        exit 1
    fi
}

__post_action() {
    exit $RETURN
}

__get() {
    local result=`curl -s "$1"`
    echo "$result"
}

__post() {
    local result=`curl -s -d "$1" "$2"`
    echo "$result"
}

# entry point

main "$@"
