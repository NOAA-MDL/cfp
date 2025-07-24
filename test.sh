#!/bin/bash
#set -x
echo 'This wil build and test the minimal case of mpi cfp.'

#scrub everyting out
./clean.sh
#build everything
./build.sh
mkdir -p test
cd test
cp ../support/* .
cp ../bin/cfp .
#submit the job card to pbs
qsub ./launchCfp.pbs
echo "Waiting for job to finish"
echo "Will update every 10 seconds until completed"
while sleep 10 ;do
    cat cfp.o*
    if grep "aprun of COMPLETED" cfp.o*;then
        echo PASS PASS PASS PASS PASS PASS PASS PASS PASS PASS PASS 
        echo "test succeeded."
        break
    fi
done    

