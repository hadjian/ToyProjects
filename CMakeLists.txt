cmake_minimum_required(VERSION 2.8.8)
project(ToyProjects)

set(ToyProject_VERSION_MAJOR 0)
set(ToyProject_VERSION_MINOR 1)

include(ExternalProject)

set(GTEST_DIR gtest-1.6.0)
set(TOYMATRIX_DIR ToyMatrix)
set(TOYRENDERER_DIR ToyRenderer)

set(BUILD_TYPE Release CACHE STRING "Set default build type. Modify by 'cmake -DBUILD_TYPE:STRING={Debug|Release}'.")

#-------------------------------------------------------------------------------
# CMake has the habit to brutally delete the external repo from time to time.
# Anticipating tragedy, I use my own function to clone the git repo, which
# checks for existing directories and leaves them untouched.
#
# This problem has been approached recently, but I didn't check out yet if the
# patch already made it into an official release. For reference: 
#
# http://public.kitware.com/pipermail/cmake-developers/2013-September/008252.html
#
# TODO: Switch to the recommended way to do this, once it is widely available.
#-------------------------------------------------------------------------------
get_filename_component(GTEST_ABS_DIR ${GTEST_DIR} ABSOLUTE)

set(GTEST_DOWNLOAD_CMD cmake -DCLONE_URL=git@github.com:hadjian/gtest-1.6.0.git)
set(GTEST_DOWNLOAD_CMD ${GTEST_DOWNLOAD_CMD} -DCLONE_TAG=master)
set(GTEST_DOWNLOAD_CMD ${GTEST_DOWNLOAD_CMD} -DCLONE_DIR=${GTEST_DIR})
set(GTEST_DOWNLOAD_CMD ${GTEST_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)

ExternalProject_Add(gtest-external
                     PREFIX            cmake/gtest-external-prefix
                     DOWNLOAD_COMMAND  ${GTEST_DOWNLOAD_CMD} 
                     DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR} 
                     UPDATE_COMMAND    git fetch 
                     SOURCE_DIR        ${GTEST_DIR}
                     CONFIGURE_COMMAND cmake -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} ${GTEST_ABS_DIR} 
                     BINARY_DIR        build/${GTEST_DIR}-${BUILD_TYPE}
                     INSTALL_COMMAND   echo "Not invoking install")

#-------------------------------------------------------------------------------
# For the ToyMatrix subproject we want to find our own version of gtest through
# the normal find_package() cmake command, but w/o writing code for this into
# the ToyMatrix' CMakeLists.cmake file, such that it can still be used outside
# this superproject.
# 
# To achieve this, we inject cached variables into the ToyMatrix subproject.  
#-------------------------------------------------------------------------------
set(INJECT_FIND_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(INJECT_GTEST_PATH "${CMAKE_CURRENT_LIST_DIR}/build/${GTEST_DIR}-${BUILD_TYPE}")
configure_file(cmake/toymatrix_inject_variables.cmake.in
                 "cmake/toymatrix_inject_variables.cmake" @ONLY)

#-------------------------------------------------------------------------------
# Custom git clone command. See comment above at the gtest target.
#-------------------------------------------------------------------------------
get_filename_component(TOYMATRIX_ABS_DIR ${TOYMATRIX_DIR} ABSOLUTE)

set(TOYMATRIX_DOWNLOAD_CMD cmake -DCLONE_URL=git@github.com:hadjian/${TOYMATRIX_DIR}.git)
set(TOYMATRIX_DOWNLOAD_CMD ${TOYMATRIX_DOWNLOAD_CMD} -DCLONE_TAG=master)
set(TOYMATRIX_DOWNLOAD_CMD ${TOYMATRIX_DOWNLOAD_CMD} -DCLONE_DIR=${TOYMATRIX_DIR})
set(TOYMATRIX_DOWNLOAD_CMD ${TOYMATRIX_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)

ExternalProject_Add(toymatrix-external
                     DEPENDS           gtest-external
                     PREFIX            cmake/toymatrix-external-prefix
                     DOWNLOAD_COMMAND  ${TOYMATRIX_DOWNLOAD_CMD} 
                     DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR} 
                     UPDATE_COMMAND    git fetch 
                     SOURCE_DIR        ${TOYMATRIX_DIR}
                     CONFIGURE_COMMAND cmake -DArithmeticExceptions=ON -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -C${CMAKE_CURRENT_LIST_DIR}/cmake/toymatrix_inject_variables.cmake ${TOYMATRIX_ABS_DIR} 
                     BINARY_DIR        build/${TOYMATRIX_DIR}-${BUILD_TYPE}
                     INSTALL_COMMAND   echo "Not invoking install")

#-------------------------------------------------------------------------------
# The ToyRenderer in this superproject shall find the ToyMatrix project
# in the same directory. Injecting the appropriate cached variables. 
#-------------------------------------------------------------------------------
set(INJECT_FIND_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(INJECT_TOYMATRIX_PATH "${CMAKE_CURRENT_LIST_DIR}/build/${TOYMATRIX_DIR}-${BUILD_TYPE}")
configure_file(cmake/toyrenderer_inject_variables.cmake.in
                 "cmake/toyrenderer_inject_variables.cmake" @ONLY)

#-------------------------------------------------------------------------------
# Custom git clone command. See comment above at the gtest target.
#-------------------------------------------------------------------------------
GET_FILENAME_COMPONENT(TOYRENDERER_ABS_DIR ${TOYRENDERER_DIR} ABSOLUTE)

set(TOYRENDERER_DOWNLOAD_CMD cmake -DCLONE_URL=git@github.com:hadjian/${TOYRENDERER_DIR}.git)
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -DCLONE_TAG=master)
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -DCLONE_DIR=${TOYRENDERER_DIR})
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)

ExternalProject_Add(toyrenderer-external
                     DEPENDS           toymatrix-external
                     PREFIX            cmake/toyrenderer-external-prefix
                     DOWNLOAD_COMMAND  ${TOYRENDERER_DOWNLOAD_CMD} 
                     DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR}
                     UPDATE_COMMAND    git fetch 
                     SOURCE_DIR        ${TOYRENDERER_DIR}
                     CONFIGURE_COMMAND cmake -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -C${CMAKE_CURRENT_LIST_DIR}/cmake/toyrenderer_inject_variables.cmake ${TOYRENDERER_ABS_DIR} 
                     BINARY_DIR        build/${TOYRENDERER_DIR}-${BUILD_TYPE}
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

