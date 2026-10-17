#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "pangolin" for configuration "Release"
set_property(TARGET pangolin APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(pangolin PROPERTIES
  IMPORTED_LOCATION_RELEASE "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so"
  IMPORTED_SONAME_RELEASE "libpangolin.so"
  )

list(APPEND _cmake_import_check_targets pangolin )
list(APPEND _cmake_import_check_files_for_pangolin "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
