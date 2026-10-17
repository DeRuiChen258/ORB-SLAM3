#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$ROOT_DIR/source/DCH-SLAM"
BUILD_DIR="$ROOT_DIR/build/dch-cuda"
RAW_DIR="$ROOT_DIR/data/raw"
PROCESSED_DIR="$ROOT_DIR/data/processed"
SEQUENCE_NAME="rgbd_dataset_freiburg1_desk"
DATASET_URL="https://webshare.cvg.cit.tum.de/g/rgbd/dataset/freiburg1/$SEQUENCE_NAME.tgz"
SEQUENCE_DIR="$RAW_DIR/$SEQUENCE_NAME"
DATASET_ARCHIVE="$RAW_DIR/$SEQUENCE_NAME.tgz"
ASSOCIATION_FILE="$ROOT_DIR/associations/fr1_desk.txt"
RESULTS_DIR="$ROOT_DIR/results/experiment4/runs"
CUDA_ARCHITECTURES="${SLAM_CUDA_ARCHITECTURES:-120}"
BUILD_JOBS="${SLAM_BUILD_JOBS:-4}"
VIEWER_CAPTURE_TIMEOUT="${SLAM_VIEWER_CAPTURE_TIMEOUT:-35}"
MAP_CAPTURE_MIN_FRAMES=80

if [[ ! "$CUDA_ARCHITECTURES" =~ ^[0-9]+(;[0-9]+)*$ ]]; then
  echo "SLAM_CUDA_ARCHITECTURES 必须是数字架构列表，例如 120 或 87;120。" >&2
  exit 2
fi
if [[ ! "$BUILD_JOBS" =~ ^[1-9][0-9]*$ ]]; then
  echo "SLAM_BUILD_JOBS 必须为正整数。" >&2
  exit 2
fi
if [[ ! "$VIEWER_CAPTURE_TIMEOUT" =~ ^[1-9][0-9]*$ ]]; then
  echo "SLAM_VIEWER_CAPTURE_TIMEOUT 必须为正整数。" >&2
  exit 2
fi

mkdir -p -- "$RESULTS_DIR"
RUN_STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
RUN_DIR="$RESULTS_DIR/$RUN_STAMP"
suffix=0
while [[ -e "$RUN_DIR" ]]; do
  suffix=$((suffix + 1))
  RUN_DIR="$RESULTS_DIR/${RUN_STAMP}_$suffix"
done
mkdir -- "$RUN_DIR"
exec > >(tee -a "$RUN_DIR/start.log") 2>&1

on_exit() {
  local status=$?
  if [[ -n "${RUN_DIR:-}" && -d "$RUN_DIR" ]]; then
    if ((status == 0)); then
      printf 'status=success\nexit_code=0\n' > "$RUN_DIR/status.txt"
    else
      printf 'status=failed\nexit_code=%s\n' "$status" > "$RUN_DIR/status.txt"
    fi
  fi
}
trap on_exit EXIT

fail() {
  echo "错误：$*" >&2
  exit 2
}

echo "run_dir=$RUN_DIR"
echo "cuda_architectures=$CUDA_ARCHITECTURES"
echo "build_jobs=$BUILD_JOBS"

command -v nvcc >/dev/null 2>&1 || fail "未找到 nvcc；请在已配置 CUDA Toolkit 的环境中运行。"
command -v nvidia-smi >/dev/null 2>&1 || fail "未找到 nvidia-smi；无法确认 CUDA 设备。"
command -v cmake >/dev/null 2>&1 || fail "未找到 cmake。"
command -v python3 >/dev/null 2>&1 || fail "未找到 python3。"
command -v grep >/dev/null 2>&1 || fail "未找到 grep。"
nvidia-smi -L || fail "NVIDIA 驱动未连接可用 GPU；本次不退回 CPU。"
nvcc --version

if [[ ! -e "$SOURCE_DIR" ]]; then
  command -v git >/dev/null 2>&1 || fail "未找到 git，且 source/DCH-SLAM 尚不存在。"
  mkdir -p -- "$(dirname -- "$SOURCE_DIR")"
  git clone --depth 1 --branch main https://github.com/datrich/DCH-SLAM.git "$SOURCE_DIR"
fi
[[ -f "$SOURCE_DIR/CMakeLists.txt" ]] || fail "CUDA 源码目录不完整：$SOURCE_DIR"
grep -q 'USE_CUDA_FRONTEND' "$SOURCE_DIR/CMakeLists.txt" || fail "源码没有声明 USE_CUDA_FRONTEND。"
CUDA_KERNEL="$(find "$SOURCE_DIR/src/cuda" -type f -name '*.cu' -print -quit 2>/dev/null || true)"
[[ -n "$CUDA_KERNEL" ]] || fail "源码没有找到 CUDA .cu 前端实现。"

