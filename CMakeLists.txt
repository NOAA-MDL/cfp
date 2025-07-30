# ----------------------------------------------------------------------------------------
# This is the main CMake file for cfp (command file processor)
#
# Eric Engle
# ----------------------------------------------------------------------------------------
cmake_minimum_required(VERSION 3.15)
file(STRINGS "VERSION" pVersion)
project(cfp VERSION ${pVersion} LANGUAGES Fortran)
include(GNUInstallDirs)

# ----------------------------------------------------------------------------------------
# Get build date (format: YYYY-MM-DD)
# ----------------------------------------------------------------------------------------
string(TIMESTAMP CFP_BUILD_DATE "%Y-%m-%d")

# ----------------------------------------------------------------------------------------
# Find MPI Fortran and OpenMP
# ----------------------------------------------------------------------------------------
find_package(MPI REQUIRED Fortran)
find_package(OpenMP REQUIRED Fortran)

# ----------------------------------------------------------------------------------------
# Attempt to detect the MPI vendor by running mpirun --version
# ----------------------------------------------------------------------------------------
find_program(MPIRUN_EXECUTABLE mpirun)
if(NOT MPIRUN_EXECUTABLE)
    message(FATAL_ERROR "mpirun not found!")
endif()

execute_process(
    COMMAND ${MPIRUN_EXECUTABLE} --version
    OUTPUT_VARIABLE mpirun_version
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(MPI_VENDOR "Unknown")
if(mpirun_version MATCHES "Open MPI")
    set(MPI_VENDOR "OpenMPI")
elseif(mpirun_version MATCHES "Intel")
    set(MPI_VENDOR "IntelMPI")
elseif(mpirun_version MATCHES "HYDRA")
    set(MPI_VENDOR "MPICH")
elseif(mpirun_version MATCHES "MVAPICH")
    set(MPI_VENDOR "MVAPICH")
endif()

file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/cfp_mpi_vendor.txt" "${MPI_VENDOR}\n")

# ----------------------------------------------------------------------------------------
# Set Fortran flags (optional)
# ----------------------------------------------------------------------------------------
if(CMAKE_Fortran_COMPILER_ID MATCHES "^(Intel|IntelLLVM)$")
elseif(CMAKE_Fortran_COMPILER_ID MATCHES "^(GNU)$")
  set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -O2 -Wall")
else()
  message(FATAL_ERROR "Unsupported Fortran compiler '${CMAKE_Fortran_COMPILER_ID}'")
endif()

# ----------------------------------------------------------------------------------------
# Add the executable (source is in src/)
# ----------------------------------------------------------------------------------------
add_executable(cfp src/cfp.f90)

# ----------------------------------------------------------------------------------------
# Link MPI Fortran and OpenMP
# ----------------------------------------------------------------------------------------
target_link_libraries(cfp PRIVATE MPI::MPI_Fortran OpenMP::OpenMP_Fortran)

# ----------------------------------------------------------------------------------------
# Configure the manpage from template
# ----------------------------------------------------------------------------------------
configure_file(
  ${CMAKE_SOURCE_DIR}/man/man1/cfp.1.in
  ${CMAKE_BINARY_DIR}/cfp.1
  @ONLY
)

# ----------------------------------------------------------------------------------------
# Install the executable and generated manpage
# ----------------------------------------------------------------------------------------
install(TARGETS cfp DESTINATION bin)
install(FILES ${CMAKE_BINARY_DIR}/cfp.1 DESTINATION share/man/man1)


# ----------------------------------------------------------------------------------------
# Print summary
# ----------------------------------------------------------------------------------------
message(STATUS "Fortran compiler: ${CMAKE_Fortran_COMPILER}")
message(STATUS "MPI Fortran found: ${MPI_Fortran_FOUND}")
message(STATUS "MPI venddor: ${MPI_VENDOR}")
message(STATUS "OpenMP Fortran found: ${OpenMP_Fortran_FOUND}")
message(STATUS "cfp version: ${pVersion}")
message(STATUS "Build date: ${CFP_BUILD_DATE}")

# ----------------------------------------------------------------------------------------
# Testing
# ----------------------------------------------------------------------------------------
include(CTest)
add_subdirectory(tests)
