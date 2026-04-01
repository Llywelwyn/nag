# test/test_helper.bash
# Shared setup/teardown for nag tests.

_NAG="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)/nag"

setup() {
  export NAG_PATH
  NAG_PATH="$(mktemp)"
  rm -f "${NAG_PATH}"
  export NAG_CMD="true"
}

teardown() {
  rm -f "${NAG_PATH}" "${NAG_PATH}.lock"
}

run_nag() {
  run "${_NAG}" --yes "$@"
}
