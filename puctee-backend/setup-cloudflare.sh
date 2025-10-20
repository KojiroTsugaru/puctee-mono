#!/bin/bash

# Cloudflare Workers セットアップスクリプト
# このスクリプトは初回セットアップ時に実行してください

set -e

echo "🔧 Cloudflare Workers セットアップ"
echo "=================================="
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "📦 Wrangler CLI をインストールしています..."
    npm install -g wrangler
else
    echo "✅ Wrangler CLI は既にインストールされています"
fi

# Login to Cloudflare
echo ""
echo "🔐 Cloudflare にログインしてください..."
wrangler login

echo ""
echo "✅ ログイン成功！"
echo ""

# Prompt for environment
read -p "セットアップする環境を選択してください (development/production): " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-development}

echo ""
echo "🔑 Secrets を設定します..."
echo "各項目の値を入力してください（Ctrl+C でスキップ可能）"
echo ""

# Function to set secret
set_secret() {
    local secret_name=$1
    local description=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 $secret_name"
    echo "   $description"
    read -p "   値を入力してください: " secret_value
    
    if [ -n "$secret_value" ]; then
        echo "$secret_value" | wrangler secret put "$secret_name" --env "$ENVIRONMENT"
        echo "   ✅ 設定完了"
    else
        echo "   ⏭️  スキップしました"
    fi
    echo ""
}

# Set all required secrets
set_secret "DATABASE_URL" "Neon/Supabase の接続文字列 (例: postgresql://user:pass@host/db?sslmode=require)"
set_secret "SECRET_KEY" "JWT Secret Key (openssl rand -hex 32 で生成)"
set_secret "AWS_ACCESS_KEY_ID" "AWS Access Key ID (S3用)"
set_secret "AWS_SECRET_ACCESS_KEY" "AWS Secret Access Key (S3用)"
set_secret "AWS_S3_BUCKET" "S3 バケット名"
set_secret "REDIS_URL" "Redis URL (Upstash推奨: rediss://default:pass@host:port)"
set_secret "APNS_SECRET_ARN" "APNs Secret ARN"
set_secret "APNS_AUTH_KEY_ID" "APNs Auth Key ID"
set_secret "APNS_TEAM_ID" "Apple Team ID"
set_secret "APNS_BUNDLE_ID" "iOS Bundle ID (例: com.yourcompany.puctee)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ セットアップ完了！"
echo ""
echo "📋 設定された Secrets の一覧:"
wrangler secret list --env "$ENVIRONMENT"
echo ""
echo "🚀 次のステップ:"
echo "   1. データベースを移行: CLOUDFLARE_MIGRATION.md を参照"
echo "   2. デプロイ: ./deploy.sh $ENVIRONMENT"
echo ""
