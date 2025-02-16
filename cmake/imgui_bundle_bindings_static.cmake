# copy from \nanobind\cmake
#
function(nanobind_add_module_static name)
  cmake_parse_arguments(PARSE_ARGV 1 ARG
    "STABLE_ABI;FREE_THREADED;NB_STATIC;NB_SHARED;PROTECT_STACK;LTO;NOMINSIZE;NOSTRIP;MUSL_DYNAMIC_LIBCPP"
    "NB_DOMAIN" "")

  add_library(${name} STATIC ${ARG_UNPARSED_ARGUMENTS})

  nanobind_compile_options(${name})
  nanobind_link_options(${name})
  set_target_properties(${name} PROPERTIES LINKER_LANGUAGE CXX)

  if (ARG_NB_SHARED AND ARG_NB_STATIC)
    message(FATAL_ERROR "NB_SHARED and NB_STATIC cannot be specified at the same time!")
  elseif (NOT ARG_NB_SHARED)
    set(ARG_NB_STATIC TRUE)
  endif()

  # Stable ABI builds require CPython >= 3.12 and Python::SABIModule
  if ((Python_VERSION VERSION_LESS 3.12) OR
      (NOT Python_INTERPRETER_ID STREQUAL "Python") OR
      (NOT TARGET Python::SABIModule))
    set(ARG_STABLE_ABI FALSE)
  endif()

  if (NB_ABI MATCHES "t")
    set(ARG_STABLE_ABI FALSE)
  else(ARG_STABLE_ABI)
    set(ARG_FREE_THREADED FALSE)
  endif()

  set(libname "nanobind")
  if (ARG_NB_STATIC)
    set(libname "${libname}-static")
  endif()

  if (ARG_STABLE_ABI)
    set(libname "${libname}-abi3")
  endif()

  if (ARG_FREE_THREADED)
    set(libname "${libname}-ft")
  endif()

  if (ARG_NB_DOMAIN AND ARG_NB_SHARED)
    set(libname ${libname}-${ARG_NB_DOMAIN})
  endif()

  nanobind_build_library(${libname})

  if (ARG_NB_DOMAIN)
    target_compile_definitions(${name} PRIVATE NB_DOMAIN=${ARG_NB_DOMAIN})
  endif()

  #if (ARG_STABLE_ABI)
  #  target_compile_definitions(${libname} PUBLIC -DPy_LIMITED_API=0x030C0000)
  #  nanobind_extension_abi3(${name})
  #else()
  #  nanobind_extension(${name})
  #endif()

  if (ARG_FREE_THREADED)
    target_compile_definitions(${name} PRIVATE NB_FREE_THREADED)
  endif()

  target_link_libraries(${name} PRIVATE ${libname})

  if (NOT ARG_PROTECT_STACK)
    nanobind_disable_stack_protector(${name})
  endif()

  if (NOT ARG_NOMINSIZE)
    nanobind_opt_size(${name})
  endif()

  if (NOT ARG_NOSTRIP)
    nanobind_strip(${name})
  endif()

  if (ARG_LTO)
    nanobind_lto(${name})
  endif()

  if (ARG_NB_STATIC AND NOT ARG_MUSL_DYNAMIC_LIBCPP)
    nanobind_musl_static_libcpp(${name})
  endif()

  nanobind_set_visibility(${name})
endfunction()




function(add_imgui_bundle_bindings_static)
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
    set(python_native_module_name imgui_bundle_bindings_static)    # This is the native python module name
    set(python_wrapper_module_name imgui_bundle)    # This is the python wrapper around the native module
    set(python_module_sources
        ${bindings_main_folder}/module.cpp
        ${bindings_main_folder}/pybind_imgui_bundle.cpp
        ${all_pybind_files}
        )

    nanobind_add_module_static(${python_native_module_name} ${python_module_sources})
    target_compile_definitions(${python_native_module_name} PRIVATE VERSION_INFO=${PROJECT_VERSION})

    #litgen_setup_module(${bound_library} ${python_native_module_name} ${python_wrapper_module_name} ${IMGUI_BUNDLE_PATH}/bindings)

    # add cvnp for immvision
    if (IMGUI_BUNDLE_WITH_IMMVISION)
        set(cvnp_nano_dir ${IMGUI_BUNDLE_PATH}/external/immvision/cvnp_nano)
        target_sources(${python_native_module_name} PRIVATE ${cvnp_nano_dir}/cvnp_nano/cvnp_nano.h)
        target_include_directories(${python_native_module_name} PRIVATE ${cvnp_nano_dir})

        target_compile_definitions(${python_native_module_name} PUBLIC IMGUI_BUNDLE_WITH_IMMVISION)
    endif()

    if(IMGUI_BUNDLE_BUILD_PYTHON)
        # if using shared libraries, we need to set the rpath,
        # so that dll/dylibs can be found in the same folder as imgui_bundle python lib.
        _target_set_rpath(${python_native_module_name} ".")
    endif()

    if (IMGUI_BUNDLE_BUILD_PYODIDE)
        ibd_pyodide_manually_link_sdl_to_bindings()
    endif()

    target_link_libraries(${python_native_module_name} PUBLIC ${bound_library})

    # Link with OpenGL (necessary for nanobind)
    if (NOT  EMSCRIPTEN)
        find_package(OpenGL REQUIRED)
        target_link_libraries(${python_native_module_name} PUBLIC OpenGL::GL)
    endif()

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