if [[ -d "$SOURCE_DIR/.git" ]]; then
  SOURCE_REVISION="$(git -C "$SOURCE_DIR" rev-parse HEAD)"
else
  SOURCE_REVISION="unknown (local source snapshot without .git)"
fi
echo "source_revision=$SOURCE_REVISION"

# DCH-SLAM links DBoW2 from a fixed local path. Its published tree may omit that
# directory, so reuse the already audited ORB-SLAM3 DBoW2 sources/library if needed.
DBOW2_DIR="$SOURCE_DIR/Thirdparty/DBoW2"
if [[ ! -d "$DBOW2_DIR" ]]; then
  ORIGINAL_DBOW2_DIR="$ROOT_DIR/source/ORB_SLAM3/Thirdparty/DBoW2"
  [[ -d "$ORIGINAL_DBOW2_DIR" ]] || fail \
    "DCH-SLAM 缺少 Thirdparty/DBoW2，且本项目没有可复用的 ORB-SLAM3 DBoW2。"
  mkdir -p -- "$SOURCE_DIR/Thirdparty"
  cp -a -- "$ORIGINAL_DBOW2_DIR" "$DBOW2_DIR"
  echo "dbow2_dependency=copied from $ORIGINAL_DBOW2_DIR"
fi
[[ -s "$DBOW2_DIR/lib/libDBoW2.so" ]] || fail \
  "缺少 DBoW2 共享库：$DBOW2_DIR/lib/libDBoW2.so"

# This DCH-SLAM revision tracks its g2o build file and Barron additions but
# omits the upstream g2o source tree. Fill only missing files from the audited
# ORB-SLAM3 vendor copy; keep DCH-SLAM's CMakeLists and Barron implementation.
G2O_DIR="$SOURCE_DIR/Thirdparty/g2o"
ORIGINAL_G2O_DIR="$ROOT_DIR/source/ORB_SLAM3/Thirdparty/g2o"
[[ -f "$G2O_DIR/CMakeLists.txt" ]] || fail "DCH-SLAM 缺少 Thirdparty/g2o/CMakeLists.txt。"
if [[ ! -f "$G2O_DIR/config.h.in" || ! -f "$G2O_DIR/g2o/core/base_vertex.h" ]]; then
  [[ -f "$ORIGINAL_G2O_DIR/config.h.in" && -f "$ORIGINAL_G2O_DIR/g2o/core/base_vertex.h" ]] || fail \
    "DCH-SLAM g2o 源码不完整，且本项目没有可复用的 ORB-SLAM3 g2o 源码。"
  cp -a --update=none -- "$ORIGINAL_G2O_DIR/." "$G2O_DIR/"
  echo "g2o_dependency=filled missing files from $ORIGINAL_G2O_DIR; preserved DCH-SLAM-specific files"
fi
[[ -f "$G2O_DIR/config.h.in" && -f "$G2O_DIR/g2o/core/base_vertex.h" ]] || fail \
  "g2o 依赖补齐失败：config.h.in 或 core/base_vertex.h 仍缺失。"
[[ -f "$G2O_DIR/g2o/core/robust_kernel_barron.cpp" && \
   -f "$G2O_DIR/g2o/core/robust_kernel_barron.h" ]] || fail \
  "DCH-SLAM g2o 缺少 Barron 鲁棒核实现。"

# This DCH-SLAM checkout also omits Sophus, although its public headers include
# it directly. Reuse only the audited Sophus header tree and preserve any files
# already present in the DCH checkout.
SOPHUS_DIR="$SOURCE_DIR/Thirdparty/Sophus"
ORIGINAL_SOPHUS_DIR="$ROOT_DIR/source/ORB_SLAM3/Thirdparty/Sophus"
if [[ ! -f "$SOPHUS_DIR/sophus/geometry.hpp" ]]; then
  [[ -f "$ORIGINAL_SOPHUS_DIR/sophus/geometry.hpp" ]] || fail \
    "DCH-SLAM 缺少 Thirdparty/Sophus，且本项目没有可复用的 Sophus 头文件。"
  mkdir -p -- "$SOPHUS_DIR/sophus"
  cp -a --update=none -- "$ORIGINAL_SOPHUS_DIR/sophus/." "$SOPHUS_DIR/sophus/"
  echo "sophus_dependency=filled missing headers from $ORIGINAL_SOPHUS_DIR/sophus"
