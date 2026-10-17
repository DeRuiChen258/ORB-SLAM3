# TUM fr1/desk 数据准备状态

## 状态：数据准备与端到端 SLAM 验收通过

最终成功运行为 [runs/20261017T082609Z](runs/20261017T082609Z/dataset_report.md)，完整处理 573 帧并正常退出；详细结果见 [experiment4_report.md](experiment4_report.md)。

- 目标序列：`rgbd_dataset_freiburg1_desk`
- 数据来源：TUM RGB-D 数据集；修正后的地址为 `https://webshare.cvg.cit.tum.de/g/rgbd/dataset/freiburg1/rgbd_dataset_freiburg1_desk.tgz`。
- 用户运行 `runs/20261017T073611Z/` 通过 CUDA 构建和 YOLO 准备后，旧地址因缺少 `/g/` 返回 404。随后下载并由 `runs/20261017T074304Z/dataset_report.md`、`runs/20261017T074434Z/dataset_report.md` 验证了完整归档。
- 归档文件：`data/raw/rgbd_dataset_freiburg1_desk.tgz`；SHA-256 `e983d6830916e66dc4a46a71368046b149b283de87769690e7aa4e0b9483530c`。
- 解压目录：`data/raw/rgbd_dataset_freiburg1_desk/`；613 RGB、595 depth、2335 ground-truth 位姿；首/中/末图像分辨率及深度抽样通过。
- association：`associations/fr1_desk.txt`；573 组有效配对，最大时间差 0.019742 s；四列及引用图像逐行检查通过。
- 相机设置：DCH-SLAM 自带 `source/DCH-SLAM/Examples/RGB-D/TUM1.yaml` 包含 fr1 内参 `Camera1.fx=517.306408`、640×480、30 FPS、`Camera.RGB=1` 和 `RGBD.DepthMapFactor=5000`。其键名由 DCH `Settings.cc` 读取；`start.sh` 按该 schema 校验后才会运行。

## 下一步

如需重建数据，可将完整压缩包保存为 `data/raw/rgbd_dataset_freiburg1_desk.tgz` 后运行 `./start.sh`。脚本会复用归档并检查路径、关联和首/中/末 RGB-depth 配对；本项目当前归档与关联均已有真实检查记录。
