# App service (`compose.apps.yml`)

## Vai trò
- Service ứng dụng chính hiện chạy 9Router từ source trong `services/app`.
- 9Router cung cấp dashboard auth riêng và OpenAI-compatible proxy endpoint.

## Cấu hình chính
- Image local tag: `${APP_IMAGE:-o9router-app:0.4.59-local}`
- Build context: `./services/app`
- Internal port mặc định: `${APP_PORT:-20128}`
- Host port local: `127.0.0.1:${APP_HOST_PORT:-20128}:${APP_PORT:-20128}`
- Data volume: `${DOCKER_VOLUMES_ROOT:-./.docker-volumes}/app/data:/app/data`
- Logs volume: `${DOCKER_VOLUMES_ROOT:-./.docker-volumes}/app/logs:/app/logs`
- Healthcheck: `wget http://localhost:${APP_PORT}${HEALTH_PATH}` với `HEALTH_PATH=/api/health`

## ENV bắt buộc
- `APP_PORT`: port app lắng nghe trong container, mặc định `20128`.
- `APP_HOST_PORT`: port publish localhost trên host, mặc định `20128`.
- `APP_IMAGE`: tag image build cho app.
- `PROJECT_NAME`, `DOMAIN`: tạo hostname public qua Caddy labels.

## 9Router ENV
- Các biến runtime của upstream được khai báo ở cuối `.env.example` và `.env` với prefix `9ROUTER_`.
- `services/app/docker-entrypoint.sh` map `9ROUTER_*` sang env gốc mà 9Router đọc, ví dụ `9ROUTER_JWT_SECRET` thành `JWT_SECRET`.
- `APP_PORT` vẫn là source of truth cho `PORT`; compose set `PORT=${APP_PORT}`.

## Routing và auth
- Public host: `${PROJECT_NAME}.${DOMAIN}` cùng alias `main.${DOMAIN}`, `${DOMAIN}`.
- Internal HTTPS host: `${PROJECT_NAME_TAILSCALE}.${TAILSCALE_TAILNET_DOMAIN}` với `tls internal`.
- App route không dùng Tinyauth `forward_auth`; đăng nhập dùng auth mặc định của 9Router.
- Tinyauth vẫn có thể chạy cho các service khác trong `docker-compose/compose.auth.yml`.

## Data và rclone
- Data app lưu local tại `${DOCKER_VOLUMES_ROOT}/app/data` để ưu tiên hiệu năng.
- Không dùng Litestream cho 9Router theo task này.
- Nếu cần sync remote, bật `ENABLE_RCLONE=true`, set `RCLONE_REMOTE_TARGET`, và dán rclone config base64 vào `9ROUTER_RCLONE_CONFIG_BASE64`.
- Rclone sidecar chỉ chạy `rclone sync` khi `rclone check` phát hiện local/remote khác nhau, tránh xung đột với mount FUSE.
