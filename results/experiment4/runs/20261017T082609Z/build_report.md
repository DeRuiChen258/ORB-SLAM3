# CUDA 构建记录

- CMake 选项：USE_CUDA_FRONTEND=ON
- CMake 选项：DCH_BUILD_EXTRA_EXAMPLES=OFF（仅配置所需 RGB-D 示例）
- CUDA 架构：120
- CUDA 静态库：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/dch-cuda/liborbslam3_cuda.a
- g2o 共享库：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Thirdparty/g2o/lib/libg2o.so
- YOLO 资产 SHA-256：coco.names=634a1132eb33f8091d60f2c346ababe8b905ae08387037aed883953b7329af84，cfg=036f1def6b96271bd6ec590dca80e833323d324e99450ec9aa5375f0b826d18b，weights=eb37bc51b21efc53f383de29b7504f818b1a9cb9949a2d62b332ba56e44a4027
- RGB-D 程序：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Examples/RGB-D/rgbd_tum
- 源 revision：199a02517949afe8b4cd20aad8ab6e6ad51d3de5
- CUDA 编译器：Build cuda_13.4.r13.4/compiler.38855100_0
- g2o 构建命令：cmake --build /home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/dch-cuda --target g2o --parallel 4
- 构建命令：cmake --build /home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/dch-cuda --target rgbd_tum --parallel 4
- 构建日志：本次 start.log

该记录来自本次构建完成后的缓存、库文件与可执行文件检查。GPU 运行状态以本次 SLAM 日志和 NVIDIA 驱动状态为准。
