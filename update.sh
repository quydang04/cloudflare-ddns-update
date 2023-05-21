#!/bin/bash
#Last modified: 21/05/2023

# Cập nhật thông tin dưới đây

CLOUDFLARE_EMAIL="your_email@example.com" # Nhập mail mà bạn đang sử dụng cloudflare vào đây!
CLOUDFLARE_API_KEY="your_cloudflare_api_key" # Nhập Global API key của bạn!
DOMAIN="example.com"  # Dòng này đã thay cho dòng nhập zone id vì vậy hãy nhập vào nhé!
SUBDOMAIN="sub.example.com" # Hãy nhập domain mà bạn muốn cập nhật ddns vào đây!

# Không cần thay đổi phần dưới đây

echo "------------------------------------------------------------------------"
echo "Đang kiểm tra IP, vui lòng đợi trong giây lát!!!!"
echo "------------------------------------------------------------------------"
echo ""

IP=$(curl -s https://quydang.name.vn/ip.php)
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json" | grep -Po '(?<="id":")[^"]*' | head -1)

record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json")

RECORD_ID=$(echo "$record_info" | grep -Po '(?<="id":")[^"]*' | head -1)
OLD_IP=$(echo "$record_info" | grep -Po '(?<="content":")[^"]*')

if [ "$OLD_IP" == "$IP" ]; then
  echo "$(date): Không cần cập nhật cho $SUBDOMAIN (IP hiện tại: $OLD_IP)"
else
  update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
    -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
    -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$SUBDOMAIN'","content":"'$IP'","ttl":1,"proxied":false}')
  echo "$(date): Đã cập nhật bản ghi DNS cho $SUBDOMAIN từ $OLD_IP thành $IP"
fi
