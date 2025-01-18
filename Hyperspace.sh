#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/Hyperspace.sh"

# 定义检查间隔时间（秒），2分钟 = 120秒
CHECK_INTERVAL=120

# 定义screen会话名称
SCREEN_NAME="hyper"

# 定义日志文件路径
LOG_FILE="/root/aios-cli.log"

# 定义最大重试次数
MAX_RETRIES=5

# 确保环境变量已经生效
echo "确保环境变量更新..."
source /root/.bashrc

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "推特 @0xqianyi，免费开源，请勿相信收费"
        echo "================================================================"
        echo "退出脚本，请按键盘 ctrl + C 退出"
        echo "请选择要执行的操作:"
        echo "1. 部署hyperspace aiOS节点"
        echo "2. 查看运行日志"
        echo "3. 查看积分"
        echo "4. 删除节点"
        echo "5. 退出脚本"
        echo "================================================================"
        read -p "请输入选择 (1/2/3/4/5): " choice

        case $choice in
            1)  deploy_hyperspace_node ;;
            2)  view_logs ;;
            3)  view_points ;;
            4)  delete_node ;;
            5)  exit_script ;;
            *)  echo "无效选择，请重新输入！"; sleep 2 ;;
        esac
    done
}

# 部署hyperspace节点
function deploy_hyperspace_node() {
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
            read -n 1 -s -r -p "按任意键返回菜单..."
            return
        fi
    fi

    # 提示输入屏幕名称，默认值为 'hyper'
    read -p "请输入会话名称 (默认值名称请按回车): " screen_name
    screen_name=${screen_name:-hyper}
    echo "使用的会话名称是: $screen_name"

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
    echo "请输入你的私钥（按 CTRL+D 结束）："
    cat > my.pem

    # 使用 my.pem 文件运行 import-keys 命令
    echo "正在使用 my.pem 文件运行 import-keys 命令..."

    # 运行 import-keys 命令
    aios-cli hive import-keys ./my.pem
    sleep 5

    # 定义模型变量
    model="hf:TheBloke/phi-2-GGUF:phi-2.Q4_K_M.gguf"

    # 添加模型并重试
    echo "正在通过命令 'aios-cli models add' 添加模型..."
    while true; do
        if aios-cli models add "$model"; then
            echo "模型添加成功并且下载完成！"
            break
        else
            echo "添加模型时发生错误，正在重试..."
            # 检查网络连接
            if ping -q -c 1 -W 1 google.com >/dev/null; then
                echo "网络连接正常，重试添加模型..."
            else
                echo "网络连接异常，正在重启网络服务..."
                sudo systemctl restart networking
            fi
            sleep 3
        fi
    done

    # 登录并选择等级
    echo "正在登录并选择等级..."

    # 登录到 Hive
    aios-cli hive login

    # 提示用户选择等级
    echo "请选择节点等级（1-5）："
    echo "1. 30GB"
    echo "2. 20GB"
    echo "3. 8GB"
    echo "4. 4GB"
    echo "5. 2GB"
    select tier in 1 2 3 4 5; do
        case $tier in
            1|2|3|4|5)
                echo "你选择了等级 $tier"
                aios-cli hive select-tier $tier
                break
                ;;
            *)
                echo "无效的选择，请输入 1 到 5 之间的数字。"
                ;;
        esac
    done

    # 连接到 Hive
    if ! aios-cli hive connect; then
        echo "连接到 Hive 失败，正在尝试停止并重启节点..."
        restart_node
    fi

    # 停止 aios-cli 进程
    echo "使用 'aios-cli kill' 停止 'aios-cli start' 进程..."
    aios-cli kill

    # 在屏幕会话中运行 aios-cli start，并定向日志文件
    echo "在屏幕会话 '$screen_name' 中运行 'aios-cli start --connect'，并将输出定向到 '/root/aios-cli.log'..."
    screen -S "$screen_name" -X stuff "aios-cli start --connect >> /root/aios-cli.log 2>&1\n"

    echo "部署hyperspace节点完成，'aios-cli start --connect' 已在屏幕内运行，系统已恢复到后台。"

    # 启动监控脚本
    start_monitoring
}

