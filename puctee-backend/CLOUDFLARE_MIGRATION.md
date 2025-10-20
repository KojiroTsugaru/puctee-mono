# Cloudflare Workers + Neon/Supabase 移行ガイド

このガイドでは、AWS Lambda + RDS から Cloudflare Workers + Neon/Supabase への移行手順を説明します。

## 前提条件

- Node.js 18以上がインストールされていること
- Cloudflareアカウント（無料プランでOK）
- Neon または Supabase アカウント

## ステップ1: データベースのセットアップ

### Option A: Neon を使用する場合（推奨）

1. [Neon Console](https://console.neon.tech/) にアクセス
2. 新しいプロジェクトを作成
   - **Region**: Tokyo (ap-northeast-1) を選択
   - **PostgreSQL version**: 15以上
3. 接続文字列をコピー
   ```
   postgresql://user:password@ep-xxx.ap-northeast-1.aws.neon.tech/dbname?sslmode=require
   ```

### Option B: Supabase を使用する場合

1. [Supabase Console](https://app.supabase.com/) にアクセス
2. 新しいプロジェクトを作成
   - **Region**: Tokyo を選択
3. Settings > Database から接続文字列をコピー
   ```
   postgresql://postgres:password@db.xxx.supabase.co:5432/postgres
   ```

## ステップ2: データ移行

### 現在のRDSからデータをエクスポート

```bash
# RDSからダンプを取得
pg_dump $CURRENT_RDS_URL > backup.sql

# または特定のテーブルのみ
pg_dump $CURRENT_RDS_URL --table=users --table=plans > backup.sql
```

### Neon/Supabaseにインポート

```bash
# 新しいデータベースにインポート
psql $NEW_DATABASE_URL < backup.sql

# または Alembic でスキーマを作成してからデータをインポート
cd puctee-backend
alembic upgrade head
```

## ステップ3: Wrangler CLIのインストール

```bash
# Wrangler CLIをグローバルにインストール
npm install -g wrangler

# Cloudflareにログイン
wrangler login
```

## ステップ4: Secretsの設定

Cloudflare Workers に環境変数（Secrets）を設定します：

```bash
cd puctee-backend

# データベース接続文字列
wrangler secret put DATABASE_URL
# 入力: postgresql://user:password@ep-xxx.ap-northeast-1.aws.neon.tech/dbname?sslmode=require

# JWT Secret Key
wrangler secret put SECRET_KEY
# 入力: openssl rand -hex 32 で生成したキー

# AWS認証情報（S3用）
wrangler secret put AWS_ACCESS_KEY_ID
wrangler secret put AWS_SECRET_ACCESS_KEY
wrangler secret put AWS_S3_BUCKET

# Redis URL（Upstash Redisを推奨）
wrangler secret put REDIS_URL
# Upstash: https://console.upstash.com/

# APNs設定
wrangler secret put APNS_SECRET_ARN
wrangler secret put APNS_AUTH_KEY_ID
wrangler secret put APNS_TEAM_ID
wrangler secret put APNS_BUNDLE_ID
```

## ステップ5: デプロイ

```bash
# 開発環境にデプロイ
wrangler deploy --env development

# 本番環境にデプロイ
wrangler deploy --env production
```

デプロイが成功すると、URLが表示されます：
```
https://puctee-api.your-subdomain.workers.dev
```

## ステップ6: iOSアプリの接続先を変更

`puctee-ios/puctee/Utils/Networking/APIConfig.swift` などで、
APIのベースURLを新しいCloudflare WorkersのURLに変更してください。

```swift
// 変更前
let baseURL = "https://your-api.execute-api.ap-northeast-1.amazonaws.com"

// 変更後
let baseURL = "https://puctee-api.your-subdomain.workers.dev"
```

## ステップ7: 動作確認

```bash
# ヘルスチェック
curl https://puctee-api.your-subdomain.workers.dev/health

# レスポンス例
{"ok": true}
```

## トラブルシューティング

### データベース接続エラー

```
Error: connection timeout
```

**解決方法**:
- Neon/Supabaseの接続文字列が正しいか確認
- `?sslmode=require` が含まれているか確認
- Neon/Supabaseのダッシュボードでデータベースが起動しているか確認

### デプロイエラー

```
Error: Python workers are not supported
```

**解決方法**:
- `wrangler.toml` の `compatibility_flags` を確認
- Cloudflare Workers は現在 Python を実験的にサポート
- 必要に応じて、FastAPI を Workers 互換の形式に変換

### 接続プールエラー

```
Error: too many connections
```

**解決方法**:
- `app/db/session.py` で `pool_size=1` に設定されているか確認
- Neon/Supabase の接続制限を確認（無料プランは制限あり）

## パフォーマンス最適化

### 1. Neon の Autoscaling を有効化

Neon Console > Settings > Compute で Autoscaling を有効にすると、
トラフィックに応じて自動的にスケールします。

### 2. Cloudflare Workers の地域設定

`wrangler.toml` で特定の地域に制限することで、レイテンシを削減できます：

```toml
[placement]
mode = "smart"
```

### 3. Redis キャッシュの活用

頻繁にアクセスされるデータは Upstash Redis にキャッシュしましょう。

## コスト比較

### AWS Lambda + RDS
- Lambda: リクエスト数に応じて課金
- RDS: 常時稼働、最低 $15-30/月

### Cloudflare Workers + Neon
- Workers: 無料プランで 100,000 リクエスト/日
- Neon: 無料プランで 0.5GB ストレージ、自動スケール

**推定コスト削減**: 月額 $20-50 程度

## 次のステップ

1. **S3 → Cloudflare R2 への移行**
   - R2 は S3 互換 API を提供
   - エグレス料金が無料

2. **Upstash Redis の導入**
   - Cloudflare Workers と統合が簡単
   - グローバルレプリケーション

3. **モニタリングの設定**
   - Cloudflare Analytics でリクエストを監視
   - Neon Console でデータベースパフォーマンスを監視

## サポート

問題が発生した場合：
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Neon Docs](https://neon.tech/docs)
- [Supabase Docs](https://supabase.com/docs)
