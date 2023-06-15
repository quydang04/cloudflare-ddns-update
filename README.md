# Cloudflare DDNS Update
#### Cập nhật địa chỉ IP cho tên miền của bạn thông qua Cloudflare API
## Cách sử dụng
##### Bước 1: Tải file về máy
```` 
wget https://t.ly/jd55t
````
##### Bước 2: Cấp cho file có quyền thực thi
````
chmod +x cloudflare_ddns_update.sh
````
##### Bước 3: Chạy file
````
./cloudflare_ddns_update.sh
````
##### Bước 4: Tạo 1 cron mỗi 3 phút cập nhật 1 lần
````
crontab -e
````
##### Sau đó:
````
*/3 * * * * path/to/cloudflare_ddns_update.sh
````
### Lưu ý: Trước khi chạy hãy nhớ chỉnh lại các phần như zone id, domain,v.v nhé. 
#### Để chỉnh lại bằng lệnh
````
nano cloudflare_ddns_update.sh
````
#### Hoặc 
````
vim cloudflare_ddns_update.sh
````
