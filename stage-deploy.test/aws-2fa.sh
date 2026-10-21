#!/bin/bash
# Fake aws-2fa.sh: records the approval request, then runs the command (= Carlos approved).
echo "$1" >>"$FIXTURES/approvals.log"
shift 2
"$@"
