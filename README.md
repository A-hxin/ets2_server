# 欧卡专用服务器启动脚本
这个脚本基于 CentOS 创建的 欧洲卡车模拟2 的启动脚本

## 下载
可以使用熟悉的方式将脚本下载到服务器上

## 可以使用软连接创建服务
例如
```
sudo ln -s /home/steam/ets2_sv/bin/linux_x64/server.sh /usr/local/bin/ets2_sv
```

## 权限问题
修复 logs/ 目录和 server.pid 文件权限
```
sudo chown -R steam:steam /home/steam/ets2_sv/bin/linux_x64/
sudo chmod -R 775 /home/steam/ets2_sv/bin/linux_x64/
sudo chown -R steam:steam /home/steam/ets2_sv/bin/linux_x64/logs
sudo chmod -R 775 /home/steam/ets2_sv/bin/linux_x64/logs
sudo chown -R steam:steam /home/steam/ets2_doc/Euro\ Truck\ Simulator\ 2/
sudo chmod -R 775 /home/steam/ets2_doc/Euro\ Truck\ Simulator\ 2/
```


## 使用方法：
```
[steam@bc-ets linux_x64]$ ets2_sv 
🚀 ETS2 服务器管理命令
🔹 用法: server {start|stop|restart|status}
  start    - 启动 ETS2 服务器
  stop     - 停止 ETS2 服务器
  restart  - 重启 ETS2 服务器
  status   - 查看 ETS2 服务器状态
[steam@bc-ets linux_x64]$
```
