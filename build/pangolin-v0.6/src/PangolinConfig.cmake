# Compute paths
get_filename_component( PROJECT_CMAKE_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH )
SET( Pangolin_INCLUDE_DIRS "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/Pangolin-v0.6/include;/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/include;/usr/include;/usr/include;/usr/include" )
SET( Pangolin_INCLUDE_DIR  "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/Pangolin-v0.6/include;/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/pangolin-v0.6/src/include;/usr/include;/usr/include;/usr/include" )

# Library dependencies (contains definitions for IMPORTED targets)
if( NOT TARGET pangolin AND NOT Pangolin_BINARY_DIR )
  include( "${PROJECT_CMAKE_DIR}/PangolinTargets.cmake" )
  
endif()

SET( Pangolin_LIBRARIES    pangolin )
SET( Pangolin_LIBRARY      pangolin )
SET( Pangolin_CMAKEMODULES /home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/Pangolin-v0.6/src/../CMakeModules )
