# ORB-SLAM3 RGB-D CUDA 演示

本项目在 TUM RGB-D `freiburg1_desk` 序列上运行基于 DCH-SLAM 的 CUDA RGB-D SLAM，并保存相机轨迹、稀疏地图和评估结果。仓库包含启动脚本、项目源码与依赖快照、输入数据、运行结果和版本归档。

![ORB-SLAM3 CUDA RGB-D map viewer demo](demo.gif)

## 实验结果

验收运行于 RTX 5070 Laptop GPU / CUDA 13.4，处理完整序列后正常退出。

| 指标 | 结果 |
|---|---:|
| RGB-D 帧数 | 573 |
| 相机轨迹位姿 | 573 |
| 关键帧轨迹位姿 | 402 |
| ATE RMSE | 0.023424 m |
| 真值配对 | 573 / 573 |
| 轨迹对齐 | SE(3)，不拟合尺度 |

本数值只描述这次 `fr1/desk` 回放。它不能代表其他序列的定位精度，也不是 CUDA 加速比。

运行结果和图表位于 [`results/experiment4/`](results/experiment4/)，最终验收记录见 [`final_verification.md`](results/experiment4/final_verification.md)。固定成功运行目录为 [`20261017T082609Z`](results/experiment4/runs/20261017T082609Z/)。其中包含相机/关键帧轨迹、运行日志、Pangolin 地图截图、XY/3D 轨迹图和 ATE 结果说明。

## 方法与源码来源

任务指定的 `aliaxam153/ORB_SLAM3` 不含 CUDA 前端，因此实验选择 [DCH-SLAM](https://github.com/datrich/DCH-SLAM) 的 RGB-D 示例。源码基于上游 revision `199a02517949afe8b4cd20aad8ab6e6ad51d3de5`，并包含为本地依赖和运行问题所做的修复。`source/ORB_SLAM3/` 保留 CPU-only 基线及部分依赖来源；`source/DCH-SLAM/` 是实际使用的 CUDA 实现。

DCH-SLAM 还包括异步 YOLO 语义处理和自适应 Barron 鲁棒核。因此这次结果不能用于把精度或速度变化单独归因于 CUDA。仓库保留了各上游源码目录中的许可证和第三方声明；请按对应组件的许可证使用，顶层 `LICENSE` 不替代这些声明。

## 环境要求

已验证环境：Ubuntu 26.04.1、RTX 5070 Laptop GPU、CUDA 13.4、OpenCV 4.10、Python 3.12。运行需要：

- NVIDIA 驱动、可用 GPU 和 CUDA Toolkit（包含 `nvcc`）
- C++17 编译器、CMake、Git、curl
- OpenCV、Eigen、Pangolin、Boost Serialization、OpenSSL
- Python 3、NumPy、Matplotlib、Pillow
- 图形桌面环境（用于 Pangolin viewer 和地图截图）

其他系统、CUDA 架构和依赖版本未完整验证。脚本不会安装系统包；缺少依赖时会保留日志并退出，不会切换到 CPU。默认 CUDA 架构为 `120`；可按显卡设置 `SLAM_CUDA_ARCHITECTURES`。

## 获取与运行

大文件使用 Git LFS。先安装 Git LFS，再克隆仓库并拉取对象：

```bash
git lfs install
git clone https://github.com/DeRuiChen258/ORB-SLAM3.git
cd ORB-SLAM3
git lfs pull
```

在已准备好上述依赖的 Linux shell 中启动：

```bash
./start.sh
```

脚本检查 GPU 与依赖，准备 DCH-SLAM 所需文件，安全检查并关联 RGB/深度图像，构建 `rgbd_tum`，回放序列并生成日志和轨迹图。仓库包含 `fr1/desk` 数据归档和处理后的词袋文件；若缺少输入，脚本会尝试从公开来源获取。

可选参数：

```bash
SLAM_CUDA_ARCHITECTURES=87 ./start.sh
SLAM_BUILD_JOBS=8 ./start.sh
SLAM_VIEWER_CAPTURE_TIMEOUT=45 ./start.sh
```

`SLAM_SETTINGS` 可指定相机 YAML。每次运行会在 `results/experiment4/runs/<UTC 时间>/` 创建独立目录，不覆盖旧结果。以该目录 `status.txt` 的 `status=success` 和 `exit_code=0` 判断运行是否完整；提前按 Ctrl+C 停止可能留下不完整轨迹。

## 目录结构

- `associations/`：RGB 与深度图像时间戳关联。
- `build/`：本机 CUDA/第三方构建记录和构建目录；CMake 缓存绑定原构建环境，换机器应重新配置。
- `data/`：TUM 原始归档、序列数据和 ORB 词袋文件。
- `results/`：数据审计、实验记录、轨迹、图表和运行日志。
- `scripts/`：安全准备数据、提取词袋、准备源码和分析轨迹的辅助脚本。
- `source/`：DCH-SLAM CUDA 源码、ORB-SLAM3 CPU 基线、Pangolin 及依赖快照。
- `versions/`：修复源码补丁、版本清单与恢复快照。快照在公开前移除了 `Prompt/`、`docs/` 和内部 agent 状态。
- `start.sh`：从源码构建并运行 TUM RGB-D 演示的一键入口。

`Prompt/` 和 `docs/` 未纳入公开仓库。Git LFS 需要安装后才能下载大文件；普通 Git 克隆可能只拿到 LFS 指针。

## 数据引用与许可

TUM RGB-D `freiburg1_desk` 数据集来自 [TUM RGB-D Benchmark](https://cvg.cit.tum.de/data/datasets/rgbd-dataset)，按该数据集页面标注的 CC BY 3.0 条款分发。使用数据或发布其结果时，请注明数据来源并引用：Jürgen Sturm, Nikolas Engelhard, Felix Endres, Wolfram Burgard, and Daniel Cremers, “A Benchmark for the Evaluation of RGB-D SLAM Systems,” IROS 2012。

## 已知限制

- 目前只验证单条静态室内序列的一次完整回放；没有据此声称对动态场景具备鲁棒性。
- 这次成功回放没有触发跟踪丢失或新地图切换，恢复分支没有被强制验证。
- 日志仍有非致命 Qt timer 清理提示；CUDA 内存/竞态 sanitizer 未运行。
- Pangolin 截图依赖 X11、`xwininfo` 和 ImageMagick；headless/Wayland 环境未验证。
- 项目提供视觉定位和稀疏建图，不包含导航规划、避障或运动控制，不是自主导航系统。
