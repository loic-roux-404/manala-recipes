#!/usr/bin/env bash

VM_RECIPES=('dev.python-vm' 'ops.vagrant')
ANSIBLE_RECIPES=('ops.role' 'ops.playbook')
REPOSITORY=$(pwd)
DEBUG=${DEBUG:-0}

process_error () {
    echo "[ ERROR : $1 recipe failed ]"
    [ $DEBUG -eq 1 ] && exit 2 || true
    rm -rf .tests/${1}
    exit 2
}

process_test() {
    set -e
    # Definitions
    local recipe=$1
    local file=$2
    # template
    cp -f .tests/$file .tests/${recipe}/.manala.yaml;
    sed -ie "s/%RECIPE%/$recipe/g" .tests/${recipe}/.manala.yaml;
    rm -rf .tests/${recipe}/.manala.yamle
    # test
    manala --repository "$REPOSITORY" up .tests/${recipe}/ && \
        echo "[ PASSED : $recipe ]" || process_error "$recipe";
}

contains() {
    local needle="$1"
    shift 1;
    local arr=( "$@" )

    for v in "${arr[@]}"; do
        if [ "$v" == "$needle" ]; then
            return 0;
        fi
    done
   return 1;
}

guess_test() {
    contains $1 "${VM_RECIPES[@]}" \
        && process_test $1 vm.manala.yaml \
        && return 0;

    contains $1 "${ANSIBLE_RECIPES[@]}" \
        && process_test $1 ansible.manala.yaml \
        && return 0;

    process_test $1 classic.manala.yaml;
}

test_loop() {
    for d in */ ; do
        RECIPE=${d///} # remove the /
        CURR_DIR=.tests/${RECIPE}
        mkdir ${CURR_DIR}

        guess_test "$RECIPE"

        rm -rf ${CURR_DIR}
    done
}

test_loop