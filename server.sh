#!/bin/bash

# 服务器目录
SERVER_HOME="/home/steam/ets2_sv/bin/linux_x64"

# Steam 运行库目录
STEAM_PATH="/home/steam/ets2_sv/linux64"

# 设置 `LD_LIBRARY_PATH`
export LD_LIBRARY_PATH="$STEAM_PATH:$SERVER_HOME:$LD_LIBRARY_PATH"

# 欧卡文档目录（可选）
export XDG_DATA_HOME="/home/steam/ets2_doc"

# 进程 PID 文件
PID_FILE="$SERVER_HOME/logs/server.pid"
LOG_PID_FILE="$SERVER_HOME/logs/logging.pid"

# 只保留格式化后的日志
LOG_FILE="$SERVER_HOME/logs/server_timestamped.log"

# 启动参数
SERVER_OPTIONS="-nosingle -server server_packages.sii -server_cfg server_config.sii"

case "$1" in
    start)
        echo "🚀 正在启动 ETS2 服务器..."
        mkdir -p "$SERVER_HOME/logs"

        # 清理旧的 `ets2_log_server` 进程
        if [ -f "$LOG_PID_FILE" ]; then
            LOG_PID=$(cat "$LOG_PID_FILE")
            if [ -n "$LOG_PID" ] && ps -p $LOG_PID > /dev/null 2>&1; then
                echo "🛑 发现旧的日志进程 (PID: $LOG_PID)，正在清理..."
                kill -9 $LOG_PID
            fi
            rm -f "$LOG_PID_FILE"
        fi

        # 启动服务器，并直接格式化日志（不再创建原始 server.log）
        setsid "$SERVER_HOME/eurotrucks2_server" $SERVER_OPTIONS 2>&1 | awk '{print strftime("%Y-%m-%d %H:%M:%S"), "-", $0}' >> "$LOG_FILE" &

        SERVER_PID=$!  # 记录 `eurotrucks2_server` 真实的 PID
        echo $SERVER_PID > "$PID_FILE"

        echo "✅ ETS2 服务器已启动，PID: $SERVER_PID"

        # 记录 `awk` 进程的 PID（作为 `ets2_log_server`）
        echo $! > "$LOG_PID_FILE"
        ;;
    
    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            echo "🛑 正在停止 ETS2 服务器 (PID: $PID)..."

            # 先尝试正常终止服务器
            kill $PID
            sleep 2  

            # 强制终止服务器
            if ps -p $PID > /dev/null 2>&1; then
                echo "⚠ 进程 $PID 仍然存活，尝试强制终止..."
                kill -9 $PID
            fi

            # 终止日志 `ets2_log_server` 进程
            if [ -f "$LOG_PID_FILE" ]; then
                LOG_PID=$(cat "$LOG_PID_FILE")
                if [ -n "$LOG_PID" ] && ps -p $LOG_PID > /dev/null 2>&1; then
                    echo "🛑 发现日志处理进程 (PID: $LOG_PID)，正在清理..."
                    kill -9 $LOG_PID
                fi
                rm -f "$LOG_PID_FILE"
            fi

            # 清理 PID 文件
            rm -f "$PID_FILE"
            echo "✅ ETS2 服务器已完全停止。"
        else
            echo "⚠ ETS2 服务器未运行。"
        fi
        ;;
    
    restart)
        echo "🔄 正在重启 ETS2 服务器..."
        $0 stop
        sleep 3
        $0 start
        ;;

    status)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            if ps -p $PID > /dev/null 2>&1; then
                echo "✅ ETS2 服务器正在运行，PID: $PID"
            else
                echo "⚠ ETS2 服务器的 PID 文件存在，但进程未运行！"
                rm -f "$PID_FILE"  
            fi
        else
            echo "⚠ ETS2 服务器未运行。"
        fi

        # 检查日志进程
        if [ -f "$LOG_PID_FILE" ]; then
            LOG_PID=$(cat "$LOG_PID_FILE")
            if ps -p $LOG_PID > /dev/null 2>&1; then
                echo "✅ 日志进程 ets2_log_server 正在运行，PID: $LOG_PID"
            else
                echo "⚠ 日志进程的 PID 文件存在，但进程未运行！"
                rm -f "$LOG_PID_FILE"
            fi
        else
            echo "⚠ 日志进程 ets2_log_server 未运行。"
        fi
        ;;

    *)
        echo "🚀 ETS2 服务器管理命令"
        echo "🔹 用法: ets2_sv {start|stop|restart|status}"
        echo "  start    - 启动 ETS2 服务器"
        echo "  stop     - 停止 ETS2 服务器"
        echo "  restart  - 重启 ETS2 服务器"
        echo "  status   - 查看 ETS2 服务器状态"
        exit 1
        ;;
esac
