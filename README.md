# MTProto-Go 多实例部署脚本

本脚本用于一键部署多实例 MTProto-Go（支持 TLS 伪装）代理，适用于中国环境。

## ✅ 特性

- 每个实例独立随机端口
- 每个实例独立 secret
- 每个实例独立 TLS 伪装域名
- 自动开放防火墙端口（iptables + ufw）
- 自动设置开机启动（systemd）
- 代理链接保存到 `/opt/mtg/proxies.txt`

## 🛠️ 使用方法

```bash
bash -c "$(wget -qO- https://raw.githubusercontent.com/s61015265/mtg-multi-proxy/main/multi_mtg_full.sh)"
```

> 替换 `yourusername` 为你的 GitHub 用户名

## 📦 文件说明

- `multi_mtg_full.sh`：主脚本
- `README.md`：使用教程

## 🟥 停止所有代理

```bash
pkill mtg
```

或逐个停止：

```bash
systemctl stop mtg@端口号
```

## 🟢 查看代理链接

```bash
cat /opt/mtg/proxies.txt
```
