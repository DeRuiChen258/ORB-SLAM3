# Offline-only shim for the fork's unconditional catkin dependency.
# The RGB-D executable and linked ORB-SLAM3 library do not use ROS APIs.
set(catkin_FOUND TRUE)
set(catkin_INCLUDE_DIRS "")
set(catkin_LIBRARIES "")

foreach(_component IN LISTS catkin_FIND_COMPONENTS)
  set(catkin_${_component}_FOUND TRUE)
endforeach()
