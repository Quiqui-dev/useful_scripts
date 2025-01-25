#!/bin/bash

# This script can be used to configure a python development environment
# Uses: create, activate, remove venv; install packages to venv; install and configure pre-commit.

print_help() {
    # Help message explaining script usage
    echo "Usage: $0 [option]"
    echo "Options:"
    echo "  create    Create a new virtual environment (.venv)"
    echo "  activate  Activate an existing virtual environment (.venv)"
    echo "  install   Install dependencies within a virtual environment (.venv)"
    echo "  export    Export installed dependencies to requirements.txt within a virtual environment (.venv)"
    echo "  remove    Remove an existing virtual environment (.venv)"
    echo "  precommit Configure Pre-commit for this environment"
}



create_venv() {


    if [ -d ".venv" ]; then
        echo "Virtual Environment '.venv' already exists... aborting."
        return 1
    fi

    case "$OSTYPE" in 
        "darwin"* )
            # Mac OSX
            python3 -m venv .venv;
            source .venv/bin/activate;
            ;;
        "msys")
            # Windows git bash
            python -m venv .venv;
            source .venv/Scripts/activate;
            ;;
        *)
            # Unknown.
            echo "Unknown opertaing system $OSTYPE... aborting"
            return 1
            ;;

    esac

    pip install -U pip
}

activate_venv() {

    echo "Attempting to activate virtual environment..."

    if [ ! -d ".venv" ]; then
        echo "Virtual Environment '.venv' does not exist... aborting."
        return 1
    fi

    case "$OSTYPE" in 
        "darwin"* )
            # Mac OSX
            source .venv/bin/activate
            ;;
        "msys")
            # Windows git bash
            source .venv/Scripts/activate
            ;;
        *)
            # Unknown.
            echo "Unknown opertaing system... aborting"
            return 1
            ;;

    esac

}

check_install_type() {

    if [ -f "requirements.txt" ]; then
        pip install -r ./requirements.txt
    elif [ -f "setup.py" ]; then
        pip install -e .
    fi
}

install_pkgs() {

    echo "Attempting to install packages..."

    # Check for an environment
    if [ ! -d ".venv" ]; then
        echo "Virtual Environment '.venv' does not exist... aborting.\nUse '$0 create' to create one"
        return 1
    fi

    # if exists then activate it
    activate_venv

    # check for the correct way to install packages

    if [ -d "src" ]; then 
        cd ./src
        check_install_type
        cd ..
    fi

    check_install_type

}

export_dependencies() {
    echo "Attempting to export dependencies to requirements file..."

    activate_venv

    pip freeze > requirements.txt

    echo "Dependencies exported to 'requirements.txt'"
}

remove_venv() {

    activate_venv

    deactivate

    rm -rf ".venv"
}

configure_pre_commit() {

    activate_venv

    pip install pre-commit

    cp ./pre-commit-configs/python-config.yaml ./pre-commit-config.yaml

    pre-commit install

}

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    print_help
    return 0
fi

case "$OSTYPE" in
    "darwin"* )
    # Mac OSX
    $OS_TYPE = "MAC"
    ;;
    "msys" )
    # Windows git bash
    $OS_TYPE = "WIN"
    ;;
    *)
    # Unknown.
    $OS_TYPE = "UNKNOWN"
    ;;
esac

case "$1" in
    "create")
        create_venv
        ;;
    "activate")
        activate_venv
        ;;
    "install")
        install_pkgs
        ;;
    "export")
        export_dependencies
        ;;
    "remove")
        remove_venv
        ;;
    "precommit")
        configure_pre_commit
        ;;
    *)
        echo "Unknown option: $1"
        print_help
        exit 1
        ;;
esac