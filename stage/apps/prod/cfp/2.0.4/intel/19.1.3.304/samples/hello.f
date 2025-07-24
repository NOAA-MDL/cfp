      program test
      use IFPORT
c      logical exists
cc-----initialize MPI
c      call mpi_init(ierror)
      parameter( nx=10,ny=10,nz=10 )

c******************************
c*    loop over time          *
c******************************
c$omp parallel do 
      do 400 n=1,10

c-----adection work
      call advect1(xmax,x,nx,ny,nz)
      call advect2(xmax,y,nx,ny,nz)
c      write(*,*) "Iteration:",n
  400 continue
      print *, "Hello from executable.  I'm done."
c      call mpi_finalize(ierror)
      stop
      end
c**********************************************************************
c**********************************************************************
      subroutine advect1(xmax,x,nx,ny,nz)
      real x(nx,ny,nz)
c-----loop over grid
      xmax=0.0
      do n=1,12
      do k=1,nz
      do j=1,ny
      do i=1,nx
      x(i,j,k)=x(i,j,k)+i+j+k
      enddo
      enddo
      enddo
      enddo
      return
      end
c**********************************************************************
c**********************************************************************
      subroutine advect2(xmax,x,nx,ny,nz)
      real x(nx,ny,nz)
c-----loop over grid
      xmax=0.0
      do n=1,12
      do k=1,nz
      do j=1,ny
      do i=1,nx
      x(i,j,k)=x(i,j,k)+i+j+k
      enddo
      enddo
      enddo
      enddo

      return
      end

