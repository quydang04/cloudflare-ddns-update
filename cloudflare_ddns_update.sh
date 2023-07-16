# Last modified: 02/07/2023
#!/bin/bash

# Cap nhat hoac chinh sua thong tin duoi day
CLOUDFLARE_EMAIL="" # Nhap email ma ban da dang ky tai khoan cloudflare.
CLOUDFLARE_API_KEY="" # Nhap api key cho tai khoan cloudflare cua ban.
DOMAIN="" # Dong nay thay cho ZONE_ID, neu ban khong nhap thi se khong cap nhat duoc cho ten mien cua ban.
SUBDOMAIN="" # Nhap ten mien ma ban muon cap nhat ddns vao day!

# Khong can thay doi phan duoi day, neu ban thay doi se gay ra loi!!!!

# Kiem tra va thong bao neu thieu cac thong tin
if [[ -z "$CLOUDFLARE_EMAIL" || -z "$CLOUDFLARE_API_KEY" || -z "$DOMAIN" || -z "$SUBDOMAIN" ]]; then
  echo "Vui long cung cap day du thong tin nhu CLOUDFLARE_EMAIL, CLOUDFLARE_API_KEY, DOMAIN, SUBDOMAIN."
  exit 1
fi

echo "------------------------------------------------------------------------"
echo "Dang cap nhat IP, vui long doi trong giay lat!"
echo "------------------------------------------------------------------------"
echo ""

IP=$(curl -s https://ip.quydang.name.vn)
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)

if [ -z "$ZONE_ID" ]; then
  echo "Khong tim thay ten mien $DOMAIN trong ban ghi DNS cua Cloudflare. Vui long kiem tra lai!"
  exit 1
fi

record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json")

RECORD_ID=$(echo "$record_info" | grep -Po '(?<="id":")[^"]*' | head -1)
OLD_IP=$(echo "$record_info" | grep -Po '(?<="content":")[^"]*')

if [ -z "$RECORD_ID" ]; then
  echo "Ban ghi DNS cho ten mien $SUBDOMAIN chua duoc them hoac khong hop le tren Cloudflare. Vui long kiem tra lai!"
  exit 1
fi

if [ "$OLD_IP" == "$IP" ]; then
  echo "$(date +'%d/%m/%Y %H:%M:%S'): Khong can cap nhat cho $SUBDOMAIN (IP hien tai: $OLD_IP)"
else
  update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$SUBDOMAIN'","content":"'$IP'","ttl":1,"proxied":false}')
  echo "$(date +'%d/%m/%Y %H:%M:%S'): Da cap nhat ban ghi DNS cho $SUBDOMAIN tu $OLD_IP thanh $IP"
fi

echo "Da thoat..."
