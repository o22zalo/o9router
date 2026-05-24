# Task: Swap App — Triển khai app mới thay thế `services/app`

---

## User prompt

> Dán yêu cầu của user tại đây. Bao gồm đầy đủ các spec bên dưới.

### Spec 1 — App mô tả

> Triển khai 9router theo repo github: https://github.com/decolua/9router
> Ưu tiên sử dụng docker, có phiên bản triển khai
> Data app sqlite, enable rclone, mount remote để chứa file data này
>
> - Dữ liệu lưu tại local data để hiệu năng cao nhất
> - Dùng rclone union với remote để đồng bộ lên remote
> - rclone config sẽ là base64 từ .env

### Spec 2 — Source code

> Source code app mới sẽ thay thế toàn bộ thư mục `services/app`.

### Spec 3 — Docker Compose (`compose.apps.yml`)

> Dựa vào tài liệu của repo trên triển khai
> Internal port (APP_PORT): `20128` theo mặc định của repo
> Không auth qua tinuauth, auth mặc định của app 9router

### Spec 4 — ENV mới (`.env.example`)

> Có tất cả env là repo trên hỗ trợ, có ghi giá trị mặc định để thay đổi khi cần
> Liệt kê các biến ENV mới cần thêm vào `.env.example` và `.env` ở cuối file và prefix phải là `9ROUTER_`.
>
> **Yêu cầu bắt buộc khi liệt kê:**
>
> - Mỗi biến **phải có comment** diễn giải rõ mục đích, ảnh hưởng khi thay đổi.
> - Nếu biến có **tập giá trị cố định** → comment **toàn bộ giá trị hợp lệ** kèm tác dụng từng giá trị.
> - Nếu giá trị cần **lấy từ web** (API key, secret, token…) → ghi rõ **link** và **hướng dẫn ngắn** cách lấy.
>
> **Ví dụ format:**
>
> ```dotenv
> # Môi trường chạy ứng dụng.
> # Giá trị hợp lệ:
> #   development  → bật hot-reload, log verbose, tắt cache
> #   staging      → giống production nhưng dùng DB test
> #   production   → tắt debug, bật cache, gửi error lên Sentry
> APP_ENV=development
>
> # Cấp độ log output.
> # Giá trị hợp lệ: error | warn | info | debug | trace
> #   error  → chỉ lỗi nghiêm trọng
> #   warn   → lỗi + cảnh báo
> #   info   → thêm sự kiện chính (mặc định production)
> #   debug  → thêm luồng xử lý nội bộ
> #   trace  → toàn bộ, rất verbose
> LOG_LEVEL=info
> ```

> # Secret key dùng để ký JWT token.
>
> # Lấy tại: https://your-auth-provider.com/dashboard → Settings → API Keys
>
> # Hướng dẫn: Đăng nhập → chọn project → Copy "Secret Key"
>
> # ⚠️ KHÔNG commit giá trị thật lên Git.
>
> MY_APP_SECRET=change-me
>
> ```
>
> Nếu không có ENV mới: ghi `"Không cần thêm ENV mới."`
> ```

### Spec 5 — SQLite / Litestream

> Không dùng

### Spec 6 — Thông tin bổ sung

> Thêm sidebar để dùng rclone sync local lên remote, kiểm tra khoảng thời gian, mà có khác giữa local và remote, thì chạy riêng lệnh sync, tránh xung đột với mount fs của rclone

---

## Thông tin cần xác nhận

Agent điền mục này nếu prompt thiếu dữ liệu cần thiết để triển khai đúng.

- [x] Không cần hỏi thêm
- [ ] Cần hỏi user trước khi làm

Câu hỏi cần xác nhận:

- ***

## Checklist triển khai

Agent tự tạo checklist từ các Spec ở trên, rồi đánh dấu khi từng bước hoàn tất.

### Phase 0 — Đọc hiểu & xác nhận

- [x] Đọc yêu cầu user và xác định phạm vi thay đổi
- [x] Kiểm tra rule bắt buộc trong `AGENTS.md`
- [x] Đọc `AGENT_APP_SWAP.md` để nắm invariants (Scope And Invariants, mục 2)
- [x] Xác nhận đủ 6 Spec — nếu thiếu, hỏi user trước khi làm

### Phase 1 — Chuẩn bị source code

- [x] Xóa toàn bộ nội dung `services/app/` (giữ thư mục)
- [x] Copy source code app mới vào `services/app/`
- [x] Kiểm tra / tạo `services/app/Dockerfile` phù hợp runtime mới
- [x] Kiểm tra `.dockerignore` trong `services/app/` (tạo nếu cần)

### Phase 2 — Cập nhật compose.apps.yml

- [x] Sửa `compose.apps.yml` theo Spec 3 (image/build, port, env, volumes, labels, healthcheck)
- [x] Giữ đúng invariants từ `AGENT_APP_SWAP.md`:
  - Service name vẫn là `app`
  - Container name vẫn là `main-app`
  - Network vẫn là `app_net`
  - `APP_PORT` là source of truth cho port
  - Healthcheck phải có
  - Caddy labels dùng env vars, không hard-code domain
