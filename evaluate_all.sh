#!/bin/bash

# 1. 检查参数
if [ "$#" -ne 2 ]; then
    echo "使用方法: $0 <实验名称> <权重文件路径>"
    exit 1
fi

EXP_NAME=$1
WEIGHT_PATH=$2

# 2. 在 results 目录下创建独立的日志与指标文件夹
mkdir -p results/logs/ results/metrics/

# 3. 定义并初始化 Markdown 表格文件
METRIC_FILE="results/metrics/${EXP_NAME}_metrics.md"
echo "### ${EXP_NAME} 评估指标" > "$METRIC_FILE"
echo "| Dataset | PSNR | SSIM | NCC | LMSE |" >> "$METRIC_FILE"
echo "|---|---|---|---|---|" >> "$METRIC_FILE"

# 4. 定义测试数据集
DATASETS=("ceilnet_table2" "real20" "postcard" "objects" "wild")

# 5. 遍历测试与数据提取
for DS in "${DATASETS[@]}"; do
    echo "正在测试数据集: $DS ..."
    LOG_FILE="results/logs/${EXP_NAME}_${DS}.log"
    
    # 5.1 执行测试，将所有输出重定向到单独的日志文件
    python test_errnet.py --name "$EXP_NAME" --dataset "$DS" -r --icnn_path "$WEIGHT_PATH" --hyper > "$LOG_FILE" 2>&1
    
    # 5.2 正则提取逻辑：先定位到对应指标的键名，再提取其紧跟的数值
    PSNR=$(grep -i "PSNR" "$LOG_FILE" | tail -n 1 | grep -oEi "psnr[^0-9]*[0-9]+(\.[0-9]+)?" | grep -oE "[0-9]+(\.[0-9]+)?")
    SSIM=$(grep -i "SSIM" "$LOG_FILE" | tail -n 1 | grep -oEi "ssim[^0-9]*[0-9]+(\.[0-9]+)?" | grep -oE "[0-9]+(\.[0-9]+)?")
    NCC=$(grep -i "NCC" "$LOG_FILE" | tail -n 1 | grep -oEi "ncc[^0-9]*[0-9]+(\.[0-9]+)?" | grep -oE "[0-9]+(\.[0-9]+)?")
    LMSE=$(grep -i "LMSE" "$LOG_FILE" | tail -n 1 | grep -oEi "lmse[^0-9]*[0-9]+(\.[0-9]+)?" | grep -oE "[0-9]+(\.[0-9]+)?")
    
    # 5.3 处理缺失值情况
    PSNR=${PSNR:-"N/A"}
    SSIM=${SSIM:-"N/A"}
    NCC=${NCC:-"N/A"}
    LMSE=${LMSE:-"N/A"}
    
    # 5.4 将提取结果按 Markdown 表格行格式写入
    echo "| $DS | $PSNR | $SSIM | $NCC | $LMSE |" >> "$METRIC_FILE"
done

# 6. 测试完成提示并在终端打印最终表格
echo "测试完成！"
echo "完整日志所在路径: results/logs/"
echo "最终指标表格如下:"
cat "$METRIC_FILE"