# RustDesk 自建服务器部署指南

使用 Docker 快速部署 RustDesk Server（hbbs/hbbr）和 RustDesk API 服务，实现 RustDesk 的自托管。

---

## 架构说明

本项目包含以下服务：
- `hbbs`：RustDesk 服务器的核心服务，负责建立控制通道和文件传输通道。
- `hbbr`：RustDesk 的中继服务器，负责数据中转。
- `rustdesk-api`：RustDesk API 服务，提供 Web 登录界面和 API 接口支持。

---

## 环境要求

- Docker（19+）
- Docker Compose
- Bash 环境（Linux/macOS 或 WSL）

---

## 快速启动

1. 请确保你已克隆本项目并进入目录。
2. 修改 `.env` 文件中的 `RUSTDESK_HOST_IP` 为你的服务器公网 IP。
3. 执行启动脚本：

```bash
chmod +x start.sh
./start.sh
```

脚本将：
- 先启动 `hbbs`，生成服务器公钥；
- 等待 `id_ed25519.pub` 文件生成；
- 将公钥写入 `.env` 作为 `RUSTDESK_API_KEY`；
- 最后启动 `hbbr` 和 `rustdesk-api`。

---

## 停止服务

```bash
docker-compose down
```

---

## Docker 服务说明

### hbbs（RustDesk 主桥接服务器）

- 端口映射：
    - `21115`: TCP 用于客户端信息同步
    - `21116`: TCP/UDP 用于 NAT 穿透和注册服务
    - `21118`: TCP 用于静态文件分发
- 使用 `hbbs -r <host_ip>:21117` 命令，指定 hbbr relay 服务地址
- 存储数据目录：`./data/hbbs`

### hbbr（RustDesk 中继服务器）

- 端口：`21117`
- 存储数据目录：`./data/hbbr`

### rustdesk-api（前端 API 和 Web 登录界面）

- 端口：`21114`
- 环境变量：
    - `RUSTDESK_API_LANG`: 界面语言
    - `TZ`: 时区设置
    - `RUSTDESK_API_RUSTDESK_ID_SERVER`: id 登录地址
    - `RUSTDESK_API_RUSTDESK_RELAY_SERVER`: relay 地址
    - `RUSTDESK_API_RUSTDESK_API_SERVER`: api 服务地址
    - `RUSTDESK_API_KEY`: hbbs 公钥，用于 API 校验指纹信息

---

## Web API 使用

访问地址：

```
http://<your_server_ip>:21114
```

初次安装管理员用户名为 `admin`，密码将在容器 `rustdesk-api` 控制台打印，可以通过 [命令行](https://github.com/lejianwen/rustdesk-api#CLI) 更改密码

> 初次登录后请及时修改自己的账户密码。

---

## 注意事项

- 请确保服务器防火墙设置允许端口: 21115 ~ 21119。
- hbbs 生成 `id_ed25519.pub` 需要几分钟时间（取决于 hbbs 启动速度）。如果 start.sh 脚本检测超时，请手动检查 `./data/hbbs` 文件夹是否存在生成的公钥。

---

## 参考项目/文档

- RustDesk 服务端源码: [https://github.com/rustdesk/rustdesk-server](https://github.com/rustdesk/rustdesk-server)
- rustdesk-api 项目：[https://github.com/lejianwen/rustdesk-api](https://github.com/lejianwen/rustdesk-api)

---

> 如果你使用域名并希望支持 HTTPS，可以自行用 Nginx 或 Traefik 配置反向代理。