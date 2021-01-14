#!/usr/bin/env bash

##################################################
#
# This function is used to check that a command is 
# available on the host
#
###################################################

function checkCommand {
    if ! command -v $1 &> /dev/null
    then
        printf "\n%s\n" "====> The prerequisite command [$1] could not be found"
        if [[ ! -z $2 ]]; then
            printf "%s\n\n" "======> \"$2\""
        fi
        exit
    fi
}

##################################################
#
# This function is used to check that a directory
# exists
#
###################################################

# This will return 0 if the directory is empty or non existant
# Otherwise it will return the number of files in the directory
function dirCheck {
    log 'debug' "Verifying [$1] is a directory"
    if [[ -d $1 ]]; then
        count=$(ls -1 $1 2> /dev/null| wc -l | tr -d '[:space:]')
        log 'debug' "[$count] file(s) found in [$1]"
        if [[ ${count} -ge 255 ]]; then
            log 'warn' "This script can only return up to 255"
        fi
        return $count
    else
        log 'debug' "[$1] is not a directory"
        return 0
    fi
}

##################################################
#
# This function will check to make sure a given
# envar is set, log the key value, and return 1
# if it is unset
#
###################################################

function checkEnv(){
    key=${1:-}
    value=${!1:-}
    if [[ ! -z ${value} ]]; then
        log info "--> $key: ${value}"
        return 0
    else
        log warn "--> $key: not set!"
        return 1
    fi
}

##################################################
#
# These functions are used to test the connection 
# to Grey Matter Control Api and Catalog Api
#
###################################################

function currentConfigs() {
    count=0

    for c in  GREYMATTER_CONSOLE_LEVEL GREYMATTER_API_HOST GREYMATTER_API_SSLCERT GREYMATTER_API_SSLKEY GREYMATTER_API_SSL GREYMATTER_API_PREFIX GREYMATTER_API_INSECURE GREYMATTER_CATALOG_PREFIX
    do
        checkEnv "$c"
        if [[ $? -gt 0 ]]; then 
            unset_envars+=("$c")
            count=$((count+1))
        fi
    done

    if [[ $count -gt 0 ]]; then 
        log error "You need to set the following environment variables to point to the service mesh you want to apply config changes too:\n    ${unset_envars[*]}"
        exit 2
    fi
}

# this can recive an argument that will set the currentConfigs logging level
# will exit code 1 if there is an error
testControlApiConnection() {
    log_lvl=${1:-debug}
    currentConfigs $log_lvl
    catch=$(greymatter list cluster 2>&1)
    if [[ $? -gt 0 ]]; then 
        log 'error' "====> there was an issue connecting to Grey Matter Control API\n====> Check your environment variables used to configure the cli\n====> Run this again with \"-d debug\" to get more info"
    else
        log 'info' "\n* * * Connection was made to Grey Matter Control API * * *\n"
    fi
}

testCatalogApiConnection() {
    log_lvl=${1:-debug}
    
    GREYMATTER_CATALOG_PREFIX=${GREYMATTER_CATALOG_PREFIX:-/services/catalog/latest}
    currentConfigs $log_lvl

    host=$(echo $GREYMATTER_API_HOST | awk 'BEGIN { FS = ":" } ; { print $1 }')
    base_url="https://$host$GREYMATTER_CATALOG_PREFIX/zones"

    catch=$(curl --write-out '%{http_code}' --silent --output /dev/null -k --cert $GREYMATTER_API_SSLCERT --key $GREYMATTER_API_SSLKEY $base_url)
    log debug "catalog response code: $catch"
    if [[ $catch -ne 200 ]]; then 
        log 'warn' "====> Response code from catalog [${catch}]"
        log 'warn' "====> There was an issue connecting to Catalog Api API\n====> Check your environment variables used to configure \n====> Run this again with \"-d debug\" to get more info"
        return 3
    else
        log 'info' "* * * Connection was made to Catalog Api API * * *\n"
    fi
}

testConnections(){
    testControlApiConnection
    testCatalogApiConnection
    if [[ $? -gt 0 ]]; then log error "Hint: Check that [${GREYMATTER_CATALOG_PREFIX}] is the catalog endpoint for your mesh"; fi
}

# This function mimics the readarray function linux has
# Usage:
    # ```
    # echo "$(lookup_changed_charts "$latest_tag")" > temp.txt
    # # set -x
    # readarray changed_charts temp.txt
    # rm temp.txt
    # ```
readarray() {
    local __resultvar=$1
    declare -a __local_array
    let i=0
    while IFS=$'\n' read -r line_data; do
        __local_array[i]=${line_data}
        ((++i))
    done < $2
    if [[ "$__resultvar" ]]; then
        eval $__resultvar="'${__local_array[@]}'"
    else
        echo "${__local_array[@]}"
    fi
}