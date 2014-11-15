cmake_minimum_required(VERSION 2.8.7)
project(ToyProjects)

set(ToyProject_VERSION_MAJOR 0)
set(ToyProject_VERSION_MINOR 1)

include(ExternalProject)

set(BUILD_TYPE Release CACHE STRING "Set default build type. Modify by 'cmake -DBUILD_TYPE:STRING={Debug|Release}'.")


#-------------------------------------------------------------------------------
# Configure the names of the subprojects managed in this superproject as well
# as the directories for out-of-source-builds.
#-------------------------------------------------------------------------------
set(GTEST_DIR gtest-1.6.0)
set(GTEST_SRC_DIR ${CMAKE_CURRENT_LIST_DIR}/${GTEST_DIR})
set(GTEST_BIN_DIR ${CMAKE_CURRENT_LIST_DIR}/build/${GTEST_DIR}-${BUILD_TYPE})

set(GLEW_DIR glew-1.10.0)
set(GLEW_BIN_DIR ${GLEW_DIR}-${BUILD_TYPE})
set(GLEW_SRC_PATH ${CMAKE_CURRENT_LIST_DIR}/${GLEW_DIR})
set(GLEW_BIN_PATH ${CMAKE_CURRENT_LIST_DIR}/build/${GLEW_DIR}-${BUILD_TYPE})

set(TOYMATRIX_DIR ToyMatrix)
set(TOYMATRIX_SRC_DIR ${CMAKE_CURRENT_LIST_DIR}/${TOYMATRIX_DIR})
set(TOYMATRIX_BIN_DIR ${CMAKE_CURRENT_LIST_DIR}/build/${TOYMATRIX_DIR}-${BUILD_TYPE})

set(TOYRENDERER_DIR ToyRenderer)
set(TOYRENDERER_SRC_DIR ${CMAKE_CURRENT_LIST_DIR}/${TOYRENDERER_DIR})
set(TOYRENDERER_BIN_DIR ${CMAKE_CURRENT_LIST_DIR}/build/${TOYRENDERER_DIR}-${BUILD_TYPE})


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
#find_package(GTest QUIET)
# The cmake config of the official GTest project is broken IMHO. We will use our
# own version regardless of any installed version in the system.
set(GTest_FOUND "")
if( NOT GTest_FOUND ) 
  set(GTEST_DOWNLOAD_CMD cmake -DCLONE_URL=https://github.com/hadjian/${GTEST_DIR}.git)
  set(GTEST_DOWNLOAD_CMD ${GTEST_DOWNLOAD_CMD} -DCLONE_TAG=master)
  set(GTEST_DOWNLOAD_CMD ${GTEST_DOWNLOAD_CMD} -DCLONE_DIR=${GTEST_SRC_DIR})
  set(GTEST_DOWNLOAD_CMD ${GTEST_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)
  
  ExternalProject_Add(gtest-external
                       PREFIX            cmake/gtest-external-prefix
                       DOWNLOAD_COMMAND  ${GTEST_DOWNLOAD_CMD} 
                       DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR} 
                       UPDATE_COMMAND    git fetch 
                       SOURCE_DIR        ${GTEST_SRC_DIR}
                       CONFIGURE_COMMAND cmake -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} ${GTEST_SRC_DIR} 
                       BINARY_DIR        ${GTEST_BIN_DIR}
                       INSTALL_COMMAND   echo "Not invoking install")
else( NOT GTest_FOUND )
  message("Found GTest in the system. Skipping compilation of included source.")
  # We will define all required targets to do nothing
  ExternalProject_Add(gtest-external
		       PREFIX            cmake/gtest-external-prefix
		       DOWNLOAD_COMMAND  cmake -E echo "Using system gtest" 
		       DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR}
		       UPDATE_COMMAND    cmake -E echo "Using system gtest" 
		       SOURCE_DIR        ${GTEST_SRC_DIR}
		       CONFIGURE_COMMAND cmake -E echo "No need to configure. Makefile based."  
		       BUILD_COMMAND     cmake -E echo "No need to configure. Makefile based."  
		       BUILD_IN_SOURCE   1
		       INSTALL_COMMAND   cmake -E echo "Not invoking install")
endif( NOT GTest_FOUND )

