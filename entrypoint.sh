#!/bin/sh
# aria2-next + AriaNg 包装入口
# 1) 按 ARIANG_PORT 渲染 nginx 配置并启动静态站点
# 2) exec 回官方 aria2-next-entrypoint，完整保留 PUID/PGID、--conf-path 等原行为
set -eu

ARIANG_PORT="${ARIANG_PORT:-6880}"

# 端口必须是数字
case "$ARIANG_PORT" in
    ''|*[!0-9]*)
        echo "entrypoint: ARIANG_PORT must be a numeric port, got '${ARIANG_PORT}'" >&2
        exit 1
        ;;
esac

# tmpfs /tmp 每次启动都是空的，需现建目录
# 渲染到 /tmp 而非 /etc/nginx：容器启用 read_only 只读根文件系统时 /etc 不可写
mkdir -p /tmp/nginx/client_body /tmp/nginx/proxy /tmp/nginx/fastcgi /tmp/nginx/uwsgi /tmp/nginx/scgi
sed "s/__ARIANG_PORT__/${ARIANG_PORT}/g" /etc/nginx/nginx.conf.template > /tmp/nginx/nginx.conf

# 校验配置并后台启动 nginx（-c 指定渲染后的配置路径）
nginx -t -c /tmp/nginx/nginx.conf
nginx -c /tmp/nginx/nginx.conf

echo "entrypoint: AriaNg web UI listening on port ${ARIANG_PORT}"

# 交回官方 entrypoint 启动 aria2-next
exec /usr/local/bin/aria2-next-entrypoint "$@"
