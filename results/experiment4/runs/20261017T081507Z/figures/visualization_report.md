# 轨迹可视化与评估

## 输入与图表

- 估计轨迹：`/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/results/experiment4/runs/20261017T081507Z/CameraTrajectory.txt`
- Ground truth：`/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/data/raw/rgbd_dataset_freiburg1_desk/groundtruth.txt`
- 位姿条目：573；时间范围 `1305031453.359684` 至 `1305031473.196069`
- XY 轨迹图：`camera_trajectory_xy.png`
- 3D 轨迹图：`camera_trajectory_3d.png`
- 绘图配对：估计轨迹 573 条，真值 2335 条，匹配 573 条；绘图中估计轨迹按 ATE 对齐变换，真值为原始坐标。

## 轨迹质量检查

- 估计坐标范围：X 2.176480 m，Y 1.209939 m，Z 1.175341 m
- 相邻位姿位移：median 0.017324 m，p95 0.034002 m，max 0.061884 m
- 小于 1e-9 m 的重复相邻位置：0
- 输入位姿检查：8 列、有限数值、有效四元数及时间戳严格递增均通过

## ATE

- 对齐方法：SE(3) 刚体 Umeyama 对齐（不估计尺度；RGB-D 公制尺度）
- 时间戳策略：唯一最近邻，容差 0.020 s
- 有效配对数：573 / 估计 573，真值 2335
- 时间差：median 0.001710 s，max 0.013142 s
- ATE RMSE：0.026562 m
- ATE mean / median / p95 / max：0.024193 / 0.023173 / 0.042679 / 0.073411 m

ATE 只描述这次单条 fr1/desk 回放的估计轨迹。该值依赖上面记录的时间戳关联和 SE(3) 对齐，不代表其他序列或导航能力。
