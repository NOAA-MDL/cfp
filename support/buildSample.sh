#!/bin/bash 
module purge 2>&1 >/dev/null
module load cray-libsci
module load cray-mpich
module load craype
module load craype-x86-rome
module load libfabric
module load craype-network-ofi
module load intel
module load cpe-intel
module load cray-pals

ftn -dynamic -132 -qopenmp -o ./hello ./hello.f
