      program cfp
c****************************************************************************
c*                                                                          *
c*                                                                          *
c*                                                                          *
c****************************************************************************
      use IFPORT

      include "mpif.h"

      character*1024 comand

      character*1024 evalue
      character*1024 fvalue

      character*08 kdate
      character*10 ktime
      character*(MPI_MAX_PROCESSOR_NAME) myhost
      character*06 nranka

      character*256 dirname
      character*256 filname

      character*10 apid

      logical exists

      real*8 t1,t2,tottim

c*****************************
c*    Initialization         *
c*****************************
c-----initialize MPI
      call mpi_init(ierror)
      call mpi_comm_rank(mpi_comm_world,nrank,ierror)
      call mpi_comm_size(mpi_comm_world,nproc,ierror)

      tottim=0
      imdone=0

      ierror=system("rm -rf .o")
      if(ierror.ne.0) stop "rm-f.o"

c-----barrier synch
      call mpi_barrier(mpi_comm_world,ierror)

c-----get I/O suppression flag
      idoio=0
      call getenv("CFP_VERBOSE",evalue)
      if(evalue.ne."") read(evalue,*) idoio

c-----create sub-directory in cwd - name it CFP.<processid>
      if(idoio.ne.0) then
      ipid=getpid()
      call mpi_bcast(ipid,1,mpi_integer,0,mpi_comm_world,ierror)
      write(apid,'(i10)') ipid
      dirname='CFP.' // trim(adjustl(apid))
      write(comand,831) trim(dirname)
      ierror=system(comand)
      endif

c-----open the CFP run log files - tag with MPI rank of the process
      if(idoio.ne.0) then
      write(nranka,'(i4.4)') nrank
      filname=trim(dirname) // '/cfprun.log.' // nranka
      open(8000+nrank,file=trim(filname),status='unknown',form='formatted')
      endif

c-----get number of cpus
      call getenv("NCPUS",fvalue)
      read(fvalue,*) itile

c-----set core count per node
      ncores=itile

c-----get user requested termination option
      idoall=0
      call getenv("CFP_DOALL",fvalue)
      if(fvalue.ne."") read(fvalue,*) idoall

c-----get user requested launch delay (seconds)
      idelay=0
      call getenv("CFP_DELAY",fvalue)
      if(fvalue.ne."") read(fvalue,*) idelay

c-----get user requested minimum free memory before task launch (gbytes)
      minmem=0
      call getenv("CFP_MINMEM",fvalue)
      if(fvalue.ne."") read(fvalue,*) minmem

c-----get current  hostname 
      call MPI_Get_processor_name(myhost,lennam,ierror)

c-----get name of command file and open it
      call getarg(1,evalue)
      open(12345,file=trim(evalue),status='old')

c-----sleep to stagger intial process spinups by idelay seconds each
      if(idelay.gt.0) call sleep(mod(nrank,ncores)*idelay)

c-----print startup headings in log files
      if(idoio.ne.0) then
      write(8000+nrank,809)
      write(8000+nrank,809)
      write(8000+nrank,800) nrank,trim(myhost)
      call flush(8000+nrank)
      endif

c-----init some variables
      ncomm=0
      itotal=0
      nread=nrank+1

c*******************************
c*    BEGIN THE WORK           *
c*******************************
c-----loop over commands in command file - assume no more than 4096 commands per process
      do 400 n=1,4096
      do m=1,nread
      read(12345,'(a)',end=500) evalue
      ncomm=ncomm+1
      enddo
      nread=nproc

c-----check on available memory - wait if needed
      if(idoio.ne.0) write(8000+nrank,809)
      t1=mpi_wtime()
      t2=mpi_wtime()
      isum=0
 100  isum=isum+1
      if(isum.gt.400) go to 400
      memnow=memfree()
      if(memnow.lt.minmem) then
      call sleep(4)
      call date_and_time(kdate,ktime)
      t2=mpi_wtime()
      if(idoio.ne.0) write(8000+nrank,805) nrank,ncomm,kdate,ktime,t2-t1,memnow
      go to 100
      endif

c-----not stalled - execute the current command - wait until done
      call date_and_time(kdate,ktime)
      memnow=memfree()
      if(idoio.ne.0) write(8000+nrank,804) nrank,ncomm,kdate,ktime,t2-t1,memnow
      jerror=0
      t1=mpi_wtime()
      jerror=system(trim(evalue))
      t2=mpi_wtime()
      
c-----look for errors here
      if(jerror.ne.0) then
                      write(*,820) nrank,ncomm,trim(evalue)
                      ierror=system("mkdir -p .o")
                      endif

c-----done - print summary stats
      call date_and_time(kdate,ktime)
      memnow=memfree()
      if(idoio.ne.0) write(8000+nrank,806) nrank,ncomm,kdate,ktime,t2-t1,memnow,jerror
      tottim=tottim+t2-t1
      itotal=itotal+jerror

c-----break processing if any current processes failed
      if(idoall.eq.0) then 
      inquire(DIRECTORY=".o",EXIST=exists)
      if(exists) go to 500
      endif
 400  continue

c-----wait until all commands are done 
 500  call mpi_barrier(mpi_comm_world,ierror)

c-----get global cfp error status by summing errors on all mpi processes
      kerror=0
      call mpi_allreduce(itotal,kerror,1,mpi_int,mpi_sum,mpi_comm_world,ierror);
      if(kerror.ne.0) kerror=1

c-----print final cfp task summaries 
      if(itotal.gt.1) itotal=1
      write(*,811) nrank,tottim,itotal
      if(idoio.ne.0) write(8000+nrank,810) nrank,tottim
      if(idoio.ne.0) write(8000+nrank,809)

c-----done - clean up mpi
      call mpi_finalize(ierror)

c-----set exit status
      if(kerror.ne.0) call exit(1)
      stop

c-----i/o formats
 800  format("************************************************************************",/,
     .       "RANK",i4,"   HOSTNAME : ",a,"   CFP-2 PROCESSING STARTED   *            ",/,
     .       "************************************************************************")
 804  format("RANK",i4,"  Started  command:",i5,5x,"Date: ",a8,5x,"Time: ",a6,
     .       5x,"Wait time:",f6.1," sec",5x,"Free memory  :",i12)
 805  format("RANK",i4,"  Stalled  command:",i5,5x,"Date: ",a8,5x,"Time: ",a6, 
     .       5x,"Wait time:",f6.1," sec",5x,"Free memory  :",i12)
 806  format("RANK",i4,"  Finished command:",i5,5x,"Date: ",a8,5x,"Time: ",a6,
     .       5x,"Run  time:",f6.1," sec",5x,"Free memory  :",i12,5x,"Return Status: ",z8.8," hex")
 809  format(" ")
 810  format(73x,20("-"),/,"RANK",i4,"  TOTAl CFP-2 RUN TIME" ,43x,"Tot  time:",f6.1," sec")
 811  format("CFP RANK",i4,"    TOTAL RANK RUN TIME:",f6.1," sec    Return status: ",z8.8," hex")
 820  format("CFP RANK",i4,"    CFP TASK NUMBER: ",i4.4," FAILED.     USER COMMAND: ",a)
 831  format('mkdir -p ',a)
      end
      function memfree
c****************************************************************************
c*                                                                          *
c*                                                                          *
c*                                                                          *
c****************************************************************************
      character*32 i1
      open(2345,file='/proc/meminfo',status='old')
      read(2345,*) i1,i2
      read(2345,*) i1,i2
      close(2345)
      memfree=i2/(1024*1024)
      return
      end

