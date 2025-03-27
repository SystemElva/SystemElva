#!/bin/sh

# Ensure that the work-directory is the i686/ - direcetory
cd $(dirname $0)

# Redirect to the src-sh/ - internal 'd.sh',
# using the system's preferred shell
$SHELL "src-sh/do.sh" "$@"

