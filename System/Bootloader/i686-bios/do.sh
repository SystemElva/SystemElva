#!/bin/bash

# Ensure that the work-directory is the i686/ - direcetory
cd $(dirname $0)

bash "src-sh/do.sh" "$@"

