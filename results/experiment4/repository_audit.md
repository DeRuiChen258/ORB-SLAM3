# 源码与构建入口审计

## 获取记录

- 来源：`https://github.com/aliaxam153/ORB_SLAM3`
- 分支：`main`（GitHub codeload 分支归档）
- 本地目录：`source/ORB_SLAM3`
- 归档：`source/orb_slam3_main.tar.gz`
- SHA-256：`76660dbe2a090d2fb98ed639c0dbf5aaa51abc4cc06106e2027e0a52cb0efaa1`
- 格式与安全：gzip/tar；1,127 个成员、单一根目录 `ORB_SLAM3-main`；未发现绝对路径、`..` 路径穿越或链接成员；安全解压到项目目录。
- Git 元数据：归档不含 `.git`。`git clone` 在沙箱中因 socket 权限被拒绝，GitHub API 查询未返回可解析 JSON；因此精确 commit SHA 未能本地核实。归档 SHA-256 用作当前源码快照的固定标识。

## 初次审计时的仓库状态

- 工程根目录不是可操作的 Git 仓库。初次审计的 CPU 源码以归档 SHA-256 固定；最终 DCH checkout 有本地修改，补丁与文件清单见 [v2 验收版本](../../versions/v2_cuda_success_20261017/README.md)。
- Fork 源码包含 `Examples/RGB-D/rgbd_tum.cc`、`Examples/RGB-D/TUM1.yaml`，以及针对 `fr1_desk` 的已有 association 文件 `Examples/RGB-D/associations/fr1_desk.txt`。
- `rgbd_tum.cc` 需要 4 个程序参数：词汇表、YAML 设置、序列根目录、association 文件。association 第一列作为 RGB 时间戳传给 `TrackRGBD`；程序结束时在当前工作目录写 `CameraTrajectory.txt` 和 `KeyFrameTrajectory.txt`。
- `TUM1.yaml` 的分辨率为 640×480、帧率 30、深度因子 5000；焦距/主点值还需对照 TUM fr1 官方参数与解压数据核验。

## 构建入口与安全风险

- 顶层 `CMakeLists.txt` 要求 OpenCV ≥4.4、Eigen3、Pangolin，并无条件 `find_package(catkin REQUIRED COMPONENTS ...)`。ROS 包只用于 ROS wrapper；离线 `rgbd_tum` 源文件本身不包含 ROS 接口，但顶层配置仍会检查 catkin。
- `rgbd_tum` 是顶层 CMake 的 RGB-D target。可从独立 build directory 配置后只构建该 target；CMake 会将 `libORB_SLAM3.so` 写入源码树的 `lib/`，因此当前下载源码树中的旧预编译库会被重建结果替换。这些二进制属于本次下载快照，且已确认无法在当前环境加载。
- 仓库 `build.sh` 依次进入第三方构建目录、调用 `mkdir build`、解包词汇表并编译。归档已经带有第三方 `build/` 缓存，直接运行会撞目录；脚本没有 `set -e`，且会在源码树写入构建产物。此实验不直接运行该脚本。
- `build_prerequisities.sh` 含 `sudo apt`、添加软件源、切换系统 GCC/G++、安装 Pangolin/OpenCV/ROS、删除自身及追加 shell 启动配置等操作。本实验不运行该脚本。
- 归档内预编译 `rgbd_tum`/`libORB_SLAM3.so` 依赖缺失的 OpenCV 4.2/4.4、Pangolin、GLEW 2.1、Boost 1.71 和 OpenSSL 1.1，不能复用。

## 初次审计时的环境核对

- Ubuntu 26.04.1 LTS；G++ 15.2.0；CMake 3.31.6；Python 3.12.13。
- OpenCV 4.10.0、Eigen 3.4.0 可通过 `pkg-config` 找到；Boost Serialization 1.90 与 OpenSSL 3 可用。
- 本机没有检测到 ROS/`catkin` 或 Pangolin；GLEW 2.2、OpenGL/EGL、X11、Wayland 与常见图像/视频开发依赖可见。
- Python NumPy、Matplotlib、PyYAML、Pillow 可导入，系统有 X11 display 和 ImageMagick `import`。

## 构建路径决策

先尝试项目目录内隔离构建 Pangolin 并安装到项目专用 prefix；不安装系统软件包。为离线 RGB-D target 解除顶层无条件 catkin 检查时，优先使用项目本地、仅声明非 ROS 构建所需空变量的 CMake shim，并在报告中注明没有构建 ROS wrapper。构建命令使用独立目录，只构建 `rgbd_tum`。若 Pangolin 在现有系统依赖下无法本地构建，保留构建错误并停止运行阶段，不执行 fork 的安装脚本。

