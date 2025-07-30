program cfp
! ----------------------------------------------------------------------------------------
! Program Name: cfp
!
! Authors: Steven Bongiovanni
!          Eric Engle
!          Jim Taft
!
! Purpose:
!
! History:
!
! Usage:
!
! Parameters:
!
! ----------------------------------------------------------------------------------------
use iso_c_binding
use mpi
implicit none

! ----------------------------------------------------------------------------------------
! Define interfaces to C functions available via the system's libc.
! ----------------------------------------------------------------------------------------
interface
  logical(kind=c_bool) function c_access(path, mode) bind(C, name="access")
    import :: c_bool, c_char, c_int
    character(c_char), dimension(*), intent(in) :: path
    integer(c_int), value :: mode
  end function c_access

  integer(kind=c_int) function c_getpid() bind(C, name="getpid")
    import :: c_int
  end function c_getpid
end interface

integer, external :: get_free_memory

integer(kind=4), parameter :: CFP_MAX_FILENAME=1024
integer(kind=4), parameter :: CFP_MAX_COMMANDS=4096
integer(kind=4), parameter :: CFP_STDOUT=6

character(len=6) :: nranka
character(len=8) :: kdate
character(len=10) :: apid
character(len=10) :: ktime
character(len=CFP_MAX_FILENAME) :: dirname
character(len=CFP_MAX_FILENAME) :: filname
character(len=CFP_MAX_FILENAME) :: comand
character(len=CFP_MAX_FILENAME) :: commandfile
character(len=CFP_MAX_FILENAME) :: cenvvar
!character(len=CFP_MAX_FILENAME) :: fvalue
character(len=MPI_MAX_PROCESSOR_NAME) :: myhost

integer(kind=4) :: n,m
integer(kind=4) :: ierror,jerror,kerror
integer(kind=4) :: ios,ivarstat
integer(kind=4) :: idoio,imdone
integer(kind=4) :: ipid
integer(kind=4) :: idoall,idelay
integer(kind=4) :: isum,itotal
integer(kind=4) :: lennam
integer(kind=4) :: minmem,memnow
integer(kind=4) :: ncomm,nrank,nproc
integer(kind=4) :: ncores
integer(kind=4) :: nread

logical :: exists

real(kind=8) :: t1,t2,tottim

! ----------------------------------------------------------------------------------------
! Initialization
! ----------------------------------------------------------------------------------------
ios=0
ierror=0
imdone=0
jerror=0
kerror=0
ncores=1
tottim=0.0

! ----------------------------------------------------------------------------------------
! Initialize MPI
! ----------------------------------------------------------------------------------------
call mpi_init(ierror)
call mpi_comm_rank(MPI_COMM_WORLD,nrank,ierror)
call mpi_comm_size(MPI_COMM_WORLD,nproc,ierror)

call execute_command_line("rm -rf .o",exitstat=ierror)
if(ierror.ne.0) stop "rm-f.o"

! ----------------------------------------------------------------------------------------
! MPI Barrier sync
! ----------------------------------------------------------------------------------------
call mpi_barrier(MPI_COMM_WORLD,ierror)

! ----------------------------------------------------------------------------------------
! Get CFP I/O suppression flag.
! ----------------------------------------------------------------------------------------
idoio=0
call get_environment_variable("CFP_VERBOSE",cenvvar,status=ivarstat)
if(ivarstat.eq.0)then
   read(cenvvar,*) idoio
endif

! ----------------------------------------------------------------------------------------
! Create subdirectory in cwd and name it CFP.<process_id>
! ----------------------------------------------------------------------------------------
if(idoio.ne.0)then
   ipid=c_getpid()
   call mpi_bcast(ipid,1,mpi_integer,0,MPI_COMM_WORLD,ierror)
   write(apid,"(i10)") ipid
   dirname="CFP." // trim(adjustl(apid))
   write(comand,831) trim(dirname)
   call execute_command_line(comand,exitstat=ierror)
endif

