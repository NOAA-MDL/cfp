#!/bin/bash
#clean up litter from prior run
#for file in cfp.[0-9]* cfp.o* CFP* .o ;do
#  if [ -f "$file" ];then
#    rm "$file"
#  elif [ -d "$file" ];then
#    rm -r "$file"
#  fi
#done
for dir in ./test ./sample ./bin ./stage progenv_version.txt progenv.txt tmpfile.* current_version.txt ;do
    rm -rf $dir
done
echo "cleaned up the litter and executables for rebuild"
