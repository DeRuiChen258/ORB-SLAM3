# CUDA RGB-D 运行清单

- 后端：DCH-SLAM CUDA ORB 前端；CMake USE_CUDA_FRONTEND=ON
- CUDA 架构：120
- 源码：https://github.com/datrich/DCH-SLAM，revision 199a02517949afe8b4cd20aad8ab6e6ad51d3de5
- 相机配置：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Examples/RGB-D/TUM1.yaml
- 词袋：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/data/processed/ORBvoc.txt
- 数据集：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/data/raw/rgbd_dataset_freiburg1_desk
- association：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/associations/fr1_desk.txt
- 可执行文件：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Examples/RGB-D/rgbd_tum
- CUDA 前端静态库：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/dch-cuda/liborbslam3_cuda.a
- g2o 共享库（含 Barron 鲁棒核）：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Thirdparty/g2o/lib/libg2o.so
- DBoW2 共享库：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Thirdparty/DBoW2/lib/libDBoW2.so
- Sophus 头文件：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Thirdparty/Sophus/sophus
- YOLO 类别文件：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Thirdparty/YOLO/coco.names（SHA-256 634a1132eb33f8091d60f2c346ababe8b905ae08387037aed883953b7329af84）
- YOLO 配置文件：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Thirdparty/YOLO/yolo-fastest-xl.cfg（SHA-256 036f1def6b96271bd6ec590dca80e833323d324e99450ec9aa5375f0b826d18b）
- YOLO 权重：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/source/DCH-SLAM/Thirdparty/YOLO/yolo-fastest-xl.weights（SHA-256 eb37bc51b21efc53f383de29b7504f818b1a9cb9949a2d62b332ba56e44a4027）
- 构建目录：/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/build/dch-cuda
- 构建并运行命令见 start.log 与 slam.log。

DCH-SLAM 在 ORB-SLAM3 基础上额外包含 CUDA ORB 前端、异步 YOLO 语义线程和自适应 Barron 鲁棒核；本实验不能视为原始 ORB-SLAM3 的 CUDA-only 对照。
