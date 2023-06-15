# Last modified: 15/06/2023
#!/bin/bash

# Cập nhật thông tin dưới đây
CLOUDFLARE_EMAIL="" # Nhập email mà bạn đã đăng ký tài khoản cloudflare.
CLOUDFLARE_API_KEY="" # Nhập api key cho tài khoản cloudflare của bạn.
DOMAIN="" # Dòng này thay cho ZONE_ID, nếu bạn không nhập thì sẽ không cập nhật được cho tên miền của bạn.
SUBDOMAIN="" # Nhập tên miền mà bạn muốn cập nhật ddns vào đây!

# Kiểm tra và thông báo nếu thiếu các thông tin
if [[ -z "$CLOUDFLARE_EMAIL" || -z "$CLOUDFLARE_API_KEY" || -z "$DOMAIN" || -z "$SUBDOMAIN" ]]; then
  echo "Vui lòng cung cấp đầy đủ thông tin như CLOUDFLARE_EMAIL, CLOUDFLARE_API_KEY, DOMAIN, SUBDOMAIN."
  exit 1
fi

echo "------------------------------------------------------------------------"
echo "Đang cập nhật IP, vui lòng đợi trong giây lát!"
echo "------------------------------------------------------------------------"
echo ""

IP=$(curl -s https://quydang.name.vn/ip.php)
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)

if [ -z "$ZONE_ID" ]; then
  echo "Không tìm thấy tên miền $DOMAIN trong bản ghi DNS của Cloudflare. Vui lòng kiểm tra lại!"
  exit 1
fi

record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json")

RECORD_ID=$(echo "$record_info" | grep -Po '(?<="id":")[^"]*' | head -1)
OLD_IP=$(echo "$record_info" | grep -Po '(?<="content":")[^"]*')

if [ -z "$RECORD_ID" ]; then
  echo "Bản ghi DNS cho tên miền $SUBDOMAIN chưa được thêm hoặc không hợp lệ trên Cloudflare. Vui lòng kiểm tra lại!"
  exit 1
fi

if [ "$OLD_IP" == "$IP" ]; then
  echo "$(date +'%d/%m/%Y %H:%M:%S'): Không cần cập nhật cho $SUBDOMAIN (IP hiện tại: $OLD_IP)"
else
  update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$SUBDOMAIN'","content":"'$IP'","ttl":1,"proxied":false}')
  echo "$(date +'%d/%m/%Y %H:%M:%S'): Đã cập nhật bản ghi DNS cho $SUBDOMAIN từ $OLD_IP thành $IP"
fi

echo "Đã thoát..."
