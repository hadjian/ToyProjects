cmake_minimum_required(VERSION 2.8.8)
project(ToyProjects)

set (ToyProject_VERSION_MAJOR 0)
set (ToyProject_VERSION_MINOR 1)

include(ExternalProject)

set(gtest_dir gtest-1.6.0)
set(toymatrix_dir ToyMatrix)
set(toyrenderer_dir ToyRenderer)

ExternalProject_Add(gtest-external
                     GIT_REPOSITORY    https://github.com/hadjian/${gtest_dir}.git
                     GIT_TAG           master
                     DOWNLOAD_DIR      ${gtest_dir}
                     SOURCE_DIR        ${gtest_dir}
                     CONFIGURE_COMMAND cmake .
                     BINARY_DIR        ${gtest_dir}
                     INSTALL_COMMAND   echo "Not invoking install")


# For the ToyMatrix subproject we want to find our own version of gtest through
# the normal find_package() cmake command, but w/o writing code for this into
# the ToyMatrix' CMakeLists.cmake file, such that it can still be used outside
# this superproject.
# 
# To achieve this, we inject cached variables into the ToyMatrix subproject.  
set(INJECT_FIND_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(INJECT_GTEST_PATH "${CMAKE_CURRENT_LIST_DIR}/${gtest_dir}")
configure_file(cmake/toymatrix_inject_variables.cmake.in
                 "cmake/toymatrix_inject_variables.cmake" @ONLY)

ExternalProject_Add(toymatrix-external
                     DEPENDS           gtest-external
                     GIT_REPOSITORY    https://github.com/hadjian/${toymatrix_dir}.git
                     GIT_TAG           master
                     DOWNLOAD_DIR      ${toymatrix_dir}
                     SOURCE_DIR        ${toymatrix_dir}
                     CONFIGURE_COMMAND cmake -C${CMAKE_CURRENT_LIST_DIR}/cmake/toymatrix_inject_variables.cmake  .
                     BINARY_DIR        ${toymatrix_dir}
                     INSTALL_COMMAND   echo "Not invoking install")


# The ToyRenderer in this superproject shall find the ToyMatrix project
# in the same directory. Injecting the appropriate cached variables. 
set(INJECT_FIND_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(INJECT_TOYMATRIX_PATH "${CMAKE_CURRENT_LIST_DIR}/${toymatrix_dir}")
configure_file(cmake/toyrenderer_inject_variables.cmake.in
                 "cmake/toyrenderer_inject_variables.cmake" @ONLY)

ExternalProject_Add(toyrenderer-external
                     DEPENDS           toymatrix-external
                     GIT_REPOSITORY    https://github.com/hadjian/${toyrenderer_dir}.git
                     GIT_TAG           master
                     DOWNLOAD_DIR      ${toyrenderer_dir}
                     SOURCE_DIR        ${toyrenderer_dir}
                     CONFIGURE_COMMAND cmake -C${CMAKE_CURRENT_LIST_DIR}/cmake/toyrenderer_inject_variables.cmake  .
                     BINARY_DIR        ${toyrenderer_dir}
                     INSTALL_COMMAND   echo "Not invoking install")

set_target_properties(gtest-external toymatrix-external toyrenderer-external
                      PROPERTIES EXCLUDE_FROM_ALL 1)

ExternalProject_Add_StepTargets(gtest-external download update configure)
ExternalProject_Add_StepTargets(toymatrix-external download update configure)
ExternalProject_Add_StepTargets(toyrenderer-external download update configure)

add_custom_target(external-download DEPENDS 
                   gtest-external-download
                   toymatrix-external-download
                   toyrenderer-external-download)

add_custom_target(external-update DEPENDS
                   gtest-external-update
                   toymatrix-external-update
                   toyrenderer-external-update)

add_custom_target(external-configure ALL DEPENDS
                   toymatrix-external-configure)

