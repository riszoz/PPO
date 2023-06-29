#!/usr/bin/env bash
# 其他Paas保活
PAAS1=
PAAS2=
PAAS3=

# koyeb账号保活
KOYEB_ACCOUNT=
KOYEB_PASSWORD=

# Argo 固定域名隧道的两个参数,这个可以填 Json 内容或 Token 内容，获取方式看 https://github.com/fscarmen2/X-for-Glitch，不需要的话可以留空，删除或在这三行最前面加 # 以注释
ARGO_AUTH='{"AccountTag":"1feb11313918ecdeb60227fd673eca9f","TunnelSecret":"mLtxYzLXxPk9yLoAISOY4S3l4ZFSIJF6sIazs1N73o0=","TunnelID":"52793043-e9f0-4da6-b8d6-84f7e2f9a576"}'
ARGO_DOMAIN=zore.boy.yn.to

generate_argo() {
  cat > argo.sh << ABC
#!/usr/bin/env bash

ARGO_AUTH=${ARGO_AUTH}
ARGO_DOMAIN=${ARGO_DOMAIN}

# 下载并运行 Argo
check_file() {
  [ ! -e cloudflared ] && wget -O cloudflared https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 && chmod +x cloudflared
}

run() {
  if [[ -n "\${ARGO_AUTH}" && -n "\${ARGO_DOMAIN}" ]]; then
    [[ "\$ARGO_AUTH" =~ TunnelSecret ]] && echo "\$ARGO_AUTH" | sed 's@{@{"@g;s@[,:]@"\0"@g;s@}@"}@g' > tunnel.json && echo -e "tunnel: \$(sed "s@.*TunnelID:\(.*\)}@\1@g" <<< "\$ARGO_AUTH")\ncredentials-file: /app/tunnel.json" > tunnel.yml && ./cloudflared tunnel --edge-ip-version auto --config tunnel.yml --url http://localhost:8080 run 2>&1 &
    [[ \$ARGO_AUTH =~ ^[A-Z0-9a-z=]{120,250}$ ]] && ./cloudflared tunnel --edge-ip-version auto run --token ${ARGO_AUTH} 2>&1 &
  else
    ./cloudflared tunnel --edge-ip-version auto --no-autoupdate --logfile argo.log --loglevel info --url http://localhost:8080 2>&1 &
    sleep 5
    ARGO_DOMAIN=\$(cat argo.log | grep -o "info.*https://.*trycloudflare.com" | sed "s@.*https://@@g" | tail -n 1)
  fi
}

