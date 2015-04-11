ToyProjects
===========

This project contains a single CMakeLists.txt files, which
will download all subprojects for you. Just run

    cmake .
    make external-download
    
Currently it will download the master branch of every project.
In the future releases and dependencies will be maintained
through cmake.

I found this a lot better than using git submodules, because
of the many drawbacks (headless checkout, complicated
submodule commits and updates, ...).
