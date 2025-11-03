Docker build scripts for <https://github.com/amutu/zhparser> PostgreSQL extension.

## Usage

- Supported versions:
  - 15
  - 16
  - 17
  - 18

- Supported architectures:
  - `linux/amd64`
  - `linux/arm64`

```bash
docker run -d \
    --name postgres \
    -p 5432:5432 \
    -e POSTGRES_PASSWORD=postgres \
    postgres:16
```

That's it. You can now connect to the PostgreSQL server, or use `psql` to test the extension:

```bash
docker exec -it postgres psql -U postgres
# > select to_tsvector('chinese', '小明爱吃苹果');
# ---------------------------------
#  '吃':3 '小明':1 '爱':2 '苹果':4
# (1 row)
```

docker build  --build-arg version=17 --build-arg APT_MIRROR=mirrors.ustc.edu.cn  --build-arg GITHUB_DOMAIN=https://ghproxy.net -t pgsql-docker:17 .