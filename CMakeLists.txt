cmake_minimum_required(VERSION 3.18)
project(imgui_bundle_embed VERSION "0.0.1") # Remember to mirror changes to pyproject.toml!
find_package (Python COMPONENTS Interpreter Development)
add_compile_definitions(IMGUI_BUNDLE_BUILD_PYTHON)
add_compile_definitions(IMGUI_BUNDLE_PYTHON_API)
set(IMGUI_BUNDLE_BUILD_DEMOS OFF)
set(IMGUI_BUNDLE_BUILD_PYTHON ON) 
set(IMGUI_BUNDLE_DISABLE_IMMVISION ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)




# imgui_bundle_build_lib contains the main logic to build imgui_bundle
set(imgui_bundle_embed_path ${CMAKE_CURRENT_LIST_DIR} CACHE STRING "" FORCE)

include(cmake/imgui_bundle_bindings_static.cmake)

add_subdirectory(imgui_bundle imgui_bundle/build)


add_imgui_bundle_bindings_static()

add_executable(main main.cpp modules.cpp ${python_module_sources})
target_link_libraries(main   imgui_bundle_bindings_static)
target_link_libraries(main   imgui_bundle)
target_link_libraries(main   nanobind-static)

target_include_directories(main PRIVATE ${Python_INCLUDE_DIRS})