- [x] Auth labels: thêm/giữ/bỏ `forward_auth` theo Spec 3

### Phase 3 — Cập nhật .env.example

- [x] Thêm ENV mới theo Spec 4 vào section `APPLICATION` trong `.env.example`
- [x] Cập nhật `APP_IMAGE`, `APP_PORT`, `HEALTH_PATH` nếu khác mặc định
- [x] Xóa ENV cũ không còn dùng (ví dụ: các biến `DPDNS_CLOUDFLARED_MANAGER_*` nếu app mới không dùng)

### Phase 4 — SQLite / Litestream (nếu có)

- [x] Cập nhật `services/litestream/litestream.yml` thêm DB mới (theo Spec 5) — bỏ qua vì Spec 5: Không dùng
- [x] Cập nhật `services/litestream/entrypoint.sh` thêm restore gate cho app DB — bỏ qua vì Spec 5: Không dùng
- [x] Cập nhật `docker-compose/compose.auth.yml` — mount volume app data cho litestream containers — bỏ qua vì Spec 5: Không dùng
- [x] Cập nhật `LITESTREAM_REPLICATE_DBS` trong `.env.example` — giữ `tinyauth`, không thêm app

### Phase 5 — Cập nhật docs & validate

- [x] Cập nhật `docs/services/app.md` mô tả app mới
- [x] Cập nhật `docs/services/litestream.md` nếu có thay đổi Litestream — không cần vì không dùng Litestream cho app
- [x] Chạy `npm run dockerapp-validate:env`
- [x] Chạy `npm run dockerapp-validate:compose`
- [x] Cập nhật `docker-compose/scripts/validate-env.js` nếu có ENV mới cần validate

### Phase 6 — Hoàn tất

- [x] Kiểm tra lại toàn bộ thay đổi phù hợp yêu cầu
- [ ] Cập nhật `.opushforce.message` đúng format trong `AGENTS.md`
- [ ] Trả lời user ngắn gọn kèm danh sách file đã chỉnh

---

## File liên quan — Danh sách file mà Agent có thể đọc/chỉnh

Tham chiếu từ `AGENT_APP_SWAP.md` mục 3 (Default Editable Files):

| File                                     | Hành động                 | Ghi chú                      |
| ---------------------------------------- | ------------------------- | ---------------------------- |
| `services/app/**`                        | Xóa cũ + thay source mới  | Thư mục chính của app        |
| `services/app/Dockerfile`                | Tạo mới / sửa             | Dockerfile phù hợp runtime   |
| `compose.apps.yml`                       | Sửa                       | Service `app` definition     |
| `.env.example`                           | Sửa                       | Thêm/sửa ENV mới             |
| `docker-compose/compose.auth.yml`        | Sửa (nếu cần)             | Litestream volumes, Tinyauth |
| `services/litestream/litestream.yml`     | Sửa (nếu app dùng SQLite) | Thêm DB replica config       |
| `services/litestream/entrypoint.sh`      | Sửa (nếu app dùng SQLite) | Restore gate                 |
| `docker-compose/scripts/validate-env.js` | Sửa (nếu ENV mới)         | Validation rules             |
| `docs/services/app.md`                   | Sửa                       | Tài liệu app mới             |
| `docs/services/litestream.md`            | Sửa (nếu cần)             | Tài liệu Litestream          |
| `docs/services/tinyauth.md`              | Sửa (nếu auth thay đổi)   | Tài liệu Tinyauth            |

Agent cập nhật thêm file đã đọc/chỉnh vào đây:

- `services/app/**`
- `.env`
- `.env.example`
- `compose.apps.yml`
- `docker-compose/compose.rclone.yml`
- `services/rclone/entrypoint.sh`
- `docker-compose/scripts/validate-env.js`
- `docker-compose/scripts/validate-compose.js`
- `docs/services/app.md`
- `docs/services/rclone.md`

## Kết quả kiểm tra

Agent ghi command đã chạy hoặc lý do không chạy.

- `npm run dockerapp-validate:env` → Đã chạy, fail do `.env` active còn thiếu cấu hình deploy thật: `PROJECT_NAME`, `TINYAUTH_APP_URL` phải là HTTPS, `TINYAUTH_USERS` phải là bcrypt, thiếu `TINYAUTH_TRUSTED_PROXIES`, thiếu `cloudflared/config.yml`, `cloudflared/credentials.json`, và thiếu Tailscale auth/tailnet khi `ENABLE_TAILSCALE=true`. Các biến `9ROUTER_*` mới pass.
- `npm run dockerapp-validate:compose` → Pass, compose config hợp lệ.

---

## Ghi chú cho lần sau

Chỉ ghi thông tin hữu ích trực tiếp cho task này, không thay cho memory dài hạn.

- 9Router dùng `/api/health`, port mặc định `20128`, data local `/app/data`.
- Rclone sidecar đọc config từ `9ROUTER_RCLONE_CONFIG_BASE64` và chỉ sync khi `rclone check` báo khác biệt.
