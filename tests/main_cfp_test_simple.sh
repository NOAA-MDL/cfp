#!/usr/bin/env bash

echo "./hello.sh One" > cfp_command_file.txt
echo "./hello.sh Two" >> cfp_command_file.txt
chmod 744 cfp_command_file.txt

export CFP_VERBOSE=1
export NCPUS=2

mpirun -N 2 ../cfp cfp_command_file.txt

echo "Exit code: $?"
