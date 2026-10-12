#!/bin/sh
for f in host/*.sh external/board/common/overlay/usr/bin/wl-test-all external/board/common/overlay/usr/bin/wl-test.d/* ; do sh -n "$f" || exit 1; done