! ----------------------------------------------------------------------------------------
! Open the CFP run log files and tag with MPI rank of the process.
! ----------------------------------------------------------------------------------------
if(idoio.ne.0)then
   write(nranka,"(i4.4)") nrank
   filname=trim(dirname) // "/cfprun.log." // nranka
   open(8000+nrank,file=trim(filname),status="unknown",form="formatted")
endif

! ----------------------------------------------------------------------------------------
! Get number of CPUs
! ----------------------------------------------------------------------------------------
call get_environment_variable("NCPUS",cenvvar,status=ivarstat)
if(ivarstat.eq.0)then
   read(cenvvar,*) ncores
endif

! ----------------------------------------------------------------------------------------
! Get user requested termination option
! ----------------------------------------------------------------------------------------
idoall=0
call get_environment_variable("CFP_DOALL",cenvvar,status=ivarstat)
if(ivarstat.eq.0)then
   read(cenvvar,*) idoall
endif

! ----------------------------------------------------------------------------------------
! Get user requested launch delay (seconds)
! ----------------------------------------------------------------------------------------
idelay=0
call get_environment_variable("CFP_DELAY",cenvvar,status=ivarstat)
if(ivarstat.eq.0)then
   read(cenvvar,*) idelay
endif

! ----------------------------------------------------------------------------------------
! Get user requested minimum free memory before task launch (gbytes)
! ----------------------------------------------------------------------------------------
minmem=0
call get_environment_variable("CFP_MINMEM",cenvvar,status=ivarstat)
if(ivarstat.eq.0)then
   read(cenvvar,*) minmem
endif

! ----------------------------------------------------------------------------------------
! Get current hostname
! ----------------------------------------------------------------------------------------
call MPI_Get_processor_name(myhost,lennam,ierror)

! ----------------------------------------------------------------------------------------
! Get name of command file and open it
! ----------------------------------------------------------------------------------------
call get_command_argument(1,commandfile,status=ivarstat)
if(ivarstat.eq.0)then
   open(12345,file=trim(commandfile),form="formatted",status="old",iostat=ios)
endif
! Check ivarstat or ios not equal to zero
if(ivarstat.ne.0.or.ios.ne.0)then
   write(CFP_STDOUT,fmt="(A,A)")"Error: Trouble opening cfp command file ",trim(commandfile)
   call exit(1)
endif

! ----------------------------------------------------------------------------------------
! Sleep to stagger intial process spinups by idelay seconds each
! ----------------------------------------------------------------------------------------
if(idelay.gt.0) call sleep(mod(nrank,ncores)*idelay)

! ----------------------------------------------------------------------------------------
! Print startup headings in log files
! ----------------------------------------------------------------------------------------
if(idoio.ne.0) then
write(8000+nrank,809)
write(8000+nrank,809)
write(8000+nrank,800) nrank,trim(myhost)
call flush(8000+nrank)
endif

! ----------------------------------------------------------------------------------------
! Init some variables
! ----------------------------------------------------------------------------------------
ncomm=0
itotal=0
nread=nrank+1

