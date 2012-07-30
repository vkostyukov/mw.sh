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
        if [ -z "$@" ] ; then 
            printf "\n"
        else 
            printf "%s" "$@"
        fi
    fi
}

main() {
    if [[ -f ~/$MWSH_CONFIG ]]; then
        . ~/$MWSH_CONFIG
    fi

    local action="$1" ; shift 
    local request=""

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
        print "Performing custom request 'action=$action$request'... "
        local data=$(__get "action=$action$request")
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
    echo "    edit      Creates/edits a page"
    echo "    email     Emails to user"
    echo "    upload    Uploads a file to MediaWiki (not implemented: send request)"
    echo "    import    Imports data to MediaWiki (not implemented: send request)"
    echo "    watch     Adds page to watchlist"
    echo "    unwatch   Removes pages from watchlist"
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
        local response=$(FORMAT=xml __post "action=login&lgname=$USER&lgpassword=$PASSWD&lgtoken=$token")
        local result=$(__fetch "$response" "result")

        if [ "$result" == "NeedToken" ] ; then
            token=$(__fetch "$response" "token")
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
    local trash=$(FORMAT=xml __post "$1")
    rm cookies
    print "OK"
}

action_purge() {
    local titles=$(__arg "$1" "titles")
    print "Purging wiki pages '$titles' ... "

    local trash=$(FORMAT=xml __post "action=purge&titles=$titles")

    print "OK"
}

action_delete() {
    local title=$(__arg "$1" "title")

    print "Deleting wiki page '$title' ... "

    local response=$(FORMAT=xml __post "action=query&prop=info&intoken=delete&titles=$title")
    local token=$(__fetch "$response" "deletetoken" | sed "s/+/%2B/g")
    local trash=$(FORMAT=xml __post "action=delete&title=$title&token=$token")

    print "OK" 
}

action_move() {
    local from=$(__arg "$1" "from")
    local to=$(__arg "$1" "to")

    print "Moving page '$from' to '$to' ... "

    local response=$(FORMAT=xml __post "action=query&prop=info&intoken=move&titles=$from")
    local token=$(__fetch "$response" "movetoken" | sed "s/+/%2B/g")
    local trash=$(FORMAT=xml __post "action=move&from=$from&to=$to&token=$token&movetalk=true&noredirect=true")

    print "OK"
}

action_edit() {
    local title=$(__arg "$1" "title")
    local text=$(__arg "$1" "text")

    print "Editing/Creating wiki page '$title' ... "

    local response=$(FORMAT=xml __post "action=query&prop=info&intoken=edit&titles=$title")
    local token=$(__fetch "$response" "edittoken" | sed "s/+/%2B/g")
    local trash=$(FORMAT=xml __post "action=edit&title=$title&token=$token&text=$text")

    print "OK"
}

action_email() {
    local to=$(__arg "$1" "to")
    local subject=$(__arg "$1" "subject")
    local text=$(__arg "$1" "text")

    print "Emailing to '$to' ... "

    local response=$(FORMAT=xml __post "action=query&prop=info&intoken=email&titles=User:$to")
    local token=$(__fetch "$response" "emailtoken" | sed "s/+/%2B/g")
    local trash=$(FORMAT=xml __post "action=emailuser&target=User:$to&subject=$subject&text=$text&token=$token")

    print "OK"
}

action_upload() {
    print "Please, contact author: he'll write this action for you."
    print
    print "See details: http://www.mediawiki.org/wiki/API:Upload"
}

action_import() {
    print "Please, contact author: he'll write this action for you."
    print
    print "See details: http://www.mediawiki.org/wiki/API:Import"
}

action_watch() {
    local title=$(__arg "$1" "title")

    print "Watching wiki page '$title' ... "

    local response=$(FORMAT=xml __post "action=query&prop=info&intoken=watch&titles=$title")
    local token=$(__fetch "$response" "watchtoken" | sed "s/+/%2B/g")
    local trash=$(FORMAT=xml __post "action=watch&title=$title&token=$token")

    print "OK" 
}

# DRY broken
action_unwatch() {
    local title=$(__arg "$1" "title")

    print "Unwatching wiki page '$title' ... "

    local response=$(FORMAT=xml __post "action=query&prop=info&intoken=watch&titles=$title")
    local token=$(__fetch "$response" "watchtoken" | sed "s/+/%2B/g")
    local trash=$(FORMAT=xml __post "action=watch&title=$title&unwatch=true&token=$token")

    print "OK" 
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

__fetch() {
    echo "$1" | egrep -o "$2=[^ ]*" | sed "s/\"//g" | sed "s/$2=//"
}

__arg() {
    echo "$1" | egrep -o "$2=[^&]*" | sed "s/$2=//"
}

# entry point

main "$@"
