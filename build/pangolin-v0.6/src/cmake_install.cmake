# Install script for directory: /home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/Pangolin-v0.6/src

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "Release")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Install shared libraries without execute permission?
if(NOT DEFINED CMAKE_INSTALL_SO_NO_EXE)
  set(CMAKE_INSTALL_SO_NO_EXE "1")
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "FALSE")
endif()

# Set path to fallback-tool for dependency-resolution.
if(NOT DEFINED CMAKE_OBJDUMP)
  set(CMAKE_OBJDUMP "/usr/bin/objdump")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/include/pangolin/config.h")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/include/pangolin" TYPE FILE FILES "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/include/pangolin/config.h")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/include/pangolin")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/include" TYPE DIRECTORY FILES "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/Pangolin-v0.6/src/../include/pangolin")
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so")
    file(RPATH_CHECK
         FILE "$ENV{DESTDIR}/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so"
         RPATH "")
  endif()
  list(APPEND CMAKE_ABSOLUTE_DESTINATION_FILES
   "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so")
  if(CMAKE_WARN_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(WARNING "ABSOLUTE path INSTALL DESTINATION : ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  if(CMAKE_ERROR_ON_ABSOLUTE_INSTALL_DESTINATION)
    message(FATAL_ERROR "ABSOLUTE path INSTALL DESTINATION forbidden (by caller): ${CMAKE_ABSOLUTE_DESTINATION_FILES}")
  endif()
  file(INSTALL DESTINATION "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib" TYPE SHARED_LIBRARY FILES "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/libpangolin.so")
  if(EXISTS "$ENV{DESTDIR}/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so" AND
     NOT IS_SYMLINK "$ENV{DESTDIR}/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so")
    if(CMAKE_INSTALL_DO_STRIP)
      execute_process(COMMAND "/usr/bin/strip" "$ENV{DESTDIR}/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/deps/lib/libpangolin.so")
    endif()
  endif()
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Pangolin" TYPE FILE FILES
    "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/CMakeFiles/PangolinConfig.cmake"
    "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/PangolinConfigVersion.cmake"
    )
endif()

if(CMAKE_INSTALL_COMPONENT STREQUAL "Unspecified" OR NOT CMAKE_INSTALL_COMPONENT)
  if(EXISTS "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/Pangolin/PangolinTargets.cmake")
    file(DIFFERENT _cmake_export_file_changed FILES
         "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/Pangolin/PangolinTargets.cmake"
         "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/CMakeFiles/Export/2022d04a83e11e29aa9cd8cffe2d235e/PangolinTargets.cmake")
    if(_cmake_export_file_changed)
      file(GLOB _cmake_old_config_files "$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/Pangolin/PangolinTargets-*.cmake")
      if(_cmake_old_config_files)
        string(REPLACE ";" ", " _cmake_old_config_files_text "${_cmake_old_config_files}")
        message(STATUS "Old export file \"$ENV{DESTDIR}${CMAKE_INSTALL_PREFIX}/lib/cmake/Pangolin/PangolinTargets.cmake\" will be replaced.  Removing files [${_cmake_old_config_files_text}].")
        unset(_cmake_old_config_files_text)
        file(REMOVE ${_cmake_old_config_files})
      endif()
      unset(_cmake_old_config_files)
    endif()
    unset(_cmake_export_file_changed)
  endif()
  file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Pangolin" TYPE FILE FILES "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/CMakeFiles/Export/2022d04a83e11e29aa9cd8cffe2d235e/PangolinTargets.cmake")
  if(CMAKE_INSTALL_CONFIG_NAME MATCHES "^([Rr][Ee][Ll][Ee][Aa][Ss][Ee])$")
    file(INSTALL DESTINATION "${CMAKE_INSTALL_PREFIX}/lib/cmake/Pangolin" TYPE FILE FILES "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/CMakeFiles/Export/2022d04a83e11e29aa9cd8cffe2d235e/PangolinTargets-release.cmake")
  endif()
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
if(CMAKE_INSTALL_LOCAL_ONLY)
  file(WRITE "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/install_local_manifest.txt"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
endif()
