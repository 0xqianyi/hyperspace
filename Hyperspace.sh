#!/bin/bash

# 记录用户输入的信息
USER_INPUT_FILE="/root/user_input.txt"

# 函数记录用户输入
function record_user_input() {
    echo "$1" >> "$USER_INPUT_FILE"
}

# 从文件中读取用户输入
function get_user_input() {
    sed -n "$1p" "$USER_INPUT_FILE"
}

# 清空用户输入文件
function clear_user_input() {
    > "$USER_INPUT_FILE"
}

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由大赌社区哈哈哈哈编写，推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "如有问题，可联系推特，仅此只有一个号"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出即可"
        echo "请选择要执行的操作:"
        echo "1. 部署hyperspace节点"
        echo "2. 查看日志"
        echo "3. 查看积分"
        echo "4. 删除节点（停止节点）"
        echo "5. 启用日志监控"
        echo "6. 退出脚本"
        echo "================================================================"
        read -p "请输入选择 (1/2/3/4/5/6): " choice

        case $choice in
            1)  deploy_hyperspace_node ;;
            2)  view_logs ;;
            3)  view_points ;;
            4)  delete_node ;;
            5)  start_log_monitor ;;
            6)  exit_script ;;
            *)  echo "无效选择，请重新输入！"; sleep 2 ;;
        esac
    done
}

