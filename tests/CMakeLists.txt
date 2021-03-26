# unit testing framework
CreateTargetFromPath(libtests-undead "dunit/undead/src" STATIC "libtests-undead" D 2)
CreateTargetFromPath(libtests-dunit "dunit/dunit/src" STATIC "libtests-dunit" D 2)
target_link_libraries(libtests-dunit PUBLIC libs::libtests-undead)

# unit tests
CreateTargetFromPath(argparse-tests "tests" EXECUTABLE "argparse-tests" D 2)
d_install_injectors(argparse-tests)
target_link_libraries(argparse-tests PRIVATE
    libs::libtests-dunit
    libs::argparse
)
