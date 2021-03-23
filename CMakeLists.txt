cmake_minimum_required(VERSION 3.14)
set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH}" "${CMAKE_CURRENT_LIST_DIR}/cmake/modules")

# register D support
include(EnableD)

project(argparse D)
include(ProjectSetup)

add_subdirectory(src)
add_subdirectory(tests)
