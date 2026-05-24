# Rclone sync service (`docker-compose/compose.rclone.yml`)

## Vai trò
- Đồng bộ một chiều dữ liệu từ `.docker-volumes/` local lên remote storage khi local/remote khác nhau.
- Local là nguồn sự thật để app đọc/ghi nhanh; remote là nơi backup/sync.
- Config rclone lấy từ base64 trong `.env`, không cần commit `rclone.conf` thật.
- Hỗ trợ remote cấu hình dạng union (`type = union`, `list_action = join`) nếu bạn khai báo trong rclone config.

## Compose layer
- File: `docker-compose/compose.rclone.yml`.
- Kích hoạt qua `ENABLE_RCLONE=true` trong `.env`.
- Service chạy độc lập ở chế độ sidecar, không mount FUSE vào app.

## Services
### `rclone`
- Image: `rclone/rclone:latest`
- Profile: `rclone`
- Entrypoint: `/entrypoint.sh` mount từ `services/rclone/entrypoint.sh`.
- Volumes mount:
  - Script chạy: `./services/rclone/entrypoint.sh` vào `/entrypoint.sh:ro`.
  - Dữ liệu: `${DOCKER_VOLUMES_ROOT:-./.docker-volumes}` vào `/data`.

## ENV bắt buộc
- `ENABLE_RCLONE`: `true|false`, bật/tắt profile Rclone trong `dc.sh`.
- `9ROUTER_RCLONE_CONFIG_BASE64`: nội dung `rclone.conf` đã encode base64.
- `RCLONE_REMOTE_TARGET`: remote đích để đồng bộ, định dạng `remote_name:path/to/bucket`.

## ENV tùy chọn
- `RCLONE_SYNC_INTERVAL_SEC`: giây giữa 2 lần kiểm tra, mặc định `20`.
- `RCLONE_LOCAL_PATH`: thư mục dữ liệu nguồn trong container, mặc định `/data`.
- `RCLONE_LOG_LEVEL`: mức log của rclone, mặc định `NOTICE`.
- `RCLONE_DRY_RUN`: chạy thử không ghi dữ liệu thật, `true|false`.
- `RCLONE_EXTRA_FLAGS`: tham số bổ sung cho `rclone check` và `rclone sync`.
- `RCLONE_CHECK_FLAGS`: tham số cho `rclone check`, mặc định `--one-way`.

## Hướng dẫn setup và sử dụng
1. Tạo cấu hình thật bằng `rclone config`.
2. Encode config:
   ```bash
   base64 -w0 services/rclone/rclone.conf
   ```
3. Dán kết quả vào `.env`:
   ```env
   ENABLE_RCLONE=true
   9ROUTER_RCLONE_CONFIG_BASE64=<base64-rclone-conf>
   RCLONE_REMOTE_TARGET=remote_store:ten-bucket-cua-ban/docker-volumes
   ```
4. Khởi động dịch vụ:
   ```bash
   bash docker-compose/scripts/dc.sh up -d rclone
   ```
5. Kiểm tra log đồng bộ:
   ```bash
   bash docker-compose/scripts/dc.sh logs -f rclone
   ```
