#!/bin/bash

# Cloudflare Workers Setup Script
# Run this script for initial setup

set -e

echo "🔧 Cloudflare Workers Setup"
echo "=================================="
echo ""

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "📦 Installing Wrangler CLI..."
    npm install -g wrangler
else
    echo "✅ Wrangler CLI is already installed"
fi

# Login to Cloudflare
echo ""
echo "🔐 Please login to Cloudflare..."
wrangler login

echo ""
echo "✅ Login successful!"
echo ""

# Prompt for environment
read -p "Select environment to setup (development/production): " ENVIRONMENT
ENVIRONMENT=${ENVIRONMENT:-development}

echo ""
echo "🔑 Setting up Secrets..."
echo "Enter values for each item (Ctrl+C to skip)"
echo ""

# Function to set secret
set_secret() {
    local secret_name=$1
    local description=$2
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 $secret_name"
    echo "   $description"
    read -p "   Enter value: " secret_value
    
    if [ -n "$secret_value" ]; then
        echo "$secret_value" | wrangler secret put "$secret_name" --env "$ENVIRONMENT"
        echo "   ✅ Configuration complete"
    else
        echo "   ⏭️  Skipped"
    fi
    echo ""
}

# Set all required secrets
set_secret "DATABASE_URL" "Supabase/Neon connection string (e.g., postgresql://postgres:pass@db.xxx.supabase.co:5432/postgres)"
set_secret "SECRET_KEY" "JWT Secret Key (generate with: openssl rand -hex 32)"
set_secret "AWS_ACCESS_KEY_ID" "AWS Access Key ID (for S3)"
set_secret "AWS_SECRET_ACCESS_KEY" "AWS Secret Access Key (for S3)"
set_secret "AWS_S3_BUCKET" "S3 Bucket Name"

echo ""
echo "📝 Optional: Supabase Realtime (skip if using Neon + Redis)"
read -p "Are you using Supabase? (y/n): " use_supabase

if [[ "$use_supabase" == "y" || "$use_supabase" == "Y" ]]; then
    set_secret "SUPABASE_URL" "Supabase Project URL (e.g., https://xxx.supabase.co)"
    set_secret "SUPABASE_ANON_KEY" "Supabase Anon Key (from Settings > API)"
    echo "   ℹ️  Redis is optional when using Supabase Realtime"
    read -p "   Do you still want to configure Redis? (y/n): " use_redis
    if [[ "$use_redis" == "y" || "$use_redis" == "Y" ]]; then
        set_secret "REDIS_URL" "Redis URL (Upstash: rediss://default:pass@host:port)"
    fi
else
    echo "   Using Neon - Redis is required for WebSocket"
    set_secret "REDIS_URL" "Redis URL (Upstash recommended: rediss://default:pass@host:port)"
fi

echo ""
set_secret "APNS_SECRET_ARN" "APNs Secret ARN"
set_secret "APNS_AUTH_KEY_ID" "APNs Auth Key ID"
set_secret "APNS_TEAM_ID" "Apple Team ID"
set_secret "APNS_BUNDLE_ID" "iOS Bundle ID (e.g., com.yourcompany.puctee)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup complete!"
echo ""
echo "📋 List of configured Secrets:"
wrangler secret list --env "$ENVIRONMENT"
echo ""
echo "🚀 Next steps:"
echo "   1. Migrate database: See CLOUDFLARE_MIGRATION.md"
echo "   2. Deploy: ./deploy.sh $ENVIRONMENT"
echo ""
