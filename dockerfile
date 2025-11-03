# 定义构建时参数及其默认值
# version: 基础镜像的PostgreSQL版本
# APT_MIRROR: Debian apt源的镜像地址
# GITHUB_DOMAIN: git clone时使用的github域名
ARG version=latest
ARG APT_MIRROR=deb.debian.org
ARG GITHUB_PROXY_PREFIX=""

#---------------------------------------------------------------------
# 构建器阶段 (builder)
#---------------------------------------------------------------------
FROM postgres:${version}-bookworm AS builder

# 将构建参数引入此阶段
ARG version
ARG APT_MIRROR
ARG GITHUB_DOMAIN

ENV DEBIAN_FRONTEND=noninteractive
ENV PG_DEV_PACKAGE=postgresql-server-dev-${version}

# 安装编译依赖
RUN --mount=target=/var/lib/apt/lists,type=cache,sharing=locked \
    --mount=target=/var/cache/apt,type=cache,sharing=locked \
    # 使用 sed 替换 apt 源为指定的镜像
    # 使用 | 作为 sed 的分隔符，避免 URL 中的 / 引起冲突
    sed -i "s|deb.debian.org|$APT_MIRROR|g" /etc/apt/sources.list.d/debian.sources && \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends build-essential ca-certificates git autoconf automake libtool $PG_DEV_PACKAGE

WORKDIR /tmp

# 克隆并编译 scws，使用 GITHUB_DOMAIN 参数
RUN git clone ${GITHUB_PROXY_PREFIX}https://github.com/hightman/scws && \
    cd scws && \
    touch README && \
    sed -i '/^\s*#/d' Makefile.am && \
    aclocal && \
    autoconf && \
    autoheader && \
    libtoolize && \
    automake --add-missing && \
    ./configure --prefix=/usr/local/scws && \
    make -j$(nproc) && \
    make install

ENV SCWS_HOME=/usr/local/scws

# 克隆并编译 zhparser，使用 GITHUB_DOMAIN 参数
RUN git clone ${GITHUB_PROXY_PREFIX}https://github.com/amutu/zhparser && \
    cd zhparser && \
    make -j$(nproc) && \
    make install

#---------------------------------------------------------------------
# 最终镜像阶段
#---------------------------------------------------------------------
FROM postgres:${version}-bookworm

# 从 builder 阶段拷贝编译好的文件
COPY --from=builder /usr/local/scws /usr/local/scws
COPY --from=builder /usr/lib/postgresql /usr/lib/postgresql
COPY --from=builder /usr/share/postgresql /usr/share/postgresql

# 拷贝初始化SQL脚本
COPY init.sql /docker-entrypoint-initdb.d/zhparser.sql
