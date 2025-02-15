cmake_minimum_required(VERSION 3.18)
project(imgui_bundle_embed VERSION "0.0.1") # Remember to mirror changes to pyproject.toml!

# imgui_bundle_build_lib contains the main logic to build imgui_bundle
set(imgui_bundle_embed_path ${CMAKE_CURRENT_LIST_DIR} CACHE STRING "" FORCE)