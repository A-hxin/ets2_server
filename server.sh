#!/bin/sh


# 服务器目录
SERVER_HOME="/home/steam/ets2_sv/bin/linux_x64"

# Steam 运行库目录
STEAM_PATH="/home/steam/ets2_sv/linux64"

# 设置 `LD_LIBRARY_PATH`
export LD_LIBRARY_PATH="$STEAM_PATH:$SERVER_HOME:$LD_LIBRARY_PATH"

# 欧卡文档目录
export XDG_DATA_HOME="/home/steam/ets2_doc"

# PID 文件路径
PID_FILE="$SERVER_HOME/logs/server.pid"

# 启动参数
SERVER_OPTIONS="-nosingle -server server_packages.sii -server_cfg server_config.sii"

case "$1" in
    start)
        echo "🚀 正在启动 ETS2 服务器..."
        mkdir -p "$SERVER_HOME/logs"

        # 启动服务器，日志输出到文件
        "$SERVER_HOME/eurotrucks2_server" $SERVER_OPTIONS | exec -a ets2_server_log awk '{print strftime("%Y-%m-%d %H:%M:%S"), "-", $0}' >> "$SERVER_HOME/logs/server.log" 2>&1 &

        SERVER_PID=$!  # 记录 `eurotrucks2_server` 真实的 PID
        echo $SERVER_PID > "$PID_FILE"
        echo "✅ ETS2 服务器已启动，PID: $SERVER_PID"
        ;;
    
    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            echo "🛑 正在停止 ETS2 服务器 (PID: $PID)..."

            # 先杀掉 `eurotrucks2_server`
            kill $PID && rm -f "$PID_FILE"

            # 也尝试杀掉 `awk`（如果仍然存在）
            AWK_PID=$(pgrep -P $PID awk)
            if [ -n "$AWK_PID" ]; then
                echo "🛑 发现 `awk` 进程 (PID: $AWK_PID)，正在清理..."
                kill $AWK_PID
            fi

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
            fi
        else
            echo "⚠ ETS2 服务器未运行。"
        fi
        ;;

    *)
        echo "🚀 ETS2 服务器管理命令"
        echo "🔹 用法: server {start|stop|restart|status}"
        echo "  start    - 启动 ETS2 服务器"
        echo "  stop     - 停止 ETS2 服务器"
        echo "  restart  - 重启 ETS2 服务器"
        echo "  status   - 查看 ETS2 服务器状态"
        exit 1
        ;;
esac
