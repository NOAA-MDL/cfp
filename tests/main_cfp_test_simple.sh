#!/usr/bin/env bash

# ----------------------------------------------------------------------------------------
# Build cfp command file
# ----------------------------------------------------------------------------------------
echo "./hello.sh One" > cfp_command_file.txt
echo "./hello.sh Two" >> cfp_command_file.txt
chmod 744 cfp_command_file.txt

# ----------------------------------------------------------------------------------------
# Set cfp env vars
# ----------------------------------------------------------------------------------------
export CFP_VERBOSE=1
export NCPUS=2

# ----------------------------------------------------------------------------------------
# Run cfp
# ----------------------------------------------------------------------------------------
mpirun -n ${NCPUS} ../cfp cfp_command_file.txt
ret=$?

echo "Exit code: $ret"
exit $ret
