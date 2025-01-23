#!/bin/bash

# 设置Java运行环境变量
JAVA_HOME=/usr/java/latest
PATH=$JAVA_HOME/bin:$PATH

# 设置Java内存参数
JAVA_OPTS="-Xms256m -Xmx512m -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=256m"

# 设置应用程序目录
APP_HOME=/home/java
APP_NAME=mysql-service-1.0-SNAPSHOT.jar
APP_LOG=$APP_HOME/logs

# 创建日志目录
mkdir -p $APP_LOG

# 检查服务是否已经运行
pid=$(ps -ef | grep $APP_NAME | grep -v grep | awk '{print $2}')
if [ -n "$pid" ]; then
    echo "Service is already running (pid: $pid)"
    exit 1
fi

# 启动应用
echo "Starting MySQL Service..."
nohup java $JAVA_OPTS -jar $APP_HOME/$APP_NAME > $APP_LOG/startup.log 2>&1 &

# 获取新进程ID
NEW_PID=$!

# 等待几秒检查进程是否存活
sleep 3
if ps -p $NEW_PID > /dev/null; then
    echo "Service started successfully (pid: $NEW_PID)"
    echo "You can check the logs at: $APP_LOG/startup.log"
else
    echo "Service failed to start. Please check the logs at: $APP_LOG/startup.log"
    exit 1
fi 