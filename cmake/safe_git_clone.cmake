#------------------------------------------------------------------------------
# This script clones the repository/tag to the CLONE_DIR specified by the following
# variables:
# 
#   CLONE_URL  - Url to git rep (e.g. git@github.com:<user>/<repo>.git).
#   CLONE_TAG  - Branch of the git repo to check out.
#   CLONE_DIR  - Name of directory to which to clone to.
#   


if(DEFINED CLONE_URL AND DEFINED CLONE_TAG AND DEFINED CLONE_DIR)
  if(NOT EXISTS ${CLONE_DIR}/.git)
    message("Cloning ${CLONE_URL}!")
    execute_process(COMMAND git clone --branch ${CLONE_TAG} ${CLONE_URL} ${CLONE_DIR})     
    if(DEFINED VERSION)
      execute_process(COMMAND git checkout ${VERSION} WORKING_DIRECTORY ${CLONE_DIR})     
    endif(DEFINED VERSION)
  else(NOT EXISTS ${CLONE_DIR}/.git)
    message("Path ${CLONE_DIR}/.git already exists. Skipping clone.")
  endif(NOT EXISTS ${CLONE_DIR}/.git)
else(DEFINED CLONE_URL AND DEFINED CLONE_TAG AND DEFINED CLONE_DIR)
  message("Did not clone anything. One of CLONE_URL, CLONE_TAG or CLONE_DIR was not defined.")
endif(DEFINED CLONE_URL AND DEFINED CLONE_TAG AND DEFINED CLONE_DIR)
