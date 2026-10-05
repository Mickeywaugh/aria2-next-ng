FROM ghcr.io/aninsomniacy/aria2-next:latest

LABEL \
    maintainer="Mickey Wu <Mickeywaugh@qq.com>" \
    description="aria2-next with built-in AriaNg web UI (static site on port 6880)."

# ============================================================
# AriaNg 站点端口（运行时可用 -e ARIANG_PORT=xxxx 覆盖）
# ============================================================
ENV ARIANG_PORT=6880

# ============================================================
# 安装 nginx
# 基础镜像为 ubuntu:22.04（同官方 packaging/docker/Dockerfile），apt 可用
# ============================================================
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends nginx net-tools curl \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

# ============================================================
# AriaNg 静态站点（AllInOne 单文件版本，自包含，无需外部 js/css）
# ============================================================
COPY ariang/ /var/www/ariang/

# ============================================================
# nginx 配置模板 + 包装 entrypoint
# ============================================================
COPY nginx.conf.template /etc/nginx/nginx.conf.template
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod 755 /usr/local/bin/entrypoint.sh \
    && mkdir -p /var/www/ariang /tmp/nginx \
    && chmod -R a+rX /var/www/ariang

# ============================================================
# 6800：aria2 JSON-RPC（基础镜像已声明）
# 6880：AriaNg Web UI
# ============================================================
EXPOSE 6800 6880

# 包装入口：先启动 nginx，再 exec 回官方 aria2-next-entrypoint
# 官方 entrypoint 的 PUID/PGID 校验、目录 chown、--conf-path 等行为完整保留
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["--conf-path=/config/aria2.conf"]
