#!/bin/bash
# Run a command on rigless detached from the ssh session. Usage: rigless-detach.sh <log> <command...>
# Log lands at ~/<log> on rigless; read it with: ssh carlos@rigless tail ~/<log>
LOG=$1
shift
ssh carlos@rigless "nohup bash -c '$*' > ~/$LOG 2>&1 < /dev/null & echo started pid \$!"
