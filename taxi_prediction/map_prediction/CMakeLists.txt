cmake_minimum_required(VERSION 2.8)
project(map_prediction)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CONFIGURATION_TYPES "Release")
SET(CMAKE_CXX_FLAGS ${CMAKE_CXX_FLAGS} "-std=c++11 -pthread")
add_definitions(-std=c++11 -pthread)

find_package (Threads)

file(GLOB INCLUDES "include/*.h")
include_directories(include)

file(GLOB SOURCES "src/*.cpp")
add_library(lib ${SOURCES} ${INCLUDES})

add_executable(map_prediction main.cpp ${SOURCES} ${INCLUDES})
target_link_libraries(map_prediction lib ${CMAKE_THREAD_LIBS_INIT})

add_executable(test_a_start tests/a_star_test.cpp ${SOURCES} ${INCLUDES})
target_link_libraries(test_a_start lib)

add_executable(measure_acc tests/measure_accuracy.cpp ${SOURCES} ${INCLUDES})
target_link_libraries(measure_acc lib)

add_executable(test_vel_time_map tests/vel_time_map_test.cpp ${SOURCES} ${INCLUDES})
target_link_libraries(test_vel_time_map lib)

add_executable(optimise tests/optimise.cpp ${SOURCES} ${INCLUDES})
target_link_libraries(optimise lib)


