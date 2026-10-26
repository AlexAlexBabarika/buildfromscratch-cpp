cmake_minimum_required(VERSION 3.25)
project(bfspp LANGUAGES CXX)

add_library(bfspp src/version.cpp)
target_include_directories(bfspp PUBLIC include)

add_executable(bfspp_app app/main.cpp)
target_link_libraries(bfspp_app PRIVATE bfspp)

target_compile_features(bfspp PUBLIC cxx_std_20)