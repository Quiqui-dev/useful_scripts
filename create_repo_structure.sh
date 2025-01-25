#!/bin/bash

# My personal preference for a repo structure

create_dirs() {
    mkdir src
    mkdir cicd
    mkdir cicd/build
    mkdir cicd/deploy
    mkdir cicd/pr
    mkdir tests
}

replace_and_create_dirs() {

    if [ -d "src" ]; then
        rm -rf src
    fi

    if [ -d "cicd" ]; then
        rm -rf cicd
    fi

    if [ -d "tests" ]; then
        rm -rf tests
    fi

    create_dirs
}




replace_and_create_dirs
