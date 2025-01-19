#!/bin/bash

# 会话名称关键字
SCREEN_KEYWORD="hyper"
# 错误信息列表
ERROR_PATTERNS=(
    "Authentication failed"
    "Failed to connect to Hive"
    "Failed to register models"
    "Last pong received at"
    "status: Internal, message: \"error in response: status code 503 Service Unavailable\""
    "status: Internal, message: \"HTTP error: 500 Internal Server Error\""
    "status: Internal, message: \"error in response: status code 504 Gateway Timeout\""
    "Failed to authenticate"
    "transport error"
    "Error"
)
# 正常信息列表
NORMAL_PATTERNS=(
    "INFO \[aios_kernel::logger\] Ping sent successfully"
    "INFO \[aios_kernel::logger\] 🙂👍"
    "INFO \[aios_kernel::logger\] Received pong"
    "INFO \[aios_kernel::logger\] Pinging hive..."
)
# 超时时间（秒）
TIMEOUT=1800  # 30分钟
# 检测错误后的等待时间（秒）
ERROR_WAIT_TIME=300  # 5分钟
# 上次检测到正常信息的时间
last_success_time=$(date +%s)
# 检测到错误的时间
error_detected_time=0

# 获取所有包含关键字的会话名称
function get_session_names() {
    screen -ls | grep -oP "\d+\.$SCREEN_KEYWORD" || true
}

# 检查会话中的错误
function check_session_for_errors() {
    local session_name="$1"
    screen -S "$session_name" -X hardcopy /tmp/screenlog
    tail -n 10 /tmp/screenlog > /tmp/recentlog
    for pattern in "${ERROR_PATTERNS[@]}"; do
        if grep -q "$pattern" /tmp/recentlog; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 会话 $session_name 检测到错误模式: $pattern"
            error_detected_time=$(date +%s)
            return 0
        fi
    done
    return 1
}

# 检查会话中的正常信息
function check_session_for_normal() {
    local session_name="$1"
    screen -S "$session_name" -X hardcopy /tmp/screenlog
    tail -n 10 /tmp/screenlog > /tmp/recentlog
    for pattern in "${NORMAL_PATTERNS[@]}"; do
        if grep -q "$pattern" /tmp/recentlog; then
            return 0
        fi
    done
    return 1
}

# 重启节点
function restart_node() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 重启节点..."

    # 停止所有包含关键字的会话
    local session_names=$(get_session_names)
    for session_name in $session_names; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 正在停止会话 $session_name..."
        # 向会话发送停止命令
        screen -S "$session_name" -X stuff "aios-cli kill\n"
        sleep 5

        # 停止 screen 会话
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 正在停止 screen 会话 $session_name..."
        screen -S "$session_name" -X quit
        sleep 5
    done

    # 重新启动节点
    echo "$(date '+%Y-%m-%d %H:%M:%S') - 正在重新启动节点..."
    screen -S "$SCREEN_KEYWORD" -dm
    sleep 2
    screen -S "$SCREEN_KEYWORD" -X stuff "aios-cli kill\n"
    sleep 5
    screen -S "$SCREEN_KEYWORD" -X stuff "aios-cli start --connect\n"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Hyperspace节点已重启"
}

# 监控会话内容并重启节点
while true; do
    current_time=$(date +%s)
    local session_names=$(get_session_names)
    for session_name in $session_names; do
        if check_session_for_errors "$session_name"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 错误检测到，开始5分钟监控期..."
        fi
        if (( current_time - error_detected_time > 0 && current_time - error_detected_time < ERROR_WAIT_TIME )); then
            if check_session_for_normal "$session_name"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - 5分钟监控期内检测到正常模式，错误清除"
                error_detected_time=0
            fi
        elif (( current_time - error_detected_time >= ERROR_WAIT_TIME )); then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 5分钟内没有检测到正常信息，重启节点..."
            restart_node
            error_detected_time=0
            last_success_time=$(date +%s)
            break
        fi
        if check_session_for_normal "$session_name"; then
            echo "$(date '+%Y-%m-%d %H:%M:%S') - 会话 $session_name 检测到正常模式，节点正常运行"
            last_success_time=$(date +%s)
        fi
    done

    # 检查是否超时
    if (( current_time - last_success_time > TIMEOUT )); then
        echo "$(date '+%Y-%m-%d %H:%M:%S') - 超过30分钟没有检测到正常信息，重启节点..."
        restart_node
        last_success_time=$(date +%s)
    fi

    sleep 120  # 每2分钟检查一次
done
