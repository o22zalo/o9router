#!/bin/sh
# ================================================================
#  reset-s3.sh — Xóa dữ liệu Litestream trên S3
#
#  Dùng khi cần reset backup hoàn toàn để fresh start.
#  Sau khi chạy: litestream-restore sẽ detect S3 trống và cho
#  app tự tạo DB mới, rồi sync lên S3 lại từ đầu.
#
#  Cách dùng:
#    ./reset-s3.sh                 → xóa tất cả DB đang replicate
#    ./reset-s3.sh tinyauth        → chỉ xóa tinyauth
#    ./reset-s3.sh app             → chỉ xóa app db
#    ./reset-s3.sh tinyauth app    → xóa nhiều DB
#
#  Yêu cầu: file .env phải có đủ LITESTREAM_S3_* vars
#           và aws CLI đã được cài (hoặc chạy qua Docker)
# ================================================================
set -e

# ── Load .env từ project root ─────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/../../../../.env"
if [ -f "$ENV_FILE" ]; then
  # shellcheck disable=SC2046
  export $(grep -v '^#' "$ENV_FILE" | grep -v '^$' | xargs)
  echo "[INFO] Loaded .env from: $ENV_FILE"
else
  echo "[WARN] .env not found at $ENV_FILE, using existing environment variables."
fi

# ── Validate required vars ────────────────────────────────────────────────
: "${LITESTREAM_S3_ENDPOINT:?Need LITESTREAM_S3_ENDPOINT}"
: "${LITESTREAM_S3_BUCKET:?Need LITESTREAM_S3_BUCKET}"
: "${LITESTREAM_S3_ACCESS_KEY_ID:?Need LITESTREAM_S3_ACCESS_KEY_ID}"
: "${LITESTREAM_S3_SECRET_ACCESS_KEY:?Need LITESTREAM_S3_SECRET_ACCESS_KEY}"

export AWS_ACCESS_KEY_ID="$LITESTREAM_S3_ACCESS_KEY_ID"
export AWS_SECRET_ACCESS_KEY="$LITESTREAM_S3_SECRET_ACCESS_KEY"
export AWS_DEFAULT_REGION="${LITESTREAM_S3_REGION:-us-east-1}"

ENDPOINT="$LITESTREAM_S3_ENDPOINT"
BUCKET="$LITESTREAM_S3_BUCKET"

# ── Xác định danh sách DB cần reset ──────────────────────────────────────
if [ $# -eq 0 ]; then
  # Không truyền arg → reset tất cả DB đang config
  TARGETS="${LITESTREAM_REPLICATE_DBS:-tinyauth}"
  # Chuyển comma-separated → space-separated
  TARGETS="$(echo "$TARGETS" | tr ',' ' ')"
else
  TARGETS="$*"
fi

echo ""
echo "╔══════════════════════════════════════════════════════╗"
echo "║           LITESTREAM S3 RESET TOOL                  ║"
echo "╠══════════════════════════════════════════════════════╣"
echo "║  Endpoint : $ENDPOINT"
echo "║  Bucket   : $BUCKET"
echo "║  Targets  : $TARGETS"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# ── Map DB name → S3 path ─────────────────────────────────────────────────
get_s3_path() {
  case "$1" in
    tinyauth) echo "${LITESTREAM_TINYAUTH_S3_PATH:-tinyauth/tinyauth.db}" ;;
    app)      echo "${LITESTREAM_APP_S3_PATH:-app/app.db}" ;;
    *)        echo "$1" ;;
  esac
}

# ── Hàm xóa 1 DB path trên S3 ────────────────────────────────────────────
reset_one() {
  db_name="$1"
  s3_path="$(get_s3_path "$db_name")"
  s3_uri="s3://${BUCKET}/${s3_path}"

  echo "──────────────────────────────────────────────────────"
  echo "  DB      : $db_name"
  echo "  S3 path : $s3_uri"
  echo ""

  # Kiểm tra có gì không
  echo "  Đang kiểm tra objects trên S3..."
  OBJ_COUNT=$(aws s3 ls "${s3_uri}" \
    --endpoint-url "$ENDPOINT" \
    --recursive \
    --no-paginate 2>/dev/null | wc -l | tr -d ' ')

  if [ "${OBJ_COUNT:-0}" -eq 0 ]; then
    echo "  ✓ S3 path đã trống, không cần xóa."
    return 0
  fi

  echo "  Tìm thấy ${OBJ_COUNT} object(s) tại: $s3_uri"
  echo ""
  printf "  ⚠ Xác nhận XÓA TOÀN BỘ data của '%s' trên S3? [y/N] " "$db_name"
  read -r confirm
  case "$confirm" in
    [yY]|[yY][eE][sS])
      echo "  Đang xóa..."
      aws s3 rm "${s3_uri}" \
        --endpoint-url "$ENDPOINT" \
        --recursive
      echo "  ✓ Đã xóa toàn bộ data của '${db_name}' trên S3."
      ;;
    *)
      echo "  ✗ Bỏ qua '${db_name}'."
      ;;
  esac
  echo ""
}

# ── Chạy reset cho từng target ───────────────────────────────────────────
for db in $TARGETS; do
  reset_one "$db"
done

echo "══════════════════════════════════════════════════════"
echo "  Hoàn tất. Khởi động lại stack để fresh start:"
echo "    docker compose down && docker compose up -d"
echo "══════════════════════════════════════════════════════"