find_library(GLEW_LIBRARY GLEW)
if( NOT GLEW_LIBRARY )
  set(GLEW_DOWNLOAD_CMD cmake -DCLONE_URL=https://github.com/hadjian/${GLEW_DIR}.git)
  set(GLEW_DOWNLOAD_CMD ${GLEW_DOWNLOAD_CMD} -DCLONE_TAG=master)
  set(GLEW_DOWNLOAD_CMD ${GLEW_DOWNLOAD_CMD} -DCLONE_DIR=${GLEW_SRC_DIR})
  set(GLEW_DOWNLOAD_CMD ${GLEW_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)

  # We translate the CMake build type of "Debug" or "Release" to the appropriate target 
  # for the Makefile of glew, which is "debug" for the first and the empty string
  # for a release build.
  set(BUILD "")
  if (${BUILD_TYPE} MATCHES "Debug")
    set(BUILD "debug")
  endif(${BUILD_TYPE} MATCHES "Debug")

  ExternalProject_Add(glew-external
                       PREFIX            cmake/glew-external-prefix
                       DOWNLOAD_COMMAND  ${GLEW_DOWNLOAD_CMD}
                       DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR}
                       UPDATE_COMMAND    git fetch
                       SOURCE_DIR        ${GLEW_SRC_DIR}
                       CONFIGURE_COMMAND cmake -E echo "No need to configure. Makefile based."  
                       BUILD_COMMAND     make -f ${GLEW_SRC_PATH}/Makefile ${BUILD} VPATH=${GLEW_SRC_PATH} DIST_NAME=${GLEW_BIN_DIR}
                       BINARY_DIR        build/${GLEW_BIN_DIR}
		       INSTALL_COMMAND   cmake -E echo "Not invoking install")
else( NOT GLEW_LIBRARY )
  message("Found GLEW in the system. Skipping compilation of included source.")
  # We will define all required targets to do nothing
  ExternalProject_Add(glew-external
                       PREFIX            cmake/glew-external-prefix
		       DOWNLOAD_COMMAND  cmake -E echo "Found glew in system. Skipping bundled source." 
                       DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR}
                       UPDATE_COMMAND    cmake -E echo "Found glew in system. Skipping bundled source." 
                       SOURCE_DIR        ${GLEW_SRC_DIR}
                       CONFIGURE_COMMAND cmake -E echo "Found glew in system. Skipping bundled source."  
                       BUILD_COMMAND     cmake -E echo "Found glew in system. Skipping bundled source."  
                       BUILD_IN_SOURCE   1
		       INSTALL_COMMAND   cmake -E echo "Found glew in system. Skipping bundled source.")
endif( NOT GLEW_LIBRARY )

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
set(INJECT_GTEST_PATH "${GTEST_BIN_DIR}")
configure_file(cmake/toymatrix_inject_variables.cmake.in
                 "cmake/toymatrix_inject_variables.cmake" @ONLY)

