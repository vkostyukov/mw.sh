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

    local action="$1" ; shift 
    local request="action=$action"

    while [ $# -gt 0 ]
    do
        case "$1" in
            --api=*) API=${1#*=} ;;
            --user=*) USER=${1#*=} ;;
            --passwd=*) PASSWD=${1#*=} ;;
            --format=*) FORMAT=${1#*=} ;;
            --silent) SILENT=true ;;
            --*=*)
                local param=${1#--*}
                request="$request&$param"
                ;;
            *) request="$request&$1"
        esac
        shift
    done

    if [ `type -t action_$action`"" == "function" ] ; then
        action_"$action" "$request"
    else
        print "Performing custom request '$request'... "
        local data=$(__get "$request")
        echo "$data"
    fi
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
    echo "    purge     Purges the cache for the given titles"
    echo "    delete    Deletes a page"
    echo "    move      Moves a page"
    echo "    edit      Creates/edites a page"
    echo "    upload    Uploads a file to MediaWiki"
    echo "    import    Imports data to MediaWiki"
    echo "    watch     Adds/removes pages to/from watchlist"
    echo "    help      Shows help information"
    echo
    echo "Try '$MWSH_NAME <action> help' for action information."
}

action_test() {

    print "Testing connection to '$API' ... "
    local data=$(__get)
    if [ -z "$data" ] ; then
        print "FAIL"
        RETURN=1
    else
        print "OK"
    fi

}

action_login() {

    print "Logging in to '$API' as '$USER' ... "

    local token=""

    while true ; do
        local response=$(FORMAT=xml __post "$1&lgname=$USER&lgpassword=$PASSWD&$token")
        local result=$(echo "$response" | egrep -o "result=[^ ]*" | sed "s/\"//g" | sed "s/result=//")

        if [ "$result" == "NeedToken" ] ; then
            token=$(echo "$response" | egrep -o "token=[^ ]*" | sed "s/\"//g" | sed "s/token/lgtoken/")
        elif [ "$result" == "Success" ] ; then
            print "OK"
            exit 0
        else 
            print "$result"
            exit 1
        fi
    done
}

action_logout() {
    print "Loggin out from '$API' as '$USER' ... "  
    local response=$(FORMAT=xml __post "$1")
    rm cookies
    print "OK"
}

action_purge() {
    echo "Purge"
}

action_delete() {
    echo "Delete"
}

action_move() {
    echo "Move"
}

action_edit() {
    echo "Edit"
}

action_upload() {
    echo "Upload"
}

action_import() {
    echo "Import"
}

action_watch() {
    echo "Watch"
}

# routines

__get() {
    local result=`curl -s "$API?$1&format=$FORMAT"`
    echo "$result"
}

__post() {
    local result=`curl -s -c cookies -b cookies -d "$1&format=$FORMAT" "$API"`
    echo "$result"
}

# entry point

main "$@"
