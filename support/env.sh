#dont allow xtrace as modules are sourced
XTRACE_COMMAND=":"
$(set | egrep -s -q "^SHELLOPTS.*xtrace")
if [ $? -eq 0 ];then
    XTRACE_COMMAND="set -x"
fi
set +x 
module purge 2>&1 >/dev/null
module load cce
module load cray-libsci
module load cray-mpich
module load craype
module load craype-x86-rome
module load libfabric
module load craype-network-ofi
module load cray-dsmml
module load perftools-base
#module load xpmem
module load intel
module load cpe-intel
module load cray-pals

#now reset the xtrace if needed
$XTRACE_COMMAND

#module list -t 
