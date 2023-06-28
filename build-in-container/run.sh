#! /bin/bash

help() {
    echo "------------ Mariner Build-in-Container ------------"
    echo "
    The run.sh script presents these options
    -t      creates container image
    -b      creates container, 
            builds the specs under $(pwd)/SPECS/ 
            and places the output under $(pwd)/out/
    -i      create interactive Mariner build container
    -c      cleans up the current workspace, container images and instances
    --help  shows help
    "
    echo "----------------------------------------------------"
}

create_container() {
    echo "Creating Container Image"
    source create-build-container.sh
}

build_mariner() {
    echo "Creating Mariner Build Container and building Mariner SPECS"
    source mariner-docker-run.sh build
}

interactive_container() {
    echo "Creating Interactive Mariner Build Container"
    source mariner-docker-run.sh interactive
}

cleanup() {
    echo "Cleaning up ....."
    rm -rf build ccache out scripts/toolkit scripts/out
    # remove Mariner dockers
    docker rm -f $(docker ps -a | grep mariner |tr -s " "| cut -d ' ' -f 1)
    # remove Mariner docker images
    docker rmi -f $(docker image ls | grep mariner |tr -s " "| cut -d ' ' -f 3)
}

while (( "$#")); do
  case "$1" in
    -t ) create_container; exit 0 ;;
    -b ) build_mariner; exit 0 ;;
    -i ) interactive_container; exit 0 ;;
    -c ) cleanup; exit 0 ;;
    --help ) help; exit 1 ;;
    ?* ) echo -e "ERROR: INVALID OPTION.\n\n"; help; exit 1 ;;
  esac
done

