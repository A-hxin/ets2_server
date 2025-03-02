#!/bin/sh
# 2025-03-02-08:10:45
# 项目地址：https://github.com/A-hxin/ets2_server/

# 服务器目录（使用绝对路径，防止软链接问题）
SERVER_HOME="/home/steam/ets2_sv/bin/linux_x64"

# Steam 运行库目录
STEAM_PATH="/home/steam/ets2_sv/linux64"

# 设置 `LD_LIBRARY_PATH`
export LD_LIBRARY_PATH="$STEAM_PATH:$SERVER_HOME:$LD_LIBRARY_PATH"

# 欧卡文档目录（可选）
export XDG_DATA_HOME="/home/steam/ets2_doc"

# PID 文件的绝对路径
PID_FILE="$SERVER_HOME/logs/server.pid"

# 日志文件
SERVER_LOG="$SERVER_HOME/logs/server.log"

# 启动参数
SERVER_OPTIONS="-nosingle -server server_packages.sii -server_cfg server_config.sii"

case "$1" in
    start)
        echo "🚀 正在启动 ETS2 服务器..."
        mkdir -p "$SERVER_HOME/logs"

        # 确保旧的 `awk` 进程被清理，避免日志进程残留
        AWK_PID=$(pgrep -f "awk.*server.log")
        if [ -n "$AWK_PID" ]; then
            echo "🛑 发现旧的日志进程 (PID: $AWK_PID)，正在清理..."
            kill -9 $AWK_PID
        fi

        # 启动服务器，并使用 `awk` 处理日志（不影响 PID 记录）
        setsid "$SERVER_HOME/eurotrucks2_server" $SERVER_OPTIONS 2>&1 | awk '{print strftime("%Y-%m-%d %H:%M:%S"), "-", $0}' >> "$SERVER_LOG" &

        # 等待 `eurotrucks2_server` 启动
        sleep 2  

        # 获取 `eurotrucks2_server` 的真实 PID
        SERVER_PID=$(pgrep -f "eurotrucks2_server")
        echo $SERVER_PID > "$PID_FILE"

        echo "✅ ETS2 服务器已启动，PID: $SERVER_PID"
        ;;
    
    stop)
        if [ -f "$PID_FILE" ]; then
            PID=$(cat "$PID_FILE")
            echo "🛑 正在停止 ETS2 服务器 (PID: $PID)..."

            # 先尝试正常终止服务器
            kill $PID
            sleep 2  

            # 如果进程仍然存活，则强制终止
            if ps -p $PID > /dev/null 2>&1; then
                echo "⚠ 进程 $PID 仍然存活，尝试强制终止..."
                kill -9 $PID
            fi

            # 终止可能存在的 `awk` 进程
            AWK_PID=$(pgrep -f "awk.*server.log")
            if [ -n "$AWK_PID" ]; then
                echo "🛑 发现日志处理进程 (PID: $AWK_PID)，正在清理..."
                kill -9 $AWK_PID
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
                rm -f "$PID_FILE"  # 清理无效的 PID 文件
            fi
        else
            echo "⚠ ETS2 服务器未运行。"
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
