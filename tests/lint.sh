#!/bin/sh
for f in external/board/common/overlay/usr/bin/wl-test-all external/board/common/overlay/usr/bin/wl-test.d/* scripts/flash.sh; do sh -n "$f" || exit 1; done
