# Last modified: 10/06/2023
#!/bin/bash

# Cập nhật thông tin dưới đây

CLOUDFLARE_EMAIL="your_email@example.com" # Nhập mail mà bạn đang sử dụng cloudflare vào đây!
CLOUDFLARE_API_KEY="your_cloudflare_api_key" # Nhập Global API key của bạn!
DOMAIN="example.com"  # Dòng này đã thay cho dòng nhập zone id vì vậy hãy nhập vào nhé!
SUBDOMAIN="sub.example.com" # Hãy nhập domain mà bạn muốn cập nhật ddns vào đây!

# Không cần thay đổi phần dưới đây

echo "------------------------------------------------------------------------"
echo "Xin chào bạn đã đến với trình cập nhật DDNS!"
echo "Vui lòng chọn các tùy chọn bên dưới!"
echo "------------------------------------------------------------------------"


select option in "Cập nhật DDNS" "Thoát"; do
  case $option in
    "Cập nhật DDNS")
      echo "------------------------------------------------------------------------"
      echo "Đang cập nhật IP, vui lòng đợi trong giây lát!!!!"
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
        echo "Đã cập nhật thành công!"
        break
      else
        update=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records/$RECORD_ID" \
          -H "X-Auth-Email: $CLOUDFLARE_EMAIL" \
          -H "X-Auth-Key: $CLOUDFLARE_API_KEY" \
          -H "Content-Type: application/json" \
          --data '{"type":"A","name":"'$SUBDOMAIN'","content":"'$IP'","ttl":1,"proxied":false}')
        echo "$(date +'%d/%m/%Y %H:%M:%S'): Đã cập nhật bản ghi DNS cho $SUBDOMAIN từ $OLD_IP thành $IP"
        
        echo "Đã thoát..."
        break
      fi
      ;;
    "Thoát")
      echo "Tạm biệt bạn."
      break
      ;;
    *) echo "Tùy chọn không hợp lệ, vui lòng chọn lại.";;
  esac
done