fi
[[ -f "$SOPHUS_DIR/sophus/geometry.hpp" && -f "$SOPHUS_DIR/sophus/se3.hpp" ]] || fail \
  "Sophus 依赖补齐失败：geometry.hpp 或 se3.hpp 仍缺失。"
python3 "$ROOT_DIR/scripts/prepare_dch_source.py" --source "$SOURCE_DIR"

mkdir -p -- "$PROCESSED_DIR"
VOCABULARY="$PROCESSED_DIR/ORBvoc.txt"
if [[ ! -s "$VOCABULARY" ]]; then
  VOCABULARY_ARCHIVE="$SOURCE_DIR/Vocabulary/ORBvoc.txt.tar.gz"
  if [[ ! -f "$VOCABULARY_ARCHIVE" ]]; then
    VOCABULARY_ARCHIVE="$ROOT_DIR/source/ORB_SLAM3/Vocabulary/ORBvoc.txt.tar.gz"
  fi
  [[ -f "$VOCABULARY_ARCHIVE" ]] || fail "找不到 ORBvoc.txt.tar.gz。"
  python3 "$ROOT_DIR/scripts/extract_vocabulary.py" \
    --archive "$VOCABULARY_ARCHIVE" --output "$VOCABULARY"
fi

SETTINGS="${SLAM_SETTINGS:-}"
if [[ -z "$SETTINGS" ]]; then
  SETTINGS="$SOURCE_DIR/Examples/RGB-D/TUM1.yaml"
fi
[[ -f "$SETTINGS" ]] || fail "找不到 fr1/desk 相机配置：$SETTINGS"
grep -Eq '^Camera1\.fx:[[:space:]]*517\.306408' "$SETTINGS" || \
  fail "配置的 Camera1.fx 与 DCH-SLAM fr1/desk 参数不一致。"
grep -Eq '^RGBD\.DepthMapFactor:[[:space:]]*5000([.]0)?([[:space:]]|$)' "$SETTINGS" || \
  fail "配置的 RGBD.DepthMapFactor 不是 TUM PNG 深度因子 5000。"
grep -Eq '^Camera\.RGB:[[:space:]]*1([[:space:]]|$)' "$SETTINGS" || \
  fail "配置未声明 TUM fr1 的 RGB 通道顺序。"

# The DCH-SLAM README says these YOLO files are included, but the published
# checkout omits them. Fetch the exact model family expected by System.cc.
YOLO_DIR="$SOURCE_DIR/Thirdparty/YOLO"
mkdir -p -- "$YOLO_DIR"
download_if_missing() {
  local output_path="$1"
  local url="$2"
  if [[ ! -s "$output_path" ]]; then
    command -v curl >/dev/null 2>&1 || fail "下载缺失文件需要 curl：$output_path"
    curl --fail --location --retry 2 --output "$output_path.part" "$url"
    mv -- "$output_path.part" "$output_path"
  fi
}
YOLO_BASE_URL="https://raw.githubusercontent.com/dog-qiuqiu/Yolo-Fastest/master/ModelZoo/yolo-fastest-1.0_coco"
YOLO_NAMES_URL="https://raw.githubusercontent.com/dog-qiuqiu/Yolo-Fastest/master/ModelZoo/yolo-fastest-1.1_coco/coco.names"
download_if_missing "$YOLO_DIR/coco.names" "$YOLO_NAMES_URL"
download_if_missing "$YOLO_DIR/yolo-fastest-xl.cfg" "$YOLO_BASE_URL/yolo-fastest-xl.cfg"
download_if_missing "$YOLO_DIR/yolo-fastest-xl.weights" "$YOLO_BASE_URL/yolo-fastest-xl.weights"
[[ "$(wc -l < "$YOLO_DIR/coco.names")" -eq 80 ]] || fail "YOLO coco.names 不是 80 类标签文件。"
grep -Eq '^width[[:space:]]*=[[:space:]]*320[[:space:]]*$' "$YOLO_DIR/yolo-fastest-xl.cfg" || \
  fail "YOLO 配置输入宽度不是 320。"
grep -Eq '^height[[:space:]]*=[[:space:]]*320[[:space:]]*$' "$YOLO_DIR/yolo-fastest-xl.cfg" || \
  fail "YOLO 配置输入高度不是 320。"
