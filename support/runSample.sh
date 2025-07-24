#!/bin/bash
#set -x
echo Submitting the job card to pbs
qsub ./launchCfp.pbs
echo wating 15 seconds for job completion
echo if you are on a busy system that might not be enough
echo in that case the information from cfp will eventually
echo show up in a file matching the cfp.o* glob
sleep 15
cat cfp.o*
rm cfp.o*
