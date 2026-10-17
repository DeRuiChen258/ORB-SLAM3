# 工程收尾验证记录

日期：2026-10-17。固定验收运行：`20261017T082609Z`。收尾仅修改工程说明和版本记录，未修改已经成功运行的 `start.sh`、Python helper 或 C++/CUDA 算法。

| 检查 | 结果与依据 |
|---|---|
| 完整回放和退出 | 通过；原始 status.txt 为 success / exit_code=0，slam.log 连续包含 Frame 0..572 end、Shutdown 和两次轨迹保存 |
| 两份轨迹 | 通过；相机 573 条、关键帧 402 条，均 8 列有限数值、时间戳严格递增；最大四元数模长误差约 1.1e-7 |
| 真实可视化 | 通过；地图 1136×944、XY 1440×1080、3D 1620×1260 PNG 均可解析，已查看内容 |
| 单次 ATE | 本次运行报告为 0.023424 m，573/573 唯一最近邻配对，SE(3) 对齐且不拟合尺度；指标与最终文档一致 |
| 入口和 helper | bash -n start.sh 通过，入口有执行权限；4 个 Python helper 的 AST 解析通过 |
| CUDA 与链接库 | cuobjdump 列出 rgbd_tum.1.sm_120.cubin；ldd 无 not found |
| 源码补丁可恢复 | 5 个受跟踪文件的完整 git diff 已导出；从固定上游 revision 提取的临时副本通过 git apply --check，应用后与当前源码逐字节一致 |
| v1 完整性 | 原归档 SHA-256 仍为 9262c73cd838c59a0b989d99b180528d542909503a8b097caf58cca3d6c3c032 |
| v2 快照 | gzip/tar 全部成员已读取，普通文件流式 SHA-256 与 files.sha256 对照通过，路径无绝对路径或 .. 穿越；外层归档另有 .sha256 文件 |
| 文档引用 | 根 README/TASK、版本说明及最终实验文档的本地 Markdown 目标均存在；最终归档包含已完成的任务状态 |

源码补丁 SHA-256：`7b6faf61d15ef92bea68e84fbfa49c09bfecd42a98017e9c8ae4d8432cd1792f`。文件、环境与产物清单见 [v2 版本目录](../../versions/v2_cuda_success_20261017/README.md)，归档外层 SHA-256 见 [校验文件](../../versions/v2_cuda_success_20261017.tar.gz.sha256)。

本次使用用户终端已有成功日志完成验收，没有从无 GPU 访问权限的工具 shell 重跑 SLAM。没有强制触发 LOST/新 map、执行 GPU sanitizer、测试跨机器安装或开展 CPU/CUDA 性能基准。非致命 Qt 警告仍保留，全部适用范围见 [最终实验报告](experiment4_report.md)。
