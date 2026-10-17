# 实验四：ORB-SLAM3 RGB-D CUDA 演示

## 最终结论

验收通过。用户在 `cuda_134` / RTX 5070 Laptop GPU 环境执行根目录 `./start.sh`，成功运行固定为 **`20261017T082609Z`**。程序完整处理 573 帧，导出两份轨迹与地图/轨迹图，并正常退出；[status.txt](runs/20261017T082609Z/status.txt) 记录 `status=success`、`exit_code=0`。

| 指标 | 本次实测 |
|---|---:|
| 已处理 RGB-D 帧 | 573，日志帧 ID 连续为 0..572 |
| 相机位姿 / 关键帧位姿 | 573 / 402 |
| ATE RMSE | 0.023424 m |
| ATE mean / median / p95 / max | 0.020784 / 0.018131 / 0.040994 / 0.062791 m |
| 真值有效配对 | 573 / 573 |
| TrackRGBD 平均 / 中位耗时 | 39.2928 / 43.1605 ms |

耗时来自 `rgbd_tum` 对单次 `TrackRGBD` 调用的计时，不包含读图与回放等待；它不是端到端吞吐量或 CUDA 加速比。以上精度仅描述这一次 `fr1/desk` 运行。

## 目标与范围

依据 `Prompt/`，完成 TUM `rgbd_dataset_freiburg1_desk` 离线 RGB-D 视觉定位与稀疏建图，生成真实轨迹、地图截图及源码导读。本工程没有路径规划、动态避障或机器人运动控制模块，验收范围为视觉 SLAM 演示。

## 代码与环境

