#!/bin/bash

while true; do
  echo "------------------------------------------------------------------------"
  echo "Xin chào! Chào mừng bạn đến với công cụ cập nhật DDNS!"
  echo "Vui lòng chọn một tùy chọn:"
  echo "1. Cập nhật DDNS"
  echo "2. Thoát"

  read -p "Nhập lựa chọn của bạn: " choice

  case $choice in
    1)
      echo "------------------------------------------------------------------------"
      echo "Vui lòng cung cấp thông tin dưới đây:"
      echo "------------------------------------------------------------------------"

      read -p "Email Cloudflare: " CLOUDFLARE_EMAIL
      read -p "API Key Cloudflare: " CLOUDFLARE_API_KEY
      read -p "Nhập tên miền cần cập nhật (thay cho ZONE_ID): " DOMAIN
      read -p "Tên miền con cần cập nhật: " SUBDOMAIN

      # Kiểm tra các thông số đã được set hay chưa
      if [ -z "$CLOUDFLARE_EMAIL" ] || [ -z "$CLOUDFLARE_API_KEY" ] || [ -z "$DOMAIN" ] || [ -z "$SUBDOMAIN" ]; then
        echo "Vui lòng cung cấp đầy đủ thông tin trước khi tiếp tục!"
        continue
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
        continue
      fi

      record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN" \
        -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
        -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
        -H "Content-Type: application/json")

      RECORD_ID=$(echo "$record_info" | grep -Po '(?<="id":")[^"]*' | head -1)
      OLD_IP=$(echo "$record_info" | grep -Po '(?<="content":")[^"]*')

      if [ -z "$RECORD_ID" ]; then
        echo "Bản ghi DNS cho tên miền $SUBDOMAIN chưa được thêm hoặc không hợp lệ trên Cloudflare. Vui lòng kiểm tra lại!"
        continue
      fi

      if [ "$OLD_IP" == "$IP" ]; then
        echo "$(date +'%d/%m/%Y %H:%M:%S'): Không cần cập nhật cho $SUBDOMAIN (IP hiện tại: $OLD_IP)"
        echo "Tiếp tục..."
      else
        update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
          -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
          -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
          -H "Content-Type: application/json" \
          --data '{"type":"A","name":"'$SUBDOMAIN'","content":"'$IP'","ttl":1,"proxied":false}')
        echo "$(date +'%d/%m/%Y %H:%M:%S'): Đã cập nhật bản ghi DNS cho $SUBDOMAIN từ $OLD_IP thành $IP"
      fi
      ;;
    2)
      echo "Thoát..."
      break
      ;;
    *)
      echo "Lựa chọn không hợp lệ. Vui lòng chọn lại."
      ;;
  esac
done
