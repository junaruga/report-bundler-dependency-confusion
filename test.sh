#!/bin/bash

set -euxo pipefail

ROOT_DIR=$(dirname "${0}")
pushd "${ROOT_DIR}" > /dev/null
ROOT_DIR="${PWD}"
popd > /dev/null

TEST_BUNDLE="bundle"
# You can set the bundle path from the repository.
TEST_BUNDLE="ruby ${HOME}/git/rubygems/bundler/spec/support/bundle.rb"

TEST_GEM_DIR="${ROOT_DIR}/test/fixtures/gems"
TEST_TMP_DIR="${ROOT_DIR}/tmp"
TEST_REPO_DIR="${TEST_TMP_DIR}/repos"
TEST_REPO_SERVER_PUBLIC_PORT=8801
TEST_REPO_SERVER_PRIVATE_PORT=8802
TEST_REPO_SERVER_PORTS="${TEST_REPO_SERVER_PUBLIC_PORT} ${TEST_REPO_SERVER_PRIVATE_PORT}"
TEST_REPO_DIR_PUBLIC="${TEST_REPO_DIR}/${TEST_REPO_SERVER_PUBLIC_PORT}"
TEST_REPO_DIR_PRIVATE="${TEST_REPO_DIR}/${TEST_REPO_SERVER_PRIVATE_PORT}"

gem_install() {
    gem install "${@}"
}

install_test_gems_to_repos() {
    echo "* Installing gems to repositories ..."

    rm -rf "${TEST_REPO_DIR}"

    mkdir -p "${TEST_REPO_DIR_PUBLIC}"
    gem_install --install-dir "${TEST_REPO_DIR_PUBLIC}" --no-user-install \
        --local "${TEST_GEM_DIR}/a-0.0.2/a-0.0.2.gem"

    mkdir -p "${TEST_REPO_DIR_PRIVATE}"
    gem_install --install-dir "${TEST_REPO_DIR_PRIVATE}" --no-user-install \
        --local "${TEST_GEM_DIR}/a-0.0.1/a-0.0.1.gem"
    gem_install --install-dir "${TEST_REPO_DIR_PRIVATE}" --no-user-install \
        --local --force "${TEST_GEM_DIR}/b/b-1.0.0.gem"
}

start_server() {
    if [ "${#}" -lt 1 ]; then
        return 1
    fi
    port="${1}"

    gem server --dir "${PWD}" --bind 127.0.0.1 --port "${port}" --debug \
        >& server.log &
    pid="${!}"
    echo "${pid}" > server.pid
    echo "* Starting server (port: ${port}, pid: ${pid}) ..."
    sleep 1
}

start_servers() {
    for port in ${TEST_REPO_SERVER_PORTS}; do
        pushd "${TEST_REPO_DIR}/${port}" > /dev/null
        start_server "${port}"
        popd > /dev/null
    done
}

stop_servers() {
    for port in ${TEST_REPO_SERVER_PORTS}; do
        pushd "${TEST_REPO_DIR}/${port}" > /dev/null
        pid=$(cat server.pid)
        echo "* Stopping server (port: ${port}, pid: ${pid}) ..."
        kill "${pid}" || :
        popd > /dev/null
    done
}

stop_servers_forcely() {
    pkill -f "gem server" || :
}

run_test() {
    # Clean bundler files.
    rm -f "${ROOT_DIR}/Gemfile.lock"
    rm -rf "${ROOT_DIR}/app"

    ${TEST_BUNDLE} config set path app
    ${TEST_BUNDLE} install
    ${TEST_BUNDLE} info a
}

main() {
    install_test_gems_to_repos
    # stop_servers_forcely
    start_servers
    run_test
    stop_servers
}

main
