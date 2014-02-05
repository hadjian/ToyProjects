# - Find a "Google Test" (GTest) library.
# The following variables are set if GTest is found.  If GTest is not
# found, TOYMATRIX_FOUND is set to false.
#
#  TOYMATRIX_FOUND          - Set to true when GTest is found.
#  TOYMATRIX_VERSION        - the gtest version number.
#  TOYMATRIX_INCLUDE_DIRS   - include directories for GTest. 

find_package(TOYMATRIX NO_MODULE NAMES ToyMatrix) 

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(TOYMATRIX REQUIRED_VARS
                                   TOYMATRIX_INCLUDE_DIRS
                                   CONFIG_MODE)