#-------------------------------------------------------------------------------
# Custom git clone command. See comment above at the gtest target.
#-------------------------------------------------------------------------------
set(TOYMATRIX_DOWNLOAD_CMD cmake -DCLONE_URL=https://github.com/hadjian/${TOYMATRIX_DIR}.git)
set(TOYMATRIX_DOWNLOAD_CMD ${TOYMATRIX_DOWNLOAD_CMD} -DCLONE_TAG=master)
set(TOYMATRIX_DOWNLOAD_CMD ${TOYMATRIX_DOWNLOAD_CMD} -DCLONE_DIR=${TOYMATRIX_SRC_DIR})
set(TOYMATRIX_DOWNLOAD_CMD ${TOYMATRIX_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)

ExternalProject_Add(toymatrix-external
                     DEPENDS           gtest-external
                     PREFIX            cmake/toymatrix-external-prefix
                     DOWNLOAD_COMMAND  ${TOYMATRIX_DOWNLOAD_CMD} 
                     DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR} 
                     UPDATE_COMMAND    git fetch 
                     SOURCE_DIR        ${TOYMATRIX_SRC_DIR}
                     CONFIGURE_COMMAND cmake -DArithmeticExceptions=ON -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -C${CMAKE_CURRENT_LIST_DIR}/cmake/toymatrix_inject_variables.cmake ${TOYMATRIX_SRC_DIR} 
                     BINARY_DIR        ${TOYMATRIX_BIN_DIR}
                     INSTALL_COMMAND   echo "Not invoking install")

#-------------------------------------------------------------------------------
# The ToyRenderer in this superproject shall find the ToyMatrix project
# in the same directory. Injecting the appropriate cached variables. 
#-------------------------------------------------------------------------------
set(INJECT_FIND_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(INJECT_TOYMATRIX_PATH "${TOYMATRIX_BIN_DIR}")
set(INJECT_GLEW_BIN_DIR "${GLEW_BIN_DIR}")
set(INJECT_GLEW_BIN_PATH "${GLEW_BIN_PATH}")
set(INJECT_GLEW_INCLUDE_PATH "${GLEW_SRC_PATH}")
configure_file(cmake/toyrenderer_inject_variables.cmake.in
                 "cmake/toyrenderer_inject_variables.cmake" @ONLY)

#-------------------------------------------------------------------------------
# Custom git clone command. See comment above at the gtest target.
#-------------------------------------------------------------------------------
set(TOYRENDERER_DOWNLOAD_CMD cmake -DCLONE_URL=https://github.com/hadjian/${TOYRENDERER_DIR}.git)
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -DCLONE_TAG=master)
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -DCLONE_DIR=${TOYRENDERER_SRC_DIR})
set(TOYRENDERER_DOWNLOAD_CMD ${TOYRENDERER_DOWNLOAD_CMD} -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/safe_git_clone.cmake)

ExternalProject_Add(toyrenderer-external
                     DEPENDS           toymatrix-external gtest-external glew-external
                     PREFIX            cmake/toyrenderer-external-prefix
                     DOWNLOAD_COMMAND  ${TOYRENDERER_DOWNLOAD_CMD} 
                     DOWNLOAD_DIR      ${CMAKE_CURRENT_LIST_DIR}
                     UPDATE_COMMAND    git fetch 
                     SOURCE_DIR        ${TOYRENDERER_SRC_DIR}
                     CONFIGURE_COMMAND cmake -DCMAKE_BUILD_TYPE:STRING=${BUILD_TYPE} -C${CMAKE_CURRENT_LIST_DIR}/cmake/toyrenderer_inject_variables.cmake ${TOYRENDERER_SRC_DIR} 
                     BINARY_DIR        ${TOYRENDERER_BIN_DIR}
                     INSTALL_COMMAND   echo "Not invoking install")

#--------------------------------------------------------------------------------
# All targets run through all steps when the default target is invoked (e.g. make
# ALL on linux). I don't like that to happen. The default should at max download 
# all subprojects, but not build them. Also a short manual should be printed. 
#--------------------------------------------------------------------------------
set_target_properties(gtest-external toymatrix-external toyrenderer-external
                      PROPERTIES EXCLUDE_FROM_ALL 1)

#--------------------------------------------------------------------------------
# Configure the download and update steps of all subprojects (which are not
# found in the system), to be separately invokable targets. 
#--------------------------------------------------------------------------------
if ( NOT GTEST_FOUND )
ExternalProject_Add_StepTargets( gtest-external download update configure )
set( DOWNLOAD_TARGETS ${DOWNLOAD_TARGETS} gtest-external-download )
set( UPDATE_TARGETS   ${UPDATE_TARGETS}   gtest-external-update   )
endif ( NOT GTEST_FOUND )

if ( NOT GLEW_LIBRARY )
ExternalProject_Add_StepTargets(glew-external download update configure)
set( DOWNLOAD_TARGETS ${DOWNLOAD_TARGETS} glew-external-download )
set( UPDATE_TARGETS   ${UPDATE_TARGETS}   glew-external-update   )
endif ( NOT GLEW_LIBRARY )

ExternalProject_Add_StepTargets(toymatrix-external download update configure)
set(DOWNLOAD_TARGETS ${DOWNLOAD_TARGETS} toymatrix-external-download )
set(UPDATE_TARGETS   ${UPDATE_TARGETS}   toymatrix-external-update   )

ExternalProject_Add_StepTargets(toyrenderer-external download update configure)
set(DOWNLOAD_TARGETS ${DOWNLOAD_TARGETS} toyrenderer-external-download )
set(UPDATE_TARGETS   ${UPDATE_TARGETS}   toyrenderer-external-update   )

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

