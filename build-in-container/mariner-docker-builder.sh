#! /bin/bash

# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

set -e

help() {
    echo "------------ Mariner Build-in-Container ------------"
    echo "
    The mariner-docker-builder.sh script presents these options
    -t                  creates container image
    -b [mariner_dir]    creates container,
                        builds the specs at [mariner_dir]/SPECS/,
                        and places the output under [mariner_dir]/out/
                        (default: $mariner_dir/{SPECS,out})
    -i [mariner_dir]    create an interactive Mariner build container
    -c [mariner_dir]    cleans up Mariner workspace at [mariner_dir], container images and instances
                        (default: $mariner_dir)
    --help              shows help on usage
    
    * unless provided, mariner_dir defaults to the directory of the build-in-container tool
                        (default: $mariner_dir)
    "
    echo "----------------------------------------------------"
}

create_container() {
    echo "Creating Container Image"
    source ${tool_dir}/create-container.sh
}

build_mariner() {
    echo "*** Mariner artifacts will be used from $mariner_dir ***"
    echo "Creating Mariner Build Container and building Mariner SPECS"
    source ${tool_dir}/run-container.sh build
}

interactive_container() {
    echo "*** Mariner artifacts will be used from $mariner_dir ***"
    echo "Creating Interactive Mariner Build Container"
    source ${tool_dir}/run-container.sh interactive
}

cleanup() {
    echo "Cleaning up mariner artifacts at $mariner_dir ....."
    echo "This requires running as root ...."
    sudo rm -rf ${mariner_dir}/build ${mariner_dir}/ccache ${mariner_dir}/logs ${mariner_dir}/out ${mariner_dir}/toolkit
    # remove Mariner docker containers
    docker rm -f $(docker ps -aq --filter ancestor="mcr.microsoft.com/mariner-container-build:2.0")
    # remove Mariner docker images
    docker rmi -f $(docker images -aq --filter reference="mcr.microsoft.com/mariner-container-build")
}

tool_dir=$( realpath "$(dirname "$0")" )

if [ "$#" -eq 0 ]
then
    help >&2
    exit 1
fi

if [ -n "$2" ]
then
    mariner_dir="$(realpath $2)"
else
    mariner_dir=$( realpath "$(dirname "$0")" )
fi

while (( "$#")); do
  case "$1" in
    -t ) create_container; exit 0 ;;
    -b ) build_mariner; exit 0 ;;
    -i ) interactive_container; exit 0 ;;
    -c ) cleanup; exit 0 ;;
    --help ) help; exit 0 ;;
    ?* ) echo -e "ERROR: INVALID OPTION.\n\n"; help; exit 1 ;;
  esac
done
