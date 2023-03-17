#!/bin/bash

# Cập nhật thông tin dưới đây

CLOUDFLARE_EMAIL="your_email@example.com" // Nhập mail mà bạn đang sử dụng cloudflare vào đây!
CLOUDFLARE_API_KEY="your_cloudflare_api_key" // Nhập Global API key của bạn!
DOMAIN="example.com"  // Hãy nhập domain của bạn, không được bỏ dòng này bới vì khi bạn nhập domain của bạn vào đây thì sẽ tự động lấy zone id về để cập nhật ddns cho domain của bạn. Đó chính là vì sao bạn không thấy dòng nhập zone id là bởi vì dòng này đã thay cho nhập zone id!
SUBDOMAIN="sub.example.com" // Hãy nhập domain mà bạn muốn cập nhật ddns vào đây!

# Không cần thay đổi phần dưới đây

 echo "------------------------------------------------------------------------"
 echo "Đang kiểm tra IP, vui lòng đợi trong giây lát!!!! 
 echo "------------------------------------------------------------------------"
 echo ""
IP=$(curl -s https://api.ipify.org)
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
  echo "Địa chỉ IP cũ và mới giống nhau, không cần cập nhật DDNS."
  echo ""
  exit 0
fi

response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
  -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
  -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
  -H "Content-Type: application/json" \
  --data '{"type":"A","name":"'"$SUBDOMAIN"'","content":"'"$IP"'","ttl":1,"proxied":false}')

success=$(echo "$response" | grep -Po '(?<="success":)[^,]*')
modified=$(echo "$response" | grep -Po '(?<="modified_on":")[^"]*')
modified_readable=$(date -d "${modified}" +"%Y-%m-%d %H:%M:%S")

if [ "$success" == "true" ]; then
  echo "Cập nhật DDNS thành công!"
  echo "Tên miền phụ: $SUBDOMAIN"
  echo "Địa chỉ IP cũ: $OLD_IP"
  echo "Địa chỉ IP mới: $IP"
  echo "Thời gian cập nhật: $modified_readable"
  echo ""
else
  echo "Có lỗi xảy ra trong quá trình cập nhật DDNS."
  echo "Phản hồi từ Cloudflare API:"
  echo "$response"
  echo ""
fi
