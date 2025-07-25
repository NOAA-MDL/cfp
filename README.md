# cfp

Command File Processor (cfp) is a MPI Fortran-based command line utility that allows for the execution of shell scripts or executables in parallel.  It is intended to run simple, smaller serial jobs without the overhead of placing many jobs into a batch queue manager.

`cfp` accepts one argument, a command file which contains a list of commands to run, one per line. It uses MPI programming to distribute the jobs across multiple nodes and CPUs in concert with the local job scheduler. Care must be taken in the the definition of the “job card” to manage the number of nodes and/or cpus allocated for the job and the number of nodes/CPUs requested in the local MPI run command. cfp is intended for running a collection of many short jobs and elimintes the overhead of managing each sub-job individually by the job manager. If an error code is returned from one of the sub-tasks, cfp will wait for other active jobs to finish. It will then exit without starting any additional jobs. This behavior can be changed by use of the `CFP_DOALL` environment variable described below.

## Authors

Steven Bongiovanni, Eric Engle, Jim Taft

Code Manager: [Eric Engle](mailto:eric.engle@noaa.gov)

## Disclaimer

The United States Department of Commerce (DOC) GitHub project code is provided
on an 'as is' basis and the user assumes responsibility for its use. DOC has
relinquished control of the information and no longer has responsibility to
protect the integrity, confidentiality, or availability of the information. Any
claims against the Department of Commerce stemming from the use of its GitHub
project will be governed by all applicable Federal law. Any reference to
specific commercial products, processes, or services by service mark,
trademark, manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation or favoring by the Department of Commerce. The
Department of Commerce seal and logo, or the seal and logo of a DOC bureau,
shall not be used in any manner to imply endorsement of any commercial product
or activity by DOC or the United States Government.
