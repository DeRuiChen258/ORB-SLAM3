# ORB-SLAM3 RGB-D CUDA 演示

本项目依据 `Prompt/` 实现 TUM `fr1/desk` 离线 RGB-D SLAM 演示。CUDA 后端选用 [DCH-SLAM](https://github.com/datrich/DCH-SLAM)：它基于 ORB-SLAM3，提供 CUDA ORB 前端和 `rgbd_tum` 入口。

## 演示

下面的动图展示 TUM `fr1/desk` 序列运行时的稀疏地图与关键帧。GIF 取自地图窗口片段，已裁去桌面、文件管理器和终端中的本机路径信息。

![ORB-SLAM3 CUDA RGB-D map viewer demo](demo.gif)

## 一键运行

在已安装项目依赖的 Conda 环境中运行：

```bash
conda activate <your-environment>
cd ORB-SLAM3
./start.sh
```

脚本要求可用的 NVIDIA 驱动/GPU、CUDA Toolkit、CMake、Git、curl、Python 3、OpenCV/Eigen/Pangolin、Boost Serialization/OpenSSL 及 Python 的 NumPy/Matplotlib/Pillow。脚本先确认 NVIDIA 设备，再准备 DCH-SLAM 及缺失的第三方文件，之后获取公开 `fr1/desk` 数据集；不会退回 CPU，也不会运行系统包安装命令。缺依赖时会保留错误日志并退出。

默认编译架构为 `120`（RTX 50 系列）。可在运行前覆盖：

```bash
SLAM_CUDA_ARCHITECTURES=87 ./start.sh
SLAM_CUDA_ARCHITECTURES=89 ./start.sh
SLAM_BUILD_JOBS=8 ./start.sh
```

`start.sh` 每次在 `results/experiment4/runs/<UTC 时间>/` 新建目录，保留之前的日志和轨迹。环境变量 `SLAM_SETTINGS` 可指定相机 YAML；`SLAM_VIEWER_CAPTURE_TIMEOUT` 可调整 Pangolin 窗口检测时长。

运行时会打开两个独立窗口：`ORB-SLAM3: Map Viewer` 展示关键帧、地图点和当前相机位姿；`ORB-SLAM3: Current Frame` 展示当前图像。若只看到当前帧，可用 Alt+Tab 切换到地图窗口。程序运行时脚本会截取地图窗口；结束后在运行目录的 `figures/` 查看 `map_view.png` 和 XY/3D 轨迹图。

序列播放结束后程序自动退出。提前停止时，在启动终端按 Ctrl+C；中断记录可能没有完整轨迹。每次运行是否成功以该目录 `status.txt` 中的 `status=success` 和 `exit_code=0` 为准。

## 手动准备数据集

下载官方 [TUM fr1/desk 压缩包](https://webshare.cvg.cit.tum.de/g/rgbd/dataset/freiburg1/rgbd_dataset_freiburg1_desk.tgz)，文件大小为 344011403 字节（约 328 MiB）。将完整文件保存到项目内 `data/raw/rgbd_dataset_freiburg1_desk.tgz`，无需手动解压，再运行 `./start.sh`。脚本发现该文件后会跳过下载，继续校验、安全解压和图像关联。下载未完成的 `.part` 文件不作为数据归档使用。

## 工作流程与产物

`start.sh` 是项目入口，按顺序完成 CUDA/GPU 与依赖预检、准备 DCH-SLAM 源码和缺失资源、准备 TUM 数据并生成 RGB-D 时间戳关联、构建 `rgbd_tum`、运行序列，最后保存轨迹、日志和可视化。每次运行使用新的 UTC 时间戳目录，不覆盖之前的结果。

主要产物包括：

- `CameraTrajectory.txt`：逐帧相机位姿；`KeyFrameTrajectory.txt`：关键帧位姿，均为 TUM 轨迹格式。
- `figures/map_view.png`：Pangolin 地图窗口截图；`camera_trajectory_xy.png` 和 `camera_trajectory_3d.png`：轨迹图。
- `ATE` 结果：仅在提供 ground truth 且匹配、坐标对齐条件成立时计算。本项目使用 SE(3) 对齐，不拟合尺度。
- `start.log`、`status.txt` 和运行清单：用于检查命令状态、退出码和运行配置。

## 环境要求

已验收环境为 Ubuntu 26.04.1、RTX 5070 Laptop GPU、CUDA 13.4、OpenCV 4.10 和 Python 3.12。脚本还需要 NVIDIA 驱动/CUDA Toolkit、CMake、C++ 编译器、Git、curl、Eigen、Pangolin、Boost Serialization、OpenSSL，以及 Python 的 NumPy、Matplotlib 和 Pillow。其他发行版、显卡架构及依赖版本需按实际构建结果确认。

项目不会通过包管理器自动安装系统依赖，也不会在找不到 GPU 时切换成 CPU；缺少必需项时会报告错误并退出。默认 CUDA 架构为 120，可用 `SLAM_CUDA_ARCHITECTURES` 指定本机架构。

## 运行前检查

1. 确认 NVIDIA 驱动和 CUDA Toolkit 可用，且当前 shell 中的编译器与 Python 环境包含上述依赖。
2. 确认项目内有足够空间存放 TUM 数据集、构建文件和运行输出。
3. 若不希望脚本下载数据，按下一节将完整归档放在指定路径。
4. 在图形桌面运行以使用 Pangolin viewer 和截图功能；headless 环境不会提供相同的窗口截图体验。

## 目录

- `Prompt/`：原始阶段任务和验收标准。
- `source/ORB_SLAM3/`：Prompt 指定的 CPU-only fork，用作源码审计与构建 baseline。
- `source/DCH-SLAM/`：一键脚本获取的 CUDA 实现目录。
- `scripts/prepare_tum.py`：安全检查 TUM 归档、检查 RGB/depth 并建立四列时间戳关联。
- `scripts/extract_vocabulary.py`：只提取预期的 `ORBvoc.txt` 归档成员。
- `scripts/analyze_trajectory.py`：检查 TUM 轨迹、绘制 XY/3D 图，并在提供 ground truth 时执行不估计尺度的 SE(3) 对齐 ATE。
- `results/experiment4/`：审计、构建记录、报告和运行产物。

## CUDA 分支说明

Prompt 指定的 `aliaxam153/ORB_SLAM3` 没有 CUDA 前端，已按用户确认改用 DCH-SLAM。DCH-SLAM 还加入异步 YOLO 语义线程与自适应 Barron 鲁棒核，因此它和原版 ORB-SLAM3 的算法不完全相同，不能把这次运行解释成单独 CUDA 加速的公平对照。DCH-SLAM 的[公开仓库](https://github.com/datrich/DCH-SLAM)成熟度较低，且声明测试环境为 Ubuntu 20.04/22.04；本项目运行环境为 Ubuntu 26.04.1，需以实际构建和回放结果为准。

## 当前验收状态

验收通过。固定成功运行为 [`20261017T082609Z`](results/experiment4/runs/20261017T082609Z/status.txt)，由用户在 RTX 5070 Laptop GPU / CUDA 13.4 环境执行 `./start.sh`，完整处理 573 帧并以状态 0 退出。

| 产物/指标 | 结果 |
|---|---|
| 相机 / 关键帧位姿 | [573 条相机位姿](results/experiment4/runs/20261017T082609Z/CameraTrajectory.txt) / [402 条关键帧位姿](results/experiment4/runs/20261017T082609Z/KeyFrameTrajectory.txt) |
| 稀疏地图与关键帧 | [Pangolin 地图截图](results/experiment4/runs/20261017T082609Z/figures/map_view.png) |
| 完整相机轨迹 | [XY 图](results/experiment4/runs/20261017T082609Z/figures/camera_trajectory_xy.png) / [3D 图](results/experiment4/runs/20261017T082609Z/figures/camera_trajectory_3d.png) |
| ATE RMSE | 0.023424 m；573/573 真值配对，SE(3) 对齐，不拟合尺度 |
| 运行记录与解释 | [最终实验报告](results/experiment4/experiment4_report.md) / [源码导读](results/experiment4/slam_source_walkthrough.md) |
| 收尾校验 | [工程验收检查记录](results/experiment4/final_verification.md) |

成功日志仍有非致命 Qt timer 清理警告；完整结果和限制见实验报告。该次没有发生跟踪丢失，未单独强制测试地图重置恢复。单条序列结果不代表其他场景或 CUDA 加速比。

## 固定版本与恢复

当前可运行源码是上游 revision `199a02517949afe8b4cd20aad8ab6e6ad51d3de5` 加本地兼容性及生命周期修复。仅记录上游 SHA 无法还原最终版本，本地补丁与文件 SHA-256 清单保存在 [v2 验收版本目录](versions/v2_cuda_success_20261017/README.md)。

[版本说明](versions/README.md) 列出 v1 原版快照和 v2 成功版本快照、校验值与恢复方法。v2 用于当前 Linux/CUDA/OpenCV 环境恢复；数据集归档和完整构建缓存不重复打包，数据可按上文准备。换机器需先具备相应依赖，旧二进制和绝对路径不能直接视为通用安装包。

本演示只覆盖视觉 SLAM 定位与稀疏建图，不包含目标点规划、避障或运动控制，不称为自主导航。
