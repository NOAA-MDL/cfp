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
# Set Fortran flags (optional)
# ---------------------------------------------------------------------------------------- 
set(CMAKE_Fortran_FLAGS "${CMAKE_Fortran_FLAGS} -O2 -Wall")

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
message(STATUS "OpenMP Fortran found: ${OpenMP_Fortran_FOUND}")
message(STATUS "cfp version: ${pVersion}")
message(STATUS "Build date: ${CFP_BUILD_DATE}")
