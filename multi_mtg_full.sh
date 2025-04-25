#!/bin/bash

INSTANCE_COUNT=10
PORT_MIN=10000
PORT_MAX=60000
TLS_DOMAINS=("cloudflare.com" "microsoft.com" "google.com" "amazon.com" "akamai.com")
MTG_PATH="/opt/mtg"
SYSTEMD_DIR="/etc/systemd/system"
SERVER_IP=$(curl -s ipv4.icanhazip.com)

apt update -y && apt install -y iptables-persistent curl wget openssl

mkdir -p $MTG_PATH
cd $MTG_PATH || exit
if [ ! -f "mtg" ]; then
    echo "下载 mtg..."
    LATEST_URL=$(curl -s https://api.github.com/repos/9seconds/mtg/releases/latest | grep "browser_download_url" | grep "linux-amd64" | cut -d '"' -f 4)
    wget -O mtg "$LATEST_URL"
    chmod +x mtg
fi

echo "清理旧服务..."
systemctl stop mtg@* >/dev/null 2>&1
rm -f $SYSTEMD_DIR/mtg@*.service

> $MTG_PATH/proxies.txt
> $MTG_PATH/ports.txt

echo "开始生成 $INSTANCE_COUNT 个代理..."

for (( i=1; i<=INSTANCE_COUNT; i++ ))
do
    PORT=$((RANDOM % (PORT_MAX - PORT_MIN + 1) + PORT_MIN))
    SECRET=$(openssl rand -hex 16)
    DOMAIN=${TLS_DOMAINS[$((RANDOM % ${#TLS_DOMAINS[@]}))]}

    echo "生成实例 $i：端口 $PORT, 域名 $DOMAIN, Secret $SECRET"

    LINK="tg://proxy?server=$SERVER_IP&port=$PORT&secret=ee$SECRET"
    echo "$LINK" >> $MTG_PATH/proxies.txt
    echo "$PORT" >> $MTG_PATH/ports.txt

    iptables -I INPUT -p tcp --dport $PORT -j ACCEPT
    iptables -I INPUT -p udp --dport $PORT -j ACCEPT
    ufw allow $PORT/tcp >/dev/null 2>&1
    ufw allow $PORT/udp >/dev/null 2>&1

    cat > $SYSTEMD_DIR/mtg@$PORT.service <<EOF
[Unit]
Description=MTProto Proxy on port $PORT
After=network.target

[Service]
Type=simple
ExecStart=$MTG_PATH/mtg run --bind-to 0.0.0.0:$PORT --secret "$SECRET" --tls "$DOMAIN"
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable mtg@$PORT
    systemctl start mtg@$PORT
done

iptables-save > /etc/iptables/rules.v4

echo "✅ 全部 $INSTANCE_COUNT 个代理已部署。"
echo "代理链接已保存到：$MTG_PATH/proxies.txt"
cat $MTG_PATH/proxies.txt