! ----------------------------------------------------------------------------------------
! Loop over commands in command file - assume no more than CFP_MAX_COMMANDS commands
! per process
! ----------------------------------------------------------------------------------------
do 400 n=1,CFP_MAX_COMMANDS

   do m=1,nread
      read(12345,"(a)",end=500) cenvvar
      ncomm=ncomm+1
   enddo

   nread=nproc

   ! Check on available memory - wait if needed
   if(idoio.ne.0) write(8000+nrank,809)
   t1=mpi_wtime()
   t2=mpi_wtime()
   isum=0
   100 isum=isum+1
   if(isum.gt.400) go to 400

   memnow=get_free_memory()
   if(memnow.lt.minmem) then
      call sleep(4)
      call date_and_time(kdate,ktime)
      t2=mpi_wtime()
      if(idoio.ne.0) write(8000+nrank,805) nrank,ncomm,kdate,ktime,t2-t1,memnow
      go to 100
   endif

   ! Not stalled - execute the current command - wait until done
   call date_and_time(kdate,ktime)
   memnow=get_free_memory()
   if(idoio.ne.0) write(8000+nrank,804) nrank,ncomm,kdate,ktime,t2-t1,memnow
   jerror=0

   ! Execute command
   t1=mpi_wtime()
   call execute_command_line(trim(cenvvar),exitstat=jerror)
   t2=mpi_wtime()

   ! Look for errors here
   if(jerror.ne.0) then
      write(*,820) nrank,ncomm,trim(cenvvar)
      call execute_command_line("mkdir -p .o",exitstat=ierror)
   endif

   ! Done. Print summary stats.
   call date_and_time(kdate,ktime)
   memnow=get_free_memory()
   if(idoio.ne.0) write(8000+nrank,806) nrank,ncomm,kdate,ktime,t2-t1,memnow,jerror
   tottim=tottim+t2-t1
   itotal=itotal+jerror

   ! Break processing if any current processes failed.
   if(idoall.eq.0) then
      !inquire(DIRECTORY=".o",EXIST=exists)
      exists=c_access("./.o"//c_null_char,0)
      if(exists) go to 500
   endif

400 continue

! ----------------------------------------------------------------------------------------
! Wait until all commands are done
! ----------------------------------------------------------------------------------------
500 call mpi_barrier(MPI_COMM_WORLD,ierror)

! ----------------------------------------------------------------------------------------
! Get global cfp error status by summing errors on all mpi processes
! ----------------------------------------------------------------------------------------
kerror=0
call mpi_allreduce(itotal,kerror,1,mpi_int,mpi_sum,MPI_COMM_WORLD,ierror);
if(kerror.ne.0) kerror=1

! ----------------------------------------------------------------------------------------
! Print final cfp task summaries
! ----------------------------------------------------------------------------------------
if(itotal.gt.1) itotal=1
write(*,811) nrank,tottim,itotal
if(idoio.ne.0) write(8000+nrank,810) nrank,tottim
if(idoio.ne.0) write(8000+nrank,809)

! ----------------------------------------------------------------------------------------
! Done. Clean up MPI.
! ----------------------------------------------------------------------------------------
call mpi_finalize(ierror)

! ----------------------------------------------------------------------------------------
! Set exit status
! ----------------------------------------------------------------------------------------
if(kerror.ne.0) call exit(1)
stop

! ----------------------------------------------------------------------------------------
! I/O Formats
! ----------------------------------------------------------------------------------------
800 format("************************************************************************",/,&
           "RANK",i4,"   HOSTNAME : ",a,"   CFP-2 PROCESSING STARTED   *            ",/,&
           "************************************************************************")

804 format("RANK",i4,"  Started  command:",i5,5x,"Date: ",a8,5x,"Time: ",a6,&
           5x,"Wait time:",f6.1," sec",5x,"Free memory  :",i12)

805 format("RANK",i4,"  Stalled  command:",i5,5x,"Date: ",a8,5x,"Time: ",a6,&
           5x,"Wait time:",f6.1," sec",5x,"Free memory  :",i12)

806 format("RANK",i4,"  Finished command:",i5,5x,"Date: ",a8,5x,"Time: ",a6,&
           5x,"Run  time:",f6.1," sec",5x,"Free memory  :",i12,5x,"Return Status: ",z8.8," hex")

809 format(" ")

810 format(73x,20("-"),/,"RANK",i4,"  TOTAl CFP-2 RUN TIME" ,43x,"Tot  time:",f6.1," sec")

811 format("CFP RANK",i4,"    TOTAL RANK RUN TIME:",f6.1," sec    Return status: ",z8.8," hex")

820 format("CFP RANK",i4,"    CFP TASK NUMBER: ",i4.4," FAILED.     USER COMMAND: ",a)

831 format("mkdir -p ",a)

end program cfp

! ----------------------------------------------------------------------------------------
! ----------------------------------------------------------------------------------------
integer(kind=4) function get_free_memory()
   implicit none
   character*32 i1
   integer(kind=4) :: i2
   integer(kind=4) :: ios
   ios=0
   get_free_memory=0
   open(2345,file="/proc/meminfo",status="old",iostat=ios)
   if(ios.eq.0)then
      read(2345,*) i1,i2
      read(2345,*) i1,i2
      close(2345)
      get_free_memory=i2/(1024*1024)
   endif
   return
end function get_free_memory

