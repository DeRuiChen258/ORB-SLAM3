# Version snapshots

## v2 CUDA 成功验收版本（当前交付）

- 验收运行：`20261017T082609Z`；573 帧、573/402 条相机/关键帧位姿、ATE RMSE 0.023424 m、退出码 0。
- 恢复归档：[v2_cuda_success_20261017.tar.gz](v2_cuda_success_20261017.tar.gz)。
- 归档校验：[v2_cuda_success_20261017.tar.gz.sha256](v2_cuda_success_20261017.tar.gz.sha256)，在项目根目录运行 `sha256sum --check "versions/v2_cuda_success_20261017.tar.gz.sha256"`。
- [版本说明与恢复步骤](v2_cuda_success_20261017/README.md)、[上游源码补丁](v2_cuda_success_20261017/DCH-SLAM.patch)、[环境与结果清单](v2_cuda_success_20261017/release_manifest.json)、[逐文件校验](v2_cuda_success_20261017/files.sha256)。
- 快照包含当前修复源码、依赖/模型/词袋归档、启动脚本、说明文档与运行记录；公开副本已脱敏本机用户名路径并排除 `Prompt/`、`docs/`、内部 agent 状态与任务计划，用于原 Linux 依赖环境恢复。TUM 数据、完整构建缓存与 CPU baseline 源码不重复打包；绝对路径及二进制 ABI 限制见版本说明。
- v1、已有数据和所有成功/失败记录继续保留。归档及其外层 SHA-256 文件应一起保存；索引中的归档不会再次递归包含在自身快照里。

## v1 before map and trajectory visualization

- Archive: `v1_before_map_visualization_20261017.tar.gz`
- SHA-256: `ad3b5d64894052dd017bbd677acd7cb3b55bae0428c1b001c484ee318b9c1730`
- Includes the one-click runner, helper scripts, experiment reports and run logs; the public archive excludes `Prompt/`, `docs/`, internal agent state and task plans, DCH-SLAM source/build tree, RGB-D association, and original TUM archive.
- This archive is a point-in-time copy made before the map/trajectory visualization changes. Existing workspace files and run outputs remain in place.

To inspect without extracting over the current workspace:

```bash
mkdir -p /tmp/slam_orb_v1_snapshot
tar -xzf versions/v1_before_map_visualization_20261017.tar.gz -C /tmp/slam_orb_v1_snapshot
```
