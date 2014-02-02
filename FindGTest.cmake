# - Find a "Google Test" (GTest) library.
# The following variables are set if GTest is found.  If GTest is not
# found, GTEST_FOUND is set to false.
#
#  GTEST_FOUND          - Set to true when GTest is found.
#  GTEST_VERSION        - the gtest version number.
#  GTEST_INCLUDE_DIRS   - include directories for GTest. 
#  GTEST_LIBRARIES      - variable holds the gtest target library (w/o gtest_main). 
#  GTEST_MAIN_LIBRARIES - variable holds the gtest_main library (with gtest already linked).
#  GTEST_CXX_FLAGS      - supply this to your own translation units to match the libs.

# Caution: this drove me crazy. Even if the package name is in ExactCase, the
# <pkg>Config.cmake file searched for has the pkg part in upper case. This has
# something to do with packages always being all caps per convention (although
# the FindXXX.cmake file is also found if written in ExactCase). I bystep
# this by using the NAMES option.
find_package(GTEST 1.6.0 EXACT REQUIRED NO_MODULE NAMES GTest PATHS "${PROJECT_BINARY_DIR}/gtest-1.6.0")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(GTEST REQUIRED_VARS 
                                   GTEST_INCLUDE_DIRS 
                                   GTEST_LIBRARIES
                                   GTEST_MAIN_LIBRARIES
                                   GTEST_CXX_FLAGS
                                   CONFIG_MODE)
