# ----------------------------------------------------------------------------------------
# Copy required test scripts to build directory
# ----------------------------------------------------------------------------------------
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/main_cfp_test_simple.sh
               ${CMAKE_CURRENT_BINARY_DIR}/main_cfp_test_simple.sh COPYONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/hello.sh
               ${CMAKE_CURRENT_BINARY_DIR}/hello.sh COPYONLY)

# ----------------------------------------------------------------------------------------
# Make sure the test script is executable (for ctest, this is best effort, but may help)
# ----------------------------------------------------------------------------------------
file(
  CHMOD ${CMAKE_CURRENT_BINARY_DIR}/main_cfp_test_simple.sh
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)
file(
  CHMOD ${CMAKE_CURRENT_BINARY_DIR}/hello.sh
  PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE WORLD_READ WORLD_EXECUTE
)

# ----------------------------------------------------------------------------------------
# Register the integration test with CTest
# ----------------------------------------------------------------------------------------
enable_testing()
add_test(
  NAME cfp_test_simple
  COMMAND ${CMAKE_CURRENT_BINARY_DIR}/main_cfp_test_simple.sh
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

message(STATUS "Registered CFP tests with CTest")

