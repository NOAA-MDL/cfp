#!/bin/bash 
export CFP_COMPILER=intel
export CFP_LINK_TYPE=MPICH
source ./support/env.sh

localArgs="-dynamic -132 -qopenmp"

#make the main cfp executable
mkdir -p ./bin
echo "Building main cfp application"
ftn $localArgs -o ./bin/cfp.o -c ./src/cfp.f
ftn $localArgs -o ./bin/cfp \
-Wl,-rpath,/opt/cray/libfabric/1.11.0.0.233/lib64 \
-Wl,-rpath,/opt/intel/compilers_and_libraries_2020.3.275/linux/mpi/intel64/lib/release \
-Wl,-rpath,/opt/intel/compilers_and_libraries_2020.3.275/linux/mpi/intel64/lib \
-Wl,-rpath,/opt/intel/compilers_and_libraries_2020.3.275/linux/ipp/lib/intel64 \
-Wl,-rpath,/opt/intel/compilers_and_libraries_2020.3.275/linux/compiler/lib/intel64_lin \
-Wl,-rpath,/opt/intel/compilers_and_libraries_2020.3.275/linux/mkl/lib/intel64_lin \
-Wl,-rpath,/opt/intel/compilers_and_libraries_2020.3.275/linux/tbb/lib/intel64/gcc4.8 \
-Wl,-rpath,/opt/intel/debugger_2020/python/intel64/lib \
-Wl,-rpath,/opt/intel/debugger_2020/libipt/intel64/lib \
-Wl,-rpath,/opt/intel/compilers_and_libraries_2020.3.275/linux/daal/lib/intel64_lin \
./bin/cfp.o


ls -l ./bin/cfp


#make the support hello executable
mkdir -p ./test 
echo "Building main cfp application"
ftn $localArgs -o ./test/hello \
./src/hello.f

ls -l ./test/hello