grep -Eq '^classes[[:space:]]*=[[:space:]]*80[[:space:]]*$' "$YOLO_DIR/yolo-fastest-xl.cfg" || \
  fail "YOLO 配置类别数不是 80。"
YOLO_NAMES_SHA256="$(sha256sum "$YOLO_DIR/coco.names" | awk '{print $1}')"
YOLO_CFG_SHA256="$(sha256sum "$YOLO_DIR/yolo-fastest-xl.cfg" | awk '{print $1}')"
YOLO_WEIGHTS_SHA256="$(sha256sum "$YOLO_DIR/yolo-fastest-xl.weights" | awk '{print $1}')"
[[ "$(wc -c < "$YOLO_DIR/yolo-fastest-xl.weights")" -ge 3000000 ]] || \
  fail "YOLO 权重文件过小，可能下载不完整。"

mkdir -p -- "$(dirname -- "$BUILD_DIR")"
cmake_args=(
  -S "$SOURCE_DIR"
  -B "$BUILD_DIR"
  -DUSE_CUDA_FRONTEND=ON
  -DDCH_BUILD_EXTRA_EXAMPLES=OFF
  -DCMAKE_BUILD_TYPE=Release
  "-DCMAKE_CUDA_ARCHITECTURES=$CUDA_ARCHITECTURES"
)
PANGOLIN_CONFIG="$ROOT_DIR/build/deps/lib/cmake/Pangolin"
if [[ -d "$PANGOLIN_CONFIG" ]]; then
  cmake_args+=("-DPangolin_DIR=$PANGOLIN_CONFIG")
fi
cmake "${cmake_args[@]}"
grep -qx 'USE_CUDA_FRONTEND:BOOL=ON' "$BUILD_DIR/CMakeCache.txt" || \
  fail "CMakeCache 未确认 USE_CUDA_FRONTEND=ON。"
grep -qx 'DCH_BUILD_EXTRA_EXAMPLES:BOOL=OFF' "$BUILD_DIR/CMakeCache.txt" || \
  fail "CMakeCache 未确认已跳过 DCH checkout 缺失的额外示例。"
grep -q '^CMAKE_CUDA_COMPILER:FILEPATH=' "$BUILD_DIR/CMakeCache.txt" || \
  fail "CMake 未配置 CUDA 编译器。"
# DCH-SLAM links g2o by a file path rather than a CMake target dependency.
# Build its Barron-enabled library before linking the main SLAM library.
cmake --build "$BUILD_DIR" --target g2o --parallel "$BUILD_JOBS"
cmake --build "$BUILD_DIR" --target rgbd_tum --parallel "$BUILD_JOBS"

CUDA_ARCHIVE="$(find "$BUILD_DIR" -type f -name 'liborbslam3_cuda.a' -size +0c -print -quit)"
[[ -n "$CUDA_ARCHIVE" ]] || fail "构建产物中没有非空 liborbslam3_cuda.a。"
SLAM_BINARY="$SOURCE_DIR/Examples/RGB-D/rgbd_tum"
[[ -x "$SLAM_BINARY" ]] || fail "RGB-D 可执行文件不存在或不可执行：$SLAM_BINARY"
echo "cuda_frontend_archive=$CUDA_ARCHIVE"
echo "rgbd_binary=$SLAM_BINARY"

mkdir -p -- "$RAW_DIR"
if [[ ! -f "$DATASET_ARCHIVE" ]]; then
  command -v curl >/dev/null 2>&1 || fail "下载 TUM 数据集需要 curl。"
  echo "dataset_url=$DATASET_URL"
  echo "dataset_archive=$DATASET_ARCHIVE"
  if ! curl --fail --location --retry 2 --continue-at - \
    --output "$DATASET_ARCHIVE.part" \
    "$DATASET_URL"; then
    fail "TUM 下载失败。可用浏览器下载 $DATASET_URL，将完整压缩包保存为 $DATASET_ARCHIVE（无需解压），再运行 ./start.sh。"
  fi
  mv -- "$DATASET_ARCHIVE.part" "$DATASET_ARCHIVE"
fi

mkdir -p -- "$(dirname -- "$ASSOCIATION_FILE")"
candidate_association="$SOURCE_DIR/Examples/RGB-D/associations/fr1_desk.txt"
prepare_args=(
  --archive "$DATASET_ARCHIVE"
  --extract-to "$SEQUENCE_DIR"
  --association-out "$ASSOCIATION_FILE"
  --report "$RUN_DIR/dataset_report.md"
  --url "$DATASET_URL"
)
if [[ -f "$candidate_association" ]]; then
  prepare_args+=(--candidate-association "$candidate_association")
