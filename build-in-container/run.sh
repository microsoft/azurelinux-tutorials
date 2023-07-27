#! /bin/bash

help() {
    echo "------------ Mariner Build-in-Container ------------"
    echo "
    The run.sh script presents these options
    -t                  creates container image
    -b [repo_dir]       creates container,
                        builds the specs under [repo_dir]/SPECS/,
                        and places the output under [repo_dir]/out/
                        (default: $repo_dir/{SPECS,out})
    -i [repo_dir]       create an interactive Mariner build container
    -c [repo_dir]       cleans up Mariner workspace at [repo_dir], container images and instances
                        (default: $repo_dir)
    --help              shows help on usage
    * unless provided, repo_dir defaults to the directory of the build-in-container tool
                        (default: $repo_dir)
    "
    echo "----------------------------------------------------"
}

create_container() {
    echo "Creating Container Image"
    source ${tool_dir}/create-build-container.sh
}

build_mariner() {
    echo "Creating Mariner Build Container and building Mariner SPECS"
    source ${tool_dir}/mariner-docker-run.sh build
}

interactive_container() {
    echo "Creating Interactive Mariner Build Container"
    source ${tool_dir}/mariner-docker-run.sh interactive
}

cleanup() {
    echo "Cleaning up mariner artifacts at $repo_dir ....."
    echo "This requires running as root ...."
    sudo rm -rf ${repo_dir}/build ${repo_dir}/ccache ${repo_dir}/logs ${repo_dir}/out ${repo_dir}/toolkit
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
    repo_dir="$(realpath $2)"
else
    repo_dir=$( realpath "$(dirname "$0")" )
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