## CUDA 版本选择（用户确认）

- 用户于 2026-10-17 选择 `DCH-SLAM CUDA 前端`。候选仓库：[datrich/DCH-SLAM](https://github.com/datrich/DCH-SLAM)，分支 `main`。
- DCH-SLAM README 将自身描述为基于 ORB-SLAM3，并集成 CUDA ORB 前端、异步 YOLO 语义线程和自适应 Barron 鲁棒核。该实现不是 Prompt 指定 fork 的单纯 CUDA 移植，算法存在实质差异。
- README 给出的 CUDA 配置为 `USE_CUDA_FRONTEND=ON`；公开 [CMake 文件](https://github.com/datrich/DCH-SLAM/blob/main/CMakeLists.txt)声明该选项、启用 CUDA、建立 `orbslam3_cuda` 静态库并链接到 ORB-SLAM3 库，输出 `Examples/RGB-D/rgbd_tum`。README 为 RTX 50 系列示例使用架构 `120`：[DCH-SLAM README](https://github.com/datrich/DCH-SLAM)。本项目默认使用 `120`，可由 `SLAM_CUDA_ARCHITECTURES` 覆盖。
- GitHub 页面检查时列出 7 commits、0 stars、0 forks；README 中的论文引用作者仍标为 Anonymous。将其视为低成熟度社区实现，运行前需要核实实际 checkout 与构建产物。
- DCH-SLAM CMake 硬编码依赖 `Thirdparty/DBoW2/lib/libDBoW2.so`。本地 checkout 确认缺少该目录；`start.sh` 复用了本项目已按 OpenCV 4.10 构建的 ORB-SLAM3 DBoW2，保留已有 DCH-SLAM 文件。该 vendor 与共享库已进入最终快照。
- 用户宿主环境的运行发现 DCH commit 仅跟踪 `Thirdparty/g2o/CMakeLists.txt` 与 Barron patch，缺少 CMake 所列标准 g2o 源码和 `config.h.in`；还缺少被源码头文件引用的 Sophus 目录、README 声称包含的 YOLO 文件以及 CMake 无条件列出的部分示例。脚本从已审计 ORB-SLAM3 vendor 树非覆盖式补齐 g2o/Sophus，给旁支示例注册添加默认开启、但演示构建关闭的选项，并从 YOLO-Fastest 上游 1.0 COCO 目录下载缺失模型资产。CMake 与 `g2o`/CUDA `rgbd_tum` 编译已在本地工具环境验证通过。
- 顶层 DCH-SLAM 将 g2o 当作源码文件路径链接，而不是 CMake target 依赖；仅构建 `rgbd_tum` 时会误用旧的 `libg2o.so`，导致 Barron 符号未定义。`start.sh` 现先显式构建 `g2o` target，再构建 `rgbd_tum`；本地重复构建验证通过。
- Codex 工具 shell 对 GitHub/TUM 下载曾返回 `failed to open socket: Operation not permitted`。之后用户在宿主 Conda `cuda_134` 环境成功克隆 DCH-SLAM `main`，revision 为 `199a02517949afe8b4cd20aad8ab6e6ad51d3de5`。本地源码确认 `Settings.cc` 使用 `Camera1.fx` 和 `RGBD.DepthMapFactor`；CUDA 目标和前端调用链随后已完成构建与审阅，见 [build_report.md](build_report.md) 和 [slam_source_walkthrough.md](slam_source_walkthrough.md)。

## 当前构建与运行状态

- Prompt 指定 CPU fork 的 RGB-D target 已在本地隔离目录成功构建，DBoW2 已针对系统 OpenCV 4.10 重建；详见 `build_report.md` 和 `logs/`。
- NVCC 13.4、CUDA 目标编译与链接已验证，`cuobjdump` 确认 `sm_120` cubin，`ldd` 无缺失动态库。用户在 RTX 5070 / `cuda_134` 环境执行的一键运行 `20261017T082609Z` 完整处理 573 帧并正常退出，`status=success`、`exit_code=0`。
- TUM 数据归档已校验，最终输出 573 条相机轨迹、402 条关键帧轨迹、地图截图和 XY/3D 图；ATE RMSE 为 0.023424 m。证据与限制见 [最终报告](experiment4_report.md)。工具 shell 无 GPU 的限制不再作为用户宿主运行的未完成项。
