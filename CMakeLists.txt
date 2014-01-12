cmake_minimum_required(VERSION 2.8)
project(ToyProjects)

set (ToyProject_VERSION_MAJOR 0)
set (ToyProject_VERSION_MINOR 1)

Include(ExternalProject)

set(gtest_dir gtest-1.6.0)
set(toymatrix_dir ToyMatrix)
set(toyrenderer_dir ToyRenderer)

ExternalProject_Add(gtest
                     GIT_REPOSITORY    git@github.com:hadjian/${gtest_dir}.git
                     GIT_TAG           master
                     DOWNLOAD_DIR      ${gtest_dir}
                     SOURCE_DIR        ${gtest_dir}
                     CONFIGURE_COMMAND cmake .
                     BINARY_DIR        ${gtest_dir}
                     INSTALL_COMMAND   echo "Not invoking install")

ExternalProject_Add(toymatrix
                     GIT_REPOSITORY    git@github.com:hadjian/${toymatrix_dir}.git
                     GIT_TAG           master
                     DOWNLOAD_DIR      ${toymatrix_dir}
                     SOURCE_DIR        ${toymatrix_dir}
                     CONFIGURE_COMMAND cmake .
                     BINARY_DIR        ${toymatrix_dir}
                     INSTALL_COMMAND   echo "Not invoking install")

ExternalProject_Add(toyrenderer
                     GIT_REPOSITORY    git@github.com:hadjian/${toyrenderer_dir}.git
                     GIT_TAG           master
                     DOWNLOAD_DIR      ${toyrenderer_dir}
                     SOURCE_DIR        ${toyrenderer_dir}
                     CONFIGURE_COMMAND cmake .
                     BINARY_DIR        ${toyrenderer_dir}
                     INSTALL_COMMAND   echo "Not invoking install")

ExternalProject_Add_StepTargets(gtest download)
ExternalProject_Add_StepTargets(toymatrix download)
ExternalProject_Add_StepTargets(toyrenderer download)

set_target_properties(gtest toymatrix toyrenderer
                      PROPERTIES EXCLUDE_FROM_ALL 1)

add_custom_target(download DEPENDS
                   gtest-download
                   toymatrix-download
                   toyrenderer-download)