- Prompt 指定的 CPU-only fork 为 [aliaxam153/ORB_SLAM3](https://github.com/aliaxam153/ORB_SLAM3)。本地完成审计与 RGB-D baseline 构建；其归档 SHA-256 为 `76660dbe2a090d2fb98ed639c0dbf5aaa51abc4cc06106e2027e0a52cb0efaa1`。没有运行 CPU 性能对照。
- 用户确认采用 [datrich/DCH-SLAM](https://github.com/datrich/DCH-SLAM) CUDA ORB 前端，上游 revision 为 `199a02517949afe8b4cd20aad8ab6e6ad51d3de5`。最终代码还包含本地 CMake、LK 输入/边界、帧生命周期及线程关闭修复，完整差异与校验清单见 [v2 固定版本](../../versions/v2_cuda_success_20261017/README.md)。仅上游 SHA 不能还原本项目代码。
- 宿主 GPU 为 NVIDIA GeForce RTX 5070 Laptop GPU，CUDA Toolkit 13.4 / NVCC 13.4.92，CUDA 编译架构 `120`。GPU 与编译器输出见 [start.log](runs/20261017T082609Z/start.log)。驱动版本未在这次日志中采集。
- Ubuntu 26.04.1、GNU C++ 15.2、CMake 3.31.6、OpenCV 4.10、Eigen 3.4、Python 3.12；Pangolin v0.6 隔离安装在项目内 `build/deps`。DCH 按上游 CMake 使用 C++14，未为工程收尾变更其语言标准。
- CUDA 开关为 `USE_CUDA_FRONTEND=ON`，可执行文件包含 `sm_120` cubin，`ldd` 没有缺失库。构建步骤、vendor 补齐与日志见 [build_report.md](build_report.md)。

DCH-SLAM 额外包含异步 YOLO 与 Barron 鲁棒核；CUDA 实现与 Prompt 指定的 CPU fork 存在算法差异。不能把本次结果解释为单独替换 CUDA 的公平对照。当前工具 shell 不能访问 GPU，运行证据来自用户终端落盘日志及产物。

## 数据与设置

- 数据归档为 `data/raw/rgbd_dataset_freiburg1_desk.tgz`，SHA-256：`e983d6830916e66dc4a46a71368046b149b283de87769690e7aa4e0b9483530c`；下载与逐项校验见 [本次数据报告](runs/20261017T082609Z/dataset_report.md)。
- 613 张 RGB、595 张 depth、2335 个 ground-truth 位姿。`associations/fr1_desk.txt` 有 573 组有效配对，最大 RGB-depth 时间差 0.019742 s；四列、时间戳、文件存在性及图像/深度抽样均通过。
- 相机设置为 `source/DCH-SLAM/Examples/RGB-D/TUM1.yaml`：640×480、30 FPS，焦距 `517.306408 / 516.469215`，主点 `318.643040 / 255.313989`，`Camera.RGB=1`、`RGBD.DepthMapFactor=5000`。深度 PNG 按 5000 换算为米。
- 轨迹检查：两份文件均为 8 列有限数值、严格递增时间戳、有效单位四元数；相机轨迹没有重复相邻位置。轨迹时间范围为 `1305031453.359684` 至 `1305031473.196069`。
- ATE 使用唯一最近邻时间戳关联，容差 0.020 s；573/573 配对，时间差中位 0.001710 s、最大 0.013142 s。对估计轨迹执行 SE(3) 刚体 Umeyama 对齐，不拟合尺度。详细算法与质量检查见 [visualization_report.md](runs/20261017T082609Z/figures/visualization_report.md)。

## 运行命令与产物

已执行的一键入口：

```bash
conda activate cuda_134
cd "/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB"
./start.sh
```

脚本在 `results/experiment4/runs/20261017T082609Z/` 中运行 RGB-D 程序，四个参数依次是 `data/processed/ORBvoc.txt`、DCH 的 `TUM1.yaml`、解压后的 TUM 序列目录及 `associations/fr1_desk.txt`；实际绝对路径见 [run_manifest.md](runs/20261017T082609Z/run_manifest.md)。程序在该工作目录导出两份 TUM 轨迹。完整回放、Shutdown、轨迹保存和状态见 [slam.log](runs/20261017T082609Z/slam.log) 与 [start.log](runs/20261017T082609Z/start.log)。

| 产物 | 位置 |
|---|---|
| 相机轨迹 | [CameraTrajectory.txt](runs/20261017T082609Z/CameraTrajectory.txt) |
| 关键帧轨迹 | [KeyFrameTrajectory.txt](runs/20261017T082609Z/KeyFrameTrajectory.txt) |
| Pangolin 稀疏地图截图 | [map_view.png](runs/20261017T082609Z/figures/map_view.png) |
| XY / 3D 完整轨迹 | [camera_trajectory_xy.png](runs/20261017T082609Z/figures/camera_trajectory_xy.png) / [camera_trajectory_3d.png](runs/20261017T082609Z/figures/camera_trajectory_3d.png) |
| 轨迹评估 | [visualization_report.md](runs/20261017T082609Z/figures/visualization_report.md) |
| 构建与输入清单 | [build_report.md](runs/20261017T082609Z/build_report.md) / [run_manifest.md](runs/20261017T082609Z/run_manifest.md) |

地图截图是在回放期间超过 80 帧后截取的真实 Pangolin 窗口，包含稀疏点、关键帧和相机视锥；它不是序列结束时的最终地图或可复用地图文件。XY/3D 图由完整的 573 条相机位姿生成，估计轨迹使用与 ATE 相同的 SE(3) 对齐变换。

## 源码流程

`rgbd_tum.cc → System::TrackRGBD → Tracking::GrabImageRGBD → Frame/ORBextractor → Tracking/LocalMapping/LoopClosing → SaveTrajectoryTUM`。DCH 在关键帧 ORB 检测、方向与描述子计算中使用 CUDA；灰度/深度处理、LK、动态掩码、几何与后端保留 CPU 实现，YOLO 使用 OpenCV CPU backend。调用点、数据传输与模块图见 [slam_source_walkthrough.md](slam_source_walkthrough.md)。

## 验收与版本固化

| 验收项 | 状态 | 证据 |
|---|---|---|
| 仓库、环境与 RGB-D 构建入口审计 | 通过 | [repository_audit.md](repository_audit.md)、[build_report.md](build_report.md) |
| CUDA 构建与宿主 GPU 回放 | 通过 | USE_CUDA_FRONTEND=ON，sm_120 产物及成功运行日志 |
| 数据、关联、相机参数和深度尺度校验 | 通过 | [dataset_report.md](runs/20261017T082609Z/dataset_report.md) |
| 完整序列、正常退出与两份有效轨迹 | 通过 | 573 帧、573/402 条位姿，exit_code=0 |
| 真实地图截图与 XY/3D 轨迹图 | 通过 | 本次运行 figures/，图片已逐项检查 |
| 有真值的 SE(3) ATE | 通过（单次轨迹） | 573 对，RMSE 0.023424 m |
| 根目录 start.sh 一键入口 | 通过 | 用户终端完整执行；输入、日志和产物落盘 |
| 源码导读、复现说明与边界说明 | 通过 | 本报告、根 README 及源码导读 |

验收版本为 [v2_cuda_success_20261017](../../versions/v2_cuda_success_20261017/README.md)：包含上游与本地补丁标识、代码和结果的文件哈希及恢复快照。v1 原版快照及历次失败运行保留在原位置，见 [版本说明](../../versions/README.md)。文件、补丁恢复与快照检查见 [工程收尾验证记录](final_verification.md)。

## 已知问题与适用范围

- 成功日志仍包含 `QObject::killTimer` / `QObject::~QObject` 跨线程 timer 清理警告，以及 QSocketNotifier 提示；本次均为非致命，程序正常退出。旧版退出崩溃的 worker/Viewer 等待与 join 修复保留；未宣称所有 Qt 生命周期问题已消除。
- 本次没有记录 LK 匹配不足、local-map 跟踪失败或第二张地图创建。此前 `20261017T081837Z` 在新地图切换处崩溃的空帧保护已进入最终源码，但成功序列没有单独强制触发该恢复分支；GPU 内存/竞态 sanitizer 也未执行。
- `20261017T080812Z` 虽导出轨迹，但状态 139；`20261017T081837Z` 在约第 259 帧附近状态 139 且无轨迹。它们是调试历史，不作为最终成功证据，详见 `.agent/failures.md`。
- 地图窗口截图依赖 X11、xwininfo 与 ImageMagick import，Wayland/headless 尚未验证。RealSense 缺失提示不影响离线 TUM RGB-D 目标，本工程没有验证实时相机。
- DCH 原始 checkout 的缺失 vendor、额外示例和 YOLO 资产已在当前工程补齐；直接换成干净上游目录会丢失本地修复，应使用固定快照或补丁。迁移到其他系统需重新准备依赖和构建。
- 本次只验证单条静态序列和单次精度；未测 CUDA 相对 CPU 的加速比、动态场景鲁棒性、回环/重定位覆盖率或导航能力。
