#!/bin/bash
# Load shared setup scripts
source /home/dev/.local/bin/shared-entrypoint.sh

default_entry

RUBYVERSION="3.0.4"

setup_ruby() {
    install_and_use_ruby "$RUBYVERSION"
}

setup_js() {
    yarn install
}

if [ ! -f "${REPO_SETUP_PATH}" ]; then

    #setup_ruby

    setup_js

    touch "${REPO_SETUP_PATH}"

fi
fin

exec "$@"
