.TH CFP EXAMPLE
This directory contains an example program and scripts to demonstrate
the use of cfp.

For help on the cfp program itself run man cfp
.SH Overview
This directory contains a simple example of cfp usage.
.SH Files
This directory contains several files to illustrate a practical usage of cfp.

.IP hello.f
A small non-mpi program that does a few math operations and says hello(ish).
.IP buildSample.sh
Builds the sample executable based on a local environment definition file.
.IP runSample.sh
This will launch cfp based on the local "job card" and command files.
.IP launchCfp.pbs
A pbs "job card" to setup the local environment and launch cfp to run the sample jobs.
.IP command_file
Contains a list of commands to run.  In this case it just runs runner.sh multiple times.
.IP runner.sh
Simple wrapper script to launch the commands.  In this case just the local "hello".
.IP README
This file.
.SH BUILDING AND RUNNING
To build and test the sample run the follow scripts in order.
.RS
buildSample.sh - this will build the sample program hello.f.  This is a non-mpi test executable.
.RE
.RS
runSample.sh - this will launch cfp by way of the launchCfp.pbs "job card".
.RE
The output from these commands is self-explanitory.
.SH GENERAL INFORMATION
Generally CFP is intended to run simple, smaller serial jobs and will avoid the overhead of placing many jobs into the batch queue manager.
.SH MORE GENERAL INFORMATION
.PP
cfp takes one argument - the commands file.  In this example it is called command file.  The syntax for this file is simply one command per line.  There is a current limitation of 1024 characters per command and 4096 commands per file.  In this example there is an added layer of a launch script to run the final executable.  Although not strictly needed, this construct makes it easier to manage support or setup tasks for the jobs that are run.  It permits setting up environment variables, preparing input data and managing any instrumentation of the processes.
.PP
The sequence is:
cfp reads "command file" and launches each command in parralel up to the specified number of nodes and cores.  As each command completes the next command in the list is launched.  Only the starting of the commands is managed, and they are done sequentially.  There is no dependency control at all with respect to jobs being run unless the number of cores and nodes are both equal to one in which case they are simply launched serially and cfp doesn't help much except perhaps to check for free memeory prior to launching commands.
.PP
The runner script in this directory is what actually launches the command of interest.  This extra layer is more realistic in the real world for managing data and reporting of the sub commands.
