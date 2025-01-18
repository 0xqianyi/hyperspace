#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Hyperspace.sh"

# 新增监控和自动重启函数
function monitor_and_restart() {
    SERVICE_NAME="aios-cli"
    CHECK_INTERVAL=900 # 15分钟检查一次
    MAX_RETRY_TIME=900 # 最大重试时间为15分钟
    LOG_FILE="/root/aios-cli.log"
    LAST_SUCCESSFUL_PING_TIME=$(date +%s) # 初始化为当前时间

    while true; do
        CURRENT_TIME=$(date +%s)
        
        # 检查日志文件中是否有成功的Pong响应
        if grep -q "Received pong" "$LOG_FILE"; then
            echo "$(date): Found successful ping in log."
            # 更新最后一次成功的ping时间
            LAST_SUCCESSFUL_PONG_LINE=$(grep -oP "(?<=\[)[^]]+(?=]) Received pong" "$LOG_FILE" | tail -n 1)
            LAST_SUCCESSFUL_PING_TIME=$(date -d "${LAST_SUCCESSFUL_PONG_LINE%%]*}" +%s)
        else
            echo "$(date): No successful ping found."
        fi
        
        # 如果超过15分钟没有收到成功的pong响应，则认为连接异常
        TIME_DIFF=$((CURRENT_TIME - LAST_SUCCESSFUL_PING_TIME))
        if [ "$TIME_DIFF" -gt "$MAX_RETRY_TIME" ]; then
            echo "$(date): No successful connection for over 15 minutes, restarting $SERVICE_NAME..."
            
            # 停止并重新启动节点
            screen -S hyper -X stuff "killall $SERVICE_NAME\n"
            sleep 10
            screen -S hyper -X stuff "aios-cli start --connect >> $LOG_FILE 2>&1\n"
            
            # 更新最后一次成功的ping时间以避免立即再次重启
            LAST_SUCCESSFUL_PING_TIME=$CURRENT_TIME
        else
            echo "$(date): Connection appears to be normal."
        fi
        
        # 等待下一次检查
        sleep $CHECK_INTERVAL
    done
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "推特：0xqianyi 免费开源，请勿相信收费"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 部署hyperspace Aios节点"
        echo "2. 查看运行日志"
        echo "3. 查看所得积分"
        echo "4. 删除节点"
        echo "5. 退出脚本"
        echo "================================================================"
        read -p "请输入选择 (1/2/3/4/5): " choice

        case $choice in
            1) deploy_hyperspace_node ;;
            2) view_logs ;; 
            3) view_points ;;
            4) delete_node ;;
            5) exit_script ;;
            *) echo "无效选择，请重新输入！"; sleep 2 ;;
        esac
    done
}

# 部署hyperspace节点
function deploy_hyperspace_node() {
    # ... [原有部署代码保持不变] ...

    # 在屏幕会话中运行 aios-cli start，并定向日志文件
    echo "在屏幕会话 '$screen_name' 中运行 'aios-cli start --connect'，并将输出定向到 '/root/aios-cli.log'..."
    screen -S "$screen_name" -dm bash -c "aios-cli start --connect >> /root/aios-cli.log 2>&1 &"

    echo "部署hyperspace节点完成，'aios-cli start --connect' 已在屏幕内运行，系统已恢复到后台。"

    # 启动监控进程作为后台任务
    (monitor_and_restart) &
    
    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 查看积分
function view_points() {
    echo "正在查看积分..."
    source /root/.bashrc
    aios-cli hive points
    sleep 2
}

# 删除节点（停止节点）
function delete_node() {
    echo "正在使用 'aios-cli kill' 停止节点..."

    # 执行 aios-cli kill 停止节点
    aios-cli kill
    sleep 2
    
    echo "'aios-cli kill' 执行完成，节点已停止。"

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 查看日志
function view_logs() {
    echo "正在查看日志..."
    LOG_FILE="/root/aios-cli.log"   # 日志文件路径

    if [ -f "$LOG_FILE" ]; then
        echo "显示日志的最后 200 行:"
        tail -n 200 "$LOG_FILE"   # 显示最后 200 行日志
    else
        echo "日志文件不存在: $LOG_FILE"
    fi

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
}

# 退出脚本
function exit_script() {
    echo "退出脚本..."
    exit 0
}

# 调用主菜单函数
main_menu
