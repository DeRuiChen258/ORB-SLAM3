# TUM fr1/desk 数据准备报告

## 输入

- 来源 URL：https://webshare.cvg.cit.tum.de/g/rgbd/dataset/freiburg1/rgbd_dataset_freiburg1_desk.tgz
- 序列目录：`/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/data/raw/rgbd_dataset_freiburg1_desk`
- 归档 SHA-256：`e983d6830916e66dc4a46a71368046b149b283de87769690e7aa4e0b9483530c`
- association 生成/复用方式：复用已有文件 /home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/associations/fr1_desk.txt
- 最大时间差阈值：0.020 s

## 数据检查

- RGB 时间戳条目：613；范围 `1305031452.791720` 至 `1305031473.196069`
- Depth 时间戳条目：595；范围 `1305031453.374112` 至 `1305031473.190828`
- Ground-truth 条目：2335
- 首/中/末抽查 RGB 与 Depth：`rgb/1305031453.359684.png` / `depth/1305031453.374112.png`, `rgb/1305031463.659766.png` / `depth/1305031463.646147.png`, `rgb/1305031473.196069.png` / `depth/1305031473.190828.png`
- 抽样 RGB 图像：640×480；抽查 RGB/Depth 分辨率配对一致
- Depth 抽样格式 / mode：PNG / I;16
- Depth 非零原始值范围（首/中/末抽样）：2287 至 10128
- Depth 换算因子：5000；抽查有效深度约 0.457 至 2.026 m

## Association

- 文件：`/home/public/Workspace/Code/Project/Embodied_AI/Visual/SLAM_ORB/associations/fr1_desk.txt`
- 配对数：573；RGB 丢弃 40；Depth 丢弃 22
- 实际时间差：median 0.011648 s，max 0.019742 s
- 四列及引用图像：逐行检查通过
- Depth map factor 与设置：本次使用 5000，对应 TUM PNG 的原始深度单位