# 启动监控脚本
function start_monitoring() {
    echo "启动监控脚本，每2分钟检查一次节点状态..."

    while true; do
        # 检查日志中的异常情况
        if check_log_for_errors; then
            echo "检测到日志异常，正在重启节点..."
            restart_node
        else
            echo "Hyperspace节点正在运行，日志正常，无需操作。"
        fi

        # 等待2分钟
        sleep $CHECK_INTERVAL
    done
}

# 检查日志中的异常情况
function check_log_for_errors() {
    echo "开始检查日志文件: $LOG_FILE"

    # 检查认证失败
    if grep -q "Authentication failed" "$LOG_FILE"; then
        echo "检测到认证失败"
        return 1
    fi

    # 检查连接不到Hive
    if grep -q "Failed to connect to Hive" "$LOG_FILE"; then
        echo "检测到连接不到Hive"
        return 1
    fi

    # 检查注册模型失败
    if grep -q "Failed to register models" "$LOG_FILE"; then
        echo "检测到注册模型失败"
        return 1
    fi

    # 检查ping失败
    if grep -q "Last pong received at" "$LOG_FILE"; then
        echo "检测到ping失败"
        return 1
    fi

    # 检查503服务不可用
    if grep -q "status: Internal, message: \"error in response: status code 503 Service Unavailable\"" "$LOG_FILE"; then
        echo "检测到503服务不可用"
        return 1
    fi

    # 检查500内部服务器错误
    if grep -q "status: Internal, message: \"HTTP error: 500 Internal Server Error\"" "$LOG_FILE"; then
        echo "检测到500内部服务器错误"
        return 1
    fi

    # 检查 Last pong received at 错误
    if grep -q "Last pong received at" "$LOG_FILE"; then
        echo "检测到 Last pong received at 错误"
        return 1
    fi

    # 检查其他常见错误
    if grep -q "Error" "$LOG_FILE"; then
        echo "检测到其他常见错误"
        return 1
    fi

    # 没有检测到异常
    echo "日志正常"
    return 0
}

# 重启节点
function restart_node() {
    echo "检测到日志异常，正在重启节点..."
    local retries=0

    while [ $retries -lt $MAX_RETRIES ]; do
        # 重新加载环境变量
        source /root/.bashrc

        # 停止节点
        echo "正在使用 'aios-cli kill' 停止节点..."
        aios-cli kill
        sleep 5

        # 检查是否有残留进程
        local pids=$(pgrep -x "aios-cli")
        if [ -n "$pids" ]; then
            echo "发现残留进程，正在手动停止..."
            kill -9 $pids
            sleep 5
        fi

        # 检查并停止 screen 会话
        if screen -ls | grep -q "$SCREEN_NAME"; then
            echo "发现残留的 screen 会话，正在停止..."
            screen -S "$SCREEN_NAME" -X quit
            sleep 5
        fi

        # 清空日志文件
        > "$LOG_FILE"

        # 重新启动节点
        screen -S "$SCREEN_NAME" -dm bash -c "source /root/.bashrc && aios-cli start --connect >> $LOG_FILE 2>&1"
        echo "Hyperspace节点已重启，重试次数: $retries"

        # 检查节点是否成功启动
        sleep 30  # 等待30秒，确保节点有足够时间启动
        if check_log_for_errors; then
            echo "节点启动失败，正在重试..."
            retries=$((retries + 1))
        else
            echo "节点启动成功。"
            return
        fi
    done

    echo "节点启动失败，已达到最大重试次数。"
    # 可以在这里添加通知机制，如发送邮件或短信
}

# 查看日志
function view_logs() {
    echo "正在查看日志..."
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

# 查看积分
function view_points() {
    echo "正在查看积分..."
    source /root/.bashrc
    aios-cli hive points
    sleep 2

    # 提示用户按任意键返回主菜单
    read -n 1 -s -r -p "按任意键返回主菜单..."
    main_menu
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

# 退出脚本
function exit_script() {
    echo "退出脚本..."
    exit 0
}

# 调用主菜单函数
main_menu
