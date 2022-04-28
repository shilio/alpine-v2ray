#!/bin/sh -e

## update system
apk update && apk upgrade

## install curl wget unzip git 
apk add -t base-tools curl wget unzip nano bash
apk add caddy
# install xray
wget https://github.com/XTLS/Xray-core/releases/download/v1.5.4/Xray-linux-64.zip
unzip -d xray Xray-linux-64.zip
mv xray/xray /usr/bin/xray
rm -rf Xray-linux-64.zip xray
mkdir /etc/xray
cat > /etc/xray/config.json << EOF
{
    "log": {
        "loglevel": "warning"
    },
    "inbounds": [
        {
            "port": 1325,
            "listen": "127.0.0.1",
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "aff4fc35-d91a-4aed-8a22-6540d356e738", // 填写你的 UUID
                        "level": 0,
                        "email": "fck_gfw@gmail.com"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "ws",
                "security": "none",
                "wsSettings": {
                    "path": "/up2ws" // 必须换成自定义的 PATH，需要和上面的一致
                }
            }
        }
    ],
    "outbounds": [
        {
            "protocol": "freedom"
        }
    ]
}
EOF
cat > /etc/init.d/xray <<EOF
#!/sbin/openrc-run
supervisor=supervise-daemon

name="Xray proxy server"
description="Xray, Penetrates Everything. Also the best v2ray-core, with XTLS support. Fully compatible configuration."

: ${xray_opts:="-config /etc/xray/config.json"}

command=/usr/bin/xray
command_args="run $xray_opts"
command_user=nobody:nobody

depend() {
        need net localmount
        after firewall
}

EOF

chmod a+x /etc/init.d/xray

cat >> /etc/caddy/Caddyfile << EOF
$1 {
        root * /usr/share/caddy
        file_server
        reverse_proxy /up2ws 127.0.0.1:1325
        tls fck_gfw@gmail.com
}
EOF
service caddy restart
service xray restart
rc-update add caddy
rc-update add xray

cat >> .profile <<EOF
alias ltnp='netstat -ltnp'
alias ltunp='netstat -ltunp'
alias ls='ls -lAh --color=auto'
alias du='du -h'
alias df='df -h'
EOF
. .profile
