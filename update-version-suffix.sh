#!/bin/bash


# this script will update all Chart.yaml versions that match input to output
# if  $1) aplha and $2) beta the script will parse through Chart.yaml and if there is a version: x.x.x-alpha then it will up that to x.x.x-beta
# set -xe

REPO_HOME=${REPO_HOME:="$(git rev-parse --show-toplevel)"}

source $REPO_HOME/scripts/lib/helper.sh

main(){
    chartListRaw=$(find ${REPO_HOME} -name "Chart.yaml")
    for i in $chartListRaw; do
        curver=$(cat $i | yq -r '.version')
        printf "%s \n   %s\n" "$i" "$curver"
        # set -x
        if [[ $curver =~ "${1}" ]]; then
            echo "will replace"

            echo "currentVersion: $curver"
            baseVer=$(echo $curver | cut -f1 -d"-")
            echo "Base Version: $baseVer"
            nextVer=$(printf "%s-%s" "$baseVer" "${2}")
            echo "New Version: ${nextVer}"

            export CV1=$nextVer
            cat $i | yq -Y '.version=env.CV1' > temp.yaml
            cp temp.yaml ${i} && rm temp.yaml

            unset CV1
        fi
        # set +x
        updateDependency $i
    done

}

updateDependency(){
    cat $1 | yq -r -e '.dependencies[].repository' > temp.txt
    readarray array temp.txt && rm temp.txt
    echo $array
}


main $1 $2