export_list() {
  VMESS="{ \"v\": \"2\", \"ps\": \"Argo-Vmess\", \"add\": \"icook.hk\", \"port\": \"443\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"\${ARGO_DOMAIN}\", \"path\": \"/${WSPATH}-vmess?ed=2048\", \"tls\": \"tls\", \"sni\": \"\${ARGO_DOMAIN}\", \"alpn\": \"\" }"
  cat > list << EOF
*******************************************
V2-rayN:
----------------------------
vless://${UUID}@icook.hk:443?encryption=none&security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-vless?ed=2048#Argo-Vless
----------------------------
vmess://\$(echo \$VMESS | base64 -w0)
----------------------------
trojan://${UUID}@icook.hk:443?security=tls&sni=\${ARGO_DOMAIN}&type=ws&host=\${ARGO_DOMAIN}&path=%2F${WSPATH}-trojan?ed=2048#Argo-Trojan
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@icook.hk:443" | base64 -w0)@icook.hk:443#Argo-Shadowsocks
由于该软件导出的链接不全，请自行处理如下: 传输协议: WS ， 伪装域名: \${ARGO_DOMAIN} ，路径: /${WSPATH}-shadowsocks?ed=2048 ， 传输层安全: tls ， sni: \${ARGO_DOMAIN}
*******************************************
小火箭:
----------------------------
vless://${UUID}@icook.hk:443?encryption=none&security=tls&type=ws&host=\${ARGO_DOMAIN}&path=/${WSPATH}-vless?ed=2048&sni=\${ARGO_DOMAIN}#Argo-Vless
----------------------------
vmess://$(echo "none:${UUID}@icook.hk:443" | base64 -w0)?remarks=Argo-Vmess&obfsParam=\${ARGO_DOMAIN}&path=/${WSPATH}-vmess?ed=2048&obfs=websocket&tls=1&peer=\${ARGO_DOMAIN}&alterId=0
----------------------------
trojan://${UUID}@icook.hk:443?peer=\${ARGO_DOMAIN}&plugin=obfs-local;obfs=websocket;obfs-host=\${ARGO_DOMAIN};obfs-uri=/${WSPATH}-trojan?ed=2048#Argo-Trojan
----------------------------
ss://$(echo "chacha20-ietf-poly1305:${UUID}@icook.hk:443" | base64 -w0)?obfs=wss&obfsParam=\${ARGO_DOMAIN}&path=/${WSPATH}-shadowsocks?ed=2048#Argo-Shadowsocks
*******************************************
Clash:
----------------------------
- {name: Argo-Vless, type: vless, server: icook.hk, port: 443, uuid: ${UUID}, tls: true, servername: \${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: {path: /${WSPATH}-vless?ed=2048, headers: { Host: \${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: Argo-Vmess, type: vmess, server: icook.hk, port: 443, uuid: ${UUID}, alterId: 0, cipher: none, tls: true, skip-cert-verify: true, network: ws, ws-opts: {path: /${WSPATH}-vmess?ed=2048, headers: {Host: \${ARGO_DOMAIN}}}, udp: true}
----------------------------
- {name: Argo-Trojan, type: trojan, server: icook.hk, port: 443, password: ${UUID}, udp: true, tls: true, sni: \${ARGO_DOMAIN}, skip-cert-verify: false, network: ws, ws-opts: { path: /${WSPATH}-trojan?ed=2048, headers: { Host: \${ARGO_DOMAIN} } } }
----------------------------
- {name: Argo-Shadowsocks, type: ss, server: icook.hk, port: 443, cipher: chacha20-ietf-poly1305, password: ${UUID}, plugin: v2ray-plugin, plugin-opts: { mode: websocket, host: \${ARGO_DOMAIN}, path: /${WSPATH}-shadowsocks?ed=2048, tls: true, skip-cert-verify: false, mux: false } }
*******************************************
EOF
  cat list
}
check_file
run
export_list
ABC
}

# Paas保活
generate_keeplive() {
  cat > paaslive.sh << EOF
#!/usr/bin/env bash

# 传参
PAAS1=${PAAS1}
PAAS2=${PAAS2}
PAAS3=${PAAS3}

# 判断变量并保活
if [ -n "\${PAAS1}" ] && [ -n "\${PAAS2}" ] && [ -n "\${PAAS3}" ]; then
  while true; do
    curl \${PAAS1}
    curl \${PAAS2}
    curl \${PAAS3}
    rm -rf /dev/null
    sleep 240
  done
elif [ -n "\${PAAS1}" ] && [ -n "\${PAAS2}" ]; then
  while true; do
    curl \${PAAS1}
    curl \${PAAS2}
    rm -rf /dev/null
    sleep 240
  done
elif [ -n "\${PAAS1}" ]; then
  while true; do
    curl \${PAAS1}
    rm -rf /dev/null
    sleep 240
  done
else
  exit 1
fi
EOF
}

# koyeb保活
generate_koyeb() {
  cat > koyeb.sh << EOF
#!/usr/bin/env bash

# 传参
KOYEB_ACCOUNT=${KOYEB_ACCOUNT}
KOYEB_PASSWORD=${KOYEB_PASSWORD}

# 两个变量不全则不运行保活
check_variable() {
  [[ -z "\${KOYEB_ACCOUNT}" || -z "\${KOYEB_ACCOUNT}" ]] && exit
}

# 开始保活
run() {
while true
do
  curl -sX POST https://app.koyeb.com/v1/account/login -H 'Content-Type: application/json' -d '{"email":"'"\${KOYEB_ACCOUNT}"'","password":"'"\${KOYEB_PASSWORD}"'"}'
  rm -rf /dev/null
  sleep $((60*60*24*5))
done
}
check_variable
run
EOF
}

generate_pm2_file() {
    cat > ecosystem.config.js << EOF
module.exports = {
  "apps":[
      {
          "name":"PPO",
          "script":"/app/PPO run"
      }
  ]
}
EOF
}

generate_argo
generate_keeplive
generate_koyeb
generate_pm2_file
[ -e argo.sh ] && bash argo.sh
[ -e paaslive.sh ] && nohup bash paaslive.sh >/dev/null 2>&1 &
[ -e koyeb.sh ] && nohup bash koyeb.sh >/dev/null 2>&1 &
[ -e ecosystem.config.js ] && pm2 start
