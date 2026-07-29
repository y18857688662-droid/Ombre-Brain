#!/bin/bash
# Ombre Brain VPS 部署脚本
# curl -sL https://raw.githubusercontent.com/y18857688662-droid/Ombre-Brain/main/setup-vps.sh | bash

set -e

echo "=== Ombre Brain 部署开始 ==="

# 1. 安装 Python 依赖
echo "检查 Python..."
if ! command -v python3 &> /dev/null; then
  apt-get update && apt-get install -y python3 python3-pip python3-venv
fi
echo "Python: $(python3 --version)"

# 2. 克隆代码
if [ -d /root/ombre-brain ]; then
  echo "更新代码..."
  cd /root/ombre-brain && git pull
else
  echo "克隆代码..."
  cd /root && git clone https://github.com/y18857688662-droid/Ombre-Brain.git ombre-brain
fi
cd /root/ombre-brain

# 3. 创建虚拟环境并安装依赖
echo "安装依赖..."
python3 -m venv venv 2>/dev/null || true
source venv/bin/activate
pip install -r requirements.txt

# 4. 创建配置
if [ ! -f config.yaml ]; then
  echo "创建配置..."
  cp config.example.yaml config.yaml
  sed -i 's/transport: "stdio"/transport: "streamable-http"/' config.yaml
  sed -i 's/mcp_require_auth: true/mcp_require_auth: false/' config.yaml
fi

# 5. 创建 systemd 服务
echo "创建服务..."
cat > /etc/systemd/system/ombre-brain.service << SVC
[Unit]
Description=Ombre Brain Memory Store
After=network.target

[Service]
Type=simple
WorkingDirectory=/root/ombre-brain
ExecStart=/root/ombre-brain/venv/bin/python /root/ombre-brain/src/server.py
Restart=always
RestartSec=5
Environment=PORT=8060
Environment=OMBRE_COMPRESS_API_KEY=${OMBRE_COMPRESS_API_KEY:-}
Environment=OMBRE_EMBED_API_KEY=${OMBRE_EMBED_API_KEY:-}
Environment=OMBRE_MCP_REQUIRE_AUTH=false

[Install]
WantedBy=multi-user.target
SVC

systemctl daemon-reload
systemctl enable ombre-brain
systemctl start ombre-brain
echo "Ombre Brain 服务已启动 (端口 8060)"

# 6. 添加 nginx 配置
echo "配置 nginx..."
cat > /etc/nginx/sites-available/ombre-brain << 'NGINX'
server {
    listen 8061 ssl;
    server_name yyaokeke.top;

    ssl_certificate /etc/letsencrypt/live/yyaokeke.top/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yyaokeke.top/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8060;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_read_timeout 86400;
    }
}
NGINX

ln -sf /etc/nginx/sites-available/ombre-brain /etc/nginx/sites-enabled/ombre-brain
ufw allow 8061 2>/dev/null || true
nginx -t && systemctl reload nginx

echo ""
echo "=== Ombre Brain 部署完成！==="
echo "MCP 端点: https://yyaokeke.top:8061/mcp"
echo ""
echo "如需设置API密钥，编辑服务文件:"
echo "  nano /etc/systemd/system/ombre-brain.service"
echo "  修改 OMBRE_COMPRESS_API_KEY 和 OMBRE_EMBED_API_KEY"
echo "  然后: systemctl daemon-reload && systemctl restart ombre-brain"