fi
python3 "$ROOT_DIR/scripts/prepare_tum.py" "${prepare_args[@]}"

{
  printf '%s\n\n' '# CUDA RGB-D 运行清单'
  printf -- '- 后端：DCH-SLAM CUDA ORB 前端；CMake USE_CUDA_FRONTEND=ON\n'
  printf -- '- CUDA 架构：%s\n' "$CUDA_ARCHITECTURES"
  printf -- '- 源码：https://github.com/datrich/DCH-SLAM，revision %s\n' "$SOURCE_REVISION"
  printf -- '- 相机配置：%s\n' "$SETTINGS"
  printf -- '- 词袋：%s\n' "$VOCABULARY"
  printf -- '- 数据集：%s\n' "$SEQUENCE_DIR"
  printf -- '- association：%s\n' "$ASSOCIATION_FILE"
  printf -- '- 可执行文件：%s\n' "$SLAM_BINARY"
  printf -- '- CUDA 前端静态库：%s\n' "$CUDA_ARCHIVE"
  printf -- '- g2o 共享库（含 Barron 鲁棒核）：%s\n' "$G2O_DIR/lib/libg2o.so"
  printf -- '- DBoW2 共享库：%s\n' "$DBOW2_DIR/lib/libDBoW2.so"
  printf -- '- Sophus 头文件：%s\n' "$SOPHUS_DIR/sophus"
  printf -- '- YOLO 类别文件：%s（SHA-256 %s）\n' "$YOLO_DIR/coco.names" "$YOLO_NAMES_SHA256"
  printf -- '- YOLO 配置文件：%s（SHA-256 %s）\n' "$YOLO_DIR/yolo-fastest-xl.cfg" "$YOLO_CFG_SHA256"
  printf -- '- YOLO 权重：%s（SHA-256 %s）\n' "$YOLO_DIR/yolo-fastest-xl.weights" "$YOLO_WEIGHTS_SHA256"
  printf -- '- 构建目录：%s\n' "$BUILD_DIR"
  printf '%s\n\n' '- 构建并运行命令见 start.log 与 slam.log。'
  printf '%s\n' 'DCH-SLAM 在 ORB-SLAM3 基础上额外包含 CUDA ORB 前端、异步 YOLO 语义线程和自适应 Barron 鲁棒核；本实验不能视为原始 ORB-SLAM3 的 CUDA-only 对照。'
} > "$RUN_DIR/run_manifest.md"

mkdir -p -- "$RUN_DIR/figures"
[[ ! -e "$RUN_DIR/Thirdparty" && ! -L "$RUN_DIR/Thirdparty" ]] || fail \
  "运行目录中已存在 Thirdparty 路径：$RUN_DIR/Thirdparty"
ln -s -- "$SOURCE_DIR/Thirdparty" "$RUN_DIR/Thirdparty"
capture_viewer() {
  [[ -n "${DISPLAY:-}" ]] || {
    echo "viewer_capture=skipped (DISPLAY 未设置)"
    return 0
  }
  command -v xwininfo >/dev/null 2>&1 || {
    echo "viewer_capture=skipped (缺少 xwininfo，无法确认 viewer 窗口)"
    return 0
  }
  command -v import >/dev/null 2>&1 || {
    echo "viewer_capture=skipped (缺少 ImageMagick import)"
    return 0
  }
  local deadline=$((SECONDS + VIEWER_CAPTURE_TIMEOUT))
  local windows map_window_id frame_count
  while ((SECONDS < deadline)); do
    kill -0 "$SLAM_PID" 2>/dev/null || break
    windows="$(xwininfo -root -tree 2>/dev/null || true)"
    map_window_id="$(awk '/"ORB-SLAM3: Map Viewer"/ {print $1; exit}' <<<"$windows")"
    frame_count="$(grep -cE '^Frame [0-9]+ end$' "$RUN_DIR/slam.log" 2>/dev/null || true)"
    if [[ -n "$map_window_id" ]] && ((frame_count >= MAP_CAPTURE_MIN_FRAMES)); then
      if import -window "$map_window_id" "$RUN_DIR/figures/map_view.png" \
        2>"$RUN_DIR/map_capture.log"; then
        echo "map_viewer_window=$map_window_id"
        echo "viewer_capture=$RUN_DIR/figures/map_view.png"
      else
        echo "viewer_capture=failed (无法抓取 Pangolin 窗口；详情见 $RUN_DIR/map_capture.log)"
      fi
      return 0
    fi
    sleep 2
  done
  echo "viewer_capture=skipped (未在回放期间检测到 Pangolin viewer 窗口)"
}

