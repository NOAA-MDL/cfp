#!/bin/bash
#set -x
#build everything
./build.sh
mkdir -p sample
cp ./support/launchCfp.pbs ./sample/
cp ./support/command_file ./sample/
cp ./support/runner.sh ./sample
cp ./support/runSample.sh ./sample/
cp ./support/buildSample.sh ./sample/
cp ./src/hello.f ./sample/
cp ./bin/cfp ./sample/
groff -Tascii -man ./support/readme.txt > ./sample/README
cd sample
./buildSample.sh
./runSample.sh
cd -
rm ./sample/hello
rm ./sample/cfp
