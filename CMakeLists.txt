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



add_subdirectory(imgui_bundle imgui_bundle/build)



function(my_add_imgui_bundle_bindings)
    include(${IMGUI_BUNDLE_PATH}/imgui_bundle_cmake/internal/litgen_setup_module.cmake)
    litgen_find_nanobind()
    if (WIN32)
        _nanobind_hack_disable_forceinline()
    endif()

    set(bindings_main_folder ${IMGUI_BUNDLE_PATH}/external/bindings_generation/cpp/)
    include(${bindings_main_folder}/all_pybind_files.cmake)

    #########################################################################
    # Build python module that provides bindings to the library hello_imgui
    #########################################################################
    set(bound_library imgui_bundle)                 # The library for which we are building bindings
    set(python_wrapper_module_name imgui_bundle)    # This is the python wrapper around the native module
    set(python_module_sources
        ${bindings_main_folder}/module.cpp
        ${bindings_main_folder}/pybind_imgui_bundle.cpp
        ${all_pybind_files}
        )
    set (python_native_module_name main)
    add_executable(${python_native_module_name} modules.cpp main.cpp ${python_module_sources})
 
    target_compile_definitions(${python_native_module_name} PRIVATE VERSION_INFO=${PROJECT_VERSION})

  
  

    if(IMGUI_BUNDLE_BUILD_PYTHON)
        # if using shared libraries, we need to set the rpath,
        # so that dll/dylibs can be found in the same folder as imgui_bundle python lib.
        _target_set_rpath(${python_native_module_name} ".")
    endif()

    target_include_directories(${python_native_module_name} PRIVATE "${nanobind_DIR}/../include")
    target_link_libraries(${python_native_module_name} PUBLIC ${bound_library})
    target_link_libraries(${python_native_module_name} PUBLIC nanobind-static)
    

    # Disable optimizations on release build for msvc
    # (leads to compilation times of > 3 hours!!!)
    if (MSVC)
        target_compile_options(${python_native_module_name} PRIVATE $<$<CONFIG:Release>:/Od>)
    endif()

    if (WIN32)
        # Band aid for windows debug build, where the python lib may not be found...
        target_link_directories(${python_native_module_name} PRIVATE ${Python_LIBRARY_DIRS})
    endif()
endfunction()

#add_executable(main main.cpp ${python_module_sources})
my_add_imgui_bundle_bindings()
#target_link_libraries(main imgui_bundle)
#target_include_directories(main PRIVATE ${Python_INCLUDE_DIRS})
