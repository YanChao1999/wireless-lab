#!/bin/sh
# Syntax-check and shellcheck every shell script in the project.
files="external/board/common/overlay/usr/lib/wl-test/lib.sh host/*.sh tests/*.sh external/board/common/overlay/usr/bin/wl-test-all external/board/common/overlay/usr/bin/wl-test.d/*"
rc=0
for f in $files; do sh -n "$f" || rc=1; done
if command -v shellcheck >/dev/null 2>&1; then
    # shellcheck disable=SC2086
    shellcheck -x -s sh $files || rc=1
else
    echo "shellcheck not installed; skipping (install it, CI requires it)" >&2
    [ -z "${CI:-}" ] || rc=1
fi
exit $rc