# 部署hyperspace节点
function deploy_hyperspace_node() {
    clear_user_input

    while true; do
        # 执行安装命令
        echo "正在执行安装命令：curl https://download.hyper.space/api/install | bash"
        curl https://download.hyper.space/api/install | bash

        # 获取安装后新添加的路径
        NEW_PATH=$(bash -c 'source /root/.bashrc && echo $PATH')
        
        # 更新当前shell的PATH
        export PATH="$NEW_PATH"

        # 验证aios-cli是否可用
        if ! command -v aios-cli &> /dev/null; then
            echo "aios-cli 命令未找到，正在重试..."
            sleep 3
            # 再次尝试更新PATH
            export PATH="$PATH:/root/.local/bin"
            if ! command -v aios-cli &> /dev/null; then
                echo "无法找到 aios-cli 命令，请手动运行 'source /root/.bashrc' 后重试"
                read -n 1 -s -r -p "按任意键返回主菜单..."
                return
            fi
        fi

        # 提示输入屏幕名称，默认值为 'hyper'
        screen_name=$(get_user_input 1)
        if [ -z "$screen_name" ]; then
            read -p "请输入屏幕名称 (默认值: hyper): " screen_name
            screen_name=${screen_name:-hyper}
            record_user_input "$screen_name"
        fi
        echo "使用的屏幕名称是: $screen_name"

        # 清理已存在的 'hyper' 屏幕会话
        echo "检查并清理现有的 'hyper' 屏幕会话..."
        screen -ls | grep "$screen_name" &>/dev/null
        if [ $? -eq 0 ]; then
            echo "找到现有的 '$screen_name' 屏幕会话，正在停止并删除..."
            screen -S "$screen_name" -X quit
            sleep 2
        else
            echo "没有找到现有的 '$screen_name' 屏幕会话。"
        fi

        # 创建一个新的屏幕会话
        echo "创建一个名为 '$screen_name' 的屏幕会话..."
        screen -S "$screen_name" -dm

        # 在屏幕会话中运行 aios-cli start
        echo "在屏幕会话 '$screen_name' 中运行 'aios-cli start' 命令..."
        screen -S "$screen_name" -X stuff "aios-cli start\n"

        # 等待几秒钟确保命令执行
        sleep 5

        # 退出屏幕会话
        echo "退出屏幕会话 '$screen_name'..."
        screen -S "$screen_name" -X detach
        sleep 5
        
        # 确保环境变量已经生效
        echo "确保环境变量更新..."
        source /root/.bashrc
        sleep 4  # 等待4秒确保环境变量加载

        # 打印当前 PATH，确保 aios-cli 在其中
        echo "当前 PATH: $PATH"

        # 提示用户输入私钥并保存为 my.pem 文件
        private_key=$(get_user_input 2)
        if [ -z "$private_key" ]; then
            echo "请输入你的私钥（按 CTRL+D 结束）："
            cat > my.pem
            record_user_input "$(cat my.pem)"
        else
            echo "$private_key" > my.pem
        fi

        # 使用 my.pem 文件运行 import-keys 命令
        echo "正在使用 my.pem 文件运行 import-keys 命令..."
        
        # 运行 import-keys 命令
        aios-cli hive import-keys ./my.pem
        if [ $? -ne 0 ]; then
            echo "import-keys 失败，重新安装..."
            continue
        fi
        sleep 5

        # 定义模型变量
        model="hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf"

        # 添加模型
        echo "正在通过命令 'aios-cli models add' 添加模型..."
        if ! aios-cli models add "$model"; then
            echo "添加模型失败，重新安装..."
            continue
        fi
        echo "模型添加成功并且下载完成！"

        # 登录并选择等级
        echo "正在登录并选择等级..."

        # 登录到 Hive
        if ! aios-cli hive login; then
            echo "登录失败，重新安装..."
            continue
        fi

        # 提示用户选择等级
        tier=$(get_user_input 3)
        if [ -z "$tier" ]; then
            echo "请选择等级（1-5）："
            select tier in 1 2 3 4 5; do
                if [[ $tier =~ ^[1-5]$ ]]; then
                    echo "你选择了等级 $tier"
                    record_user_input "$tier"
                    break
                else
                    echo "无效的选择，请输入 1 到 5 之间的数字。"
                fi
            done
        fi

        # 选择等级
        if ! aios-cli hive select-tier $tier; then
            echo "选择等级失败，重新安装..."
            continue
        fi

        # 连接到 Hive
        if ! aios-cli hive connect; then
            echo "连接到 Hive 失败，重新安装..."
            continue
        fi
        sleep 5

        # 停止 aios-cli 进程
        echo "使用 'aios-cli kill' 停止 'aios-cli start' 进程..."
        aios-cli kill

        # 在屏幕会话中运行 aios-cli start，并定向日志文件
        echo "在屏幕会话 '$screen_name' 中运行 'aios-cli start --connect'，并将输出定向到 '/root/aios-cli.log'..."
        screen -S "$screen_name" -X stuff "aios-cli start --connect >> /root/aios-cli.log 2>&1\n"

        echo "部署hyperspace节点完成，'aios-cli start --connect' 已在屏幕内运行，系统已恢复到后台。"

        # 提示用户按任意键返回主菜单
        read -n 1 -s -r -p "按任意键返回主菜单..."
        return
    done
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

# 启用日志监控
function start_log_monitor() {
    echo "启动日志监控..."

    # 创建监控脚本文件
    cat > /root/monitor.sh << 'EOL'
#!/bin/bash
LOG_FILE="/root/aios-cli.log"
SCREEN_NAME="hyper"
MONITOR_LOG="/root/monitor.log"
LAST_RESTART=$(date +%s)
MIN_RESTART_INTERVAL=300

while true; do
    current_time=$(date +%s)
    
    if (tail -n 20 "$LOG_FILE" | grep -q "Last pong received.*Sending reconnect signal" || \
        tail -n 20 "$LOG_FILE" | grep -q "Failed to authenticate" || \
        tail -n 20 "$LOG_FILE" | grep -q "Failed to connect to Hive" || \
        tail -n 20 "$LOG_FILE" | grep -q "Another instance is already running" || \
        tail -n 20 "$LOG_FILE" | grep -q "\"message\": \"Internal server error\"") && \
       [ $((current_time - LAST_RESTART)) -gt $MIN_RESTART_INTERVAL ]; then
        echo "$(date): 检测到连接问题、认证失败、连接到 Hive 失败、实例已在运行或内部服务器错误，正在重启服务..." >> $MONITOR_LOG
        
        # 先发送 Ctrl+C
        screen -S "$SCREEN_NAME" -X stuff $'\003'
        sleep 5
        
        # 执行 aios-cli kill
        screen -S "$SCREEN_NAME" -X stuff "aios-cli kill\n"
        sleep 5
        
        # 确认日志文件清空
        echo "$(date): 清理旧日志..." > "$LOG_FILE"
        if [ $? -eq 0 ]; then
            echo "$(date): 日志文件已清空" >> $MONITOR_LOG
        else
            echo "$(date): 无法清空日志文件" >> $MONITOR_LOG
        fi
        
        # 重新启动服务
        screen -S "$SCREEN_NAME" -X stuff "aios-cli start --connect >> /root/aios-cli.log 2>&1\n"
        
        LAST_RESTART=$current_time
        echo "$(date): 服务已重启" >> $MONITOR_LOG

        # 检查日志文件内容
        sleep 5
        echo "$(date): 当前日志文件内容：" >> $MONITOR_LOG
        tail -n 20 "$LOG_FILE" >> $MONITOR_LOG
    fi
    sleep 30
done
EOL

    # 添加执行权限
    chmod +x /root/monitor.sh

    # 在后台启动监控脚本
    nohup /root/monitor.sh > /root/monitor.log 2>&1 &

    echo "日志监控已启动，后台运行中。"
    echo "可以通过查看 /root/monitor.log 来检查监控状态"
    sleep 2

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
