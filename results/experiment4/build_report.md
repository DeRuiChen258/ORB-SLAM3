# 构建记录

## 最终构建与运行

验收运行为 [20261017T082609Z](runs/20261017T082609Z/status.txt)，用户在 `cuda_134` / RTX 5070 Laptop GPU 环境完成 `./start.sh`，处理 573 帧，输出 573/402 条相机/关键帧位姿并正常退出。CUDA ORB 前端开关与实际路径见 [本次构建记录](runs/20261017T082609Z/build_report.md)、[完整日志](runs/20261017T082609Z/start.log) 和 [最终实验报告](experiment4_report.md)。

- 工具链：GNU C++ 15.2，CMake 3.31.6，NVCC 13.4.92，OpenCV 4.10，Eigen 3.4，项目内 Pangolin v0.6。
- DCH 按其 CMake 使用 C++14；CUDA 架构 `120`，`USE_CUDA_FRONTEND=ON`，`DCH_BUILD_EXTRA_EXAMPLES=OFF`，Release。
- 成功构建 `liborbslam3_cuda.a`、含 Barron 的 `libg2o.so`、`libORB_SLAM3.so` 和 `Examples/RGB-D/rgbd_tum`。`cuobjdump --list-elf` 确认可执行文件含 `sm_120` cubin，`ldd` 没有缺失项。
- 本机工具 shell 无 GPU runtime；CUDA 实机结果由用户终端日志和状态文件确认。收尾不再修改成功版本的 C++ 或运行入口。

## DCH-SLAM 构建入口

上游 revision：`199a02517949afe8b4cd20aad8ab6e6ad51d3de5`。本地差异保存在 [DCH-SLAM.patch](../../versions/v2_cuda_success_20261017/DCH-SLAM.patch)，文件哈希见 [固定版本清单](../../versions/v2_cuda_success_20261017/release_manifest.json)。当前工作区已应用补丁，`start.sh` 的 CMake 准备步骤会识别已处理状态。

以下命令已由 `start.sh` 执行，实际绝对路径及输出见成功运行 start.log：

```bash
cmake -S "source/DCH-SLAM" -B "build/dch-cuda" \
  -DUSE_CUDA_FRONTEND=ON -DDCH_BUILD_EXTRA_EXAMPLES=OFF \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=120 \
  -DPangolin_DIR="$PWD/build/deps/lib/cmake/Pangolin"
cmake --build "build/dch-cuda" --target g2o --parallel 4
cmake --build "build/dch-cuda" --target rgbd_tum --parallel 4
```

g2o 必须先构建，因为 DCH 顶层按共享库文件路径链接它，不声明 CMake target 依赖；跳过会误用旧库并缺少 Barron 符号。

## 本地依赖与修复

- DCH 省略了 DBoW2、Sophus 与多数标准 g2o 文件。当前工程从已审计 CPU baseline 非覆盖式补齐，保留 DCH Barron patch；DBoW2 按本机 OpenCV 4.10 重建。
- `scripts/prepare_dch_source.py` 给不完整 checkout 的额外示例添加可选开关，演示只构建所需 RGB-D target。
- YOLO COCO 类别、cfg 和权重已从公开模型目录下载并校验；实际 SHA-256 记录在成功运行 run_manifest.md。YOLO 使用 CPU backend。
- `ORBmatcher.cc` 保护空 LK 点集及输出坐标；`Tracking.cc` 在 map reset 后保护空帧、重建 LK 状态并回到 ORB 初始化；`System.cc` / `Viewer.cc` 等待并 join worker、在 Viewer 线程清理窗口。
- Pangolin 旧版在 G++ 15 下缺少若干标准头文件，项目内依赖源码已补齐并成功构建。安装位于 build/deps，没有更改系统安装。
- CMake 旧兼容性、Eigen/g2o/DCH 旧代码的比较/弃用/初始化警告仍在。RealSense 未安装的提示不影响离线 RGB-D target；Qt timer 清理提示在成功运行仍出现，列入已知问题。

## CPU baseline 构建历史

- 源码为 `aliaxam153/ORB_SLAM3` main 归档，SHA-256 `76660dbe2a090d2fb98ed639c0dbf5aaa51abc4cc06106e2027e0a52cb0efaa1`。
- 用项目本地 `scripts/catkin-shim/catkinConfig.cmake` 满足非 ROS 目标的顶层 catkin 检查，未构建 ROS wrapper。
- 已执行以下隔离构建，退出码 0：

```bash
cmake -S "source/ORB_SLAM3" -B "build/orbslam3" \
  -DCMAKE_BUILD_TYPE=Release -DCMAKE_EXPORT_NO_PACKAGE_REGISTRY=ON \
  -Dcatkin_DIR="$PWD/scripts/catkin-shim" \
  -DPangolin_DIR="$PWD/build/deps/lib/cmake/Pangolin" \
  -DCMAKE_PREFIX_PATH="$PWD/build/deps"
cmake --build "build/orbslam3" --target rgbd_tum --parallel 4
```

原 CPU fork 的旧 DBoW2 二进制依赖 OpenCV 4.4，已用当前 OpenCV 4.10 重建。日志为 [cpu-rgbd-build.log](logs/cpu-rgbd-build.log) 与 [dbow2-build.log](logs/dbow2-build.log)。CPU 构建仅用于参考和依赖复用，未执行序列性能对照。
