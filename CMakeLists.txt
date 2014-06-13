cmake_minimum_required(VERSION 2.8.8)
project(ToyProjects)

set(ToyProject_VERSION_MAJOR 0)
set(ToyProject_VERSION_MINOR 1)

include(ExternalProject)

set(GTEST_DIR gtest-1.6.0)
set(GLEW_DIR glew-1.10.0)
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
find_package(GTest 1.6.0 EXACT)
if( NOT GTest_FOUND ) 
  get_filename_component(GTEST_ABS_DIR ${GTEST_DIR} ABSOLUTE)

  set(GTEST_DOWNLOAD_CMD cmake -DCLONE_URL=git@github.com:hadjian/gtest-1.6.0.git)
  set(GTEST_DOWNLOAD_CMD ${GTEST_DOWNLOAD_CMD} -DCLONE_TAG=projection)
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
else( NOT GTest_FOUND )
  message("Found GTest in the system. Skipping compilation of included source.")
  # We will define all required targets to do nothing
  add_custom_target(gtest-external)
  add_custom_target(gtest-external-download)
  add_custom_target(gtest-external-update)
  add_custom_target(gtest-external-configure)
endif( NOT GTest_FOUND )


find_package(GLEW 1.5)
find_package(GLEW 1.10)
if( NOT GLEW_FOUND )
  get_filename_component(GLEW_ABS_DIR ${GLEW_DIR} ABSOLUTE)

  set(GLEW_DOWNLOAD_CMD cmake -DCLONE_URL=git@github.com:hadjian/glew-1.10.0.git)
  set(GLEW_DOWNLOAD_CMD ${GLEW_DOWNLOAD_CMD} -DCLONE_TAG=projection)
  set(GLEW_DOWNLOAD_CMD ${GLEW_DOWNLOAD_CMD} -DCLONE_DIR=${GLEW_DIR})
  set(GLEW_DOWNLOAD_CMD ${GLEW_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)

  ExternalProject_Add(glew-external
                       PREFIX            cmake/glew-external-prefix
                       DOWNLOAD_COMMAND  ${GLEW_DOWNLOAD_CMD}
                       DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR}
                       UPDATE_COMMAND    git fetch
                       SOURCE_DIR        ${GLEW_DIR}
                       CONFIGURE_COMMAND ${CMAKE_COMMAND} -E echo "No need to configure. Makefile based."  
                       BUILD_COMMAND     make 
                       BUILD_IN_SOURCE   1
                       INSTALL_COMMAND   echo "Not invoking install")
else( NOT GLEW_FOUND )
  message("Found GLEW in the system. Skipping compilation of included source.")
  # We will define all required targets to do nothing
  add_custom_target(glew-external)
  add_custom_target(glew-external-download)
  add_custom_target(glew-external-update)
  add_custom_target(glew-external-configure)
endif( NOT GLEW_FOUND )

#-------------------------------------------------------------------------------
# For the ToyMatrix subproject we want to find our own version of gtest through
# the normal find_package() cmake command, but w/o writing code for this into
# the ToyMatrix' CMakeLists.cmake file, such that it can still be used outside
# this superproject.
# 
# This will do no harm, if a system-wide GTest installation was found.
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
set(TOYMATRIX_DOWNLOAD_CMD ${TOYMATRIX_DOWNLOAD_CMD} -DCLONE_TAG=projection)
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
set(INJECT_GLEW_PATH "${CMAKE_CURRENT_LIST_DIR}/${GLEW_DIR}")
configure_file(cmake/toyrenderer_inject_variables.cmake.in
                 "cmake/toyrenderer_inject_variables.cmake" @ONLY)

#-------------------------------------------------------------------------------
# Custom git clone command. See comment above at the gtest target.
#-------------------------------------------------------------------------------
GET_FILENAME_COMPONENT(TOYRENDERER_ABS_DIR ${TOYRENDERER_DIR} ABSOLUTE)

set(TOYRENDERER_DOWNLOAD_CMD cmake -DCLONE_URL=git@github.com:hadjian/${TOYRENDERER_DIR}.git)
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -DCLONE_TAG=projection)
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -DCLONE_DIR=${TOYRENDERER_DIR})
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)

ExternalProject_Add(toyrenderer-external
                     DEPENDS           toymatrix-external gtest-external glew-external
                     PREFIX            cmake/toyrenderer-external-prefix
                     DOWNLOAD_COMMAND  ${TOYRENDERER_DOWNLOAD_CMD} 
                     DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR}
                     UPDATE_COMMAND    git fetch 
                     SOURCE_DIR        ${TOYRENDERER_DIR}
                     CONFIGURE_COMMAND cmake -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -C${CMAKE_CURRENT_LIST_DIR}/cmake/toyrenderer_inject_variables.cmake ${TOYRENDERER_ABS_DIR} 
                     BINARY_DIR        build/${TOYRENDERER_DIR}-${BUILD_TYPE}
                     INSTALL_COMMAND   echo "Not invoking install")

#--------------------------------------------------------------------------------
# All targets run through all steps when the default target is invoked (e.g. make
# ALL on linux). I don't like that to happen. The default should at max download 
# all subproject, but not build them and print a short manual. 
#--------------------------------------------------------------------------------
set_target_properties(gtest-external toymatrix-external toyrenderer-external
                      PROPERTIES EXCLUDE_FROM_ALL 1)

if ( NOT GTEST_FOUND )
ExternalProject_Add_StepTargets( gtest-external download update configure )
set( DOWNLOAD_TARGETS ${DOWNLOAD_TARGETS} gtest-external-download )
set( UPDATE_TARGETS   ${UPDATE_TARGETS}   gtest-external-update   )
endif ( NOT GTEST_FOUND )

if ( NOT GLEW_FOUND )
ExternalProject_Add_StepTargets(glew-external download update configure)
set( DOWNLOAD_TARGETS ${DOWNLOAD_TARGETS} glew-external-download )
set( UPDATE_TARGETS   ${UPDATE_TARGETS}   glew-external-update   )
endif ( NOT GLEW_FOUND )

ExternalProject_Add_StepTargets(toymatrix-external   download update configure)
ExternalProject_Add_StepTargets(toyrenderer-external download update configure)
set(DOWNLOAD_TARGETS ${DOWNLOAD_TARGETS} toymatrix-external-download )
set(UPDATE_TARGETS   ${UPDATE_TARGETS}   toyrenderer-external-update )
#--------------------------------------------------------------------------------
# The following custom targets lets the developer download or update all projects
# at once for on-the-go development where no online access is available.
#--------------------------------------------------------------------------------
add_custom_target(external-download DEPENDS 
                   ${DOWNLOAD_TARGETS})

add_custom_target(external-update DEPENDS
                   ${UPDATE_TARGETS})

add_custom_target(external-configure ALL DEPENDS
                   toyrenderer-external)