echo "starting_rgbd_tum"
(
  cd -- "$RUN_DIR"
  exec "$SLAM_BINARY" "$VOCABULARY" "$SETTINGS" "$SEQUENCE_DIR" "$ASSOCIATION_FILE"
) >"$RUN_DIR/slam.log" 2>&1 &
SLAM_PID=$!
tail -n +1 -f "$RUN_DIR/slam.log" &
LOG_TAIL_PID=$!
handle_interrupt() {
  echo "interrupt_received=1; sending SIGINT to rgbd_tum pid=$SLAM_PID"
  kill -INT "$SLAM_PID" 2>/dev/null || true
}
trap handle_interrupt INT
capture_viewer &
CAPTURE_PID=$!
if wait "$SLAM_PID"; then
  SLAM_EXIT_CODE=0
else
  SLAM_EXIT_CODE=$?
  echo "slam_exit_code=$SLAM_EXIT_CODE"
fi
trap - INT
kill "$LOG_TAIL_PID" 2>/dev/null || true
wait "$LOG_TAIL_PID" 2>/dev/null || true
wait "$CAPTURE_PID" || true

if [[ ! -s "$RUN_DIR/CameraTrajectory.txt" || ! -s "$RUN_DIR/KeyFrameTrajectory.txt" ]]; then
  if ((SLAM_EXIT_CODE != 0)); then
    echo "trajectory_export=unavailable (SLAM 在写出轨迹前退出；详情见 $RUN_DIR/slam.log)" >&2
    exit "$SLAM_EXIT_CODE"
  fi
  fail "SLAM 正常退出，但 CameraTrajectory.txt 或 KeyFrameTrajectory.txt 不存在或为空。"
fi
MPLCONFIGDIR="$RUN_DIR/.matplotlib" python3 "$ROOT_DIR/scripts/analyze_trajectory.py" \
  --estimate "$RUN_DIR/CameraTrajectory.txt" \
  --ground-truth "$SEQUENCE_DIR/groundtruth.txt" \
  --output-dir "$RUN_DIR/figures"

NVCC_VERSION="$(nvcc --version | tail -n 1)"
{
  printf '%s\n\n' '# CUDA 构建记录'
  printf -- '- CMake 选项：USE_CUDA_FRONTEND=ON\n'
  printf -- '- CMake 选项：DCH_BUILD_EXTRA_EXAMPLES=OFF（仅配置所需 RGB-D 示例）\n'
  printf -- '- CUDA 架构：%s\n' "$CUDA_ARCHITECTURES"
  printf -- '- CUDA 静态库：%s\n' "$CUDA_ARCHIVE"
  printf -- '- g2o 共享库：%s\n' "$G2O_DIR/lib/libg2o.so"
  printf -- '- YOLO 资产 SHA-256：coco.names=%s，cfg=%s，weights=%s\n' \
    "$YOLO_NAMES_SHA256" "$YOLO_CFG_SHA256" "$YOLO_WEIGHTS_SHA256"
  printf -- '- RGB-D 程序：%s\n' "$SLAM_BINARY"
  printf -- '- 源 revision：%s\n' "$SOURCE_REVISION"
  printf -- '- CUDA 编译器：%s\n' "$NVCC_VERSION"
  printf -- '- g2o 构建命令：cmake --build %s --target g2o --parallel %s\n' "$BUILD_DIR" "$BUILD_JOBS"
  printf -- '- 构建命令：cmake --build %s --target rgbd_tum --parallel %s\n' "$BUILD_DIR" "$BUILD_JOBS"
  printf -- '- 构建日志：本次 start.log\n\n'
  printf '%s\n' '该记录来自本次构建完成后的缓存、库文件与可执行文件检查。GPU 运行状态以本次 SLAM 日志和 NVIDIA 驱动状态为准。'
} > "$RUN_DIR/build_report.md"

echo "trajectory=$RUN_DIR/CameraTrajectory.txt"
echo "keyframe_trajectory=$RUN_DIR/KeyFrameTrajectory.txt"
echo "figures=$RUN_DIR/figures"
if ((SLAM_EXIT_CODE != 0)); then
  echo "错误：SLAM 已导出轨迹，但进程以状态 $SLAM_EXIT_CODE 结束。" >&2
  exit "$SLAM_EXIT_CODE"
fi
echo "status=success"
