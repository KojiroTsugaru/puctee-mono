#!/bin/bash

# Cloudflare Workers デプロイスクリプト
# Usage: ./deploy.sh [development|production]

set -e

ENVIRONMENT=${1:-development}

echo "🚀 Deploying to Cloudflare Workers ($ENVIRONMENT)..."

# Check if wrangler is installed
if ! command -v wrangler &> /dev/null; then
    echo "❌ Error: wrangler CLI is not installed"
    echo "Install it with: npm install -g wrangler"
    exit 1
fi

# Check if logged in
if ! wrangler whoami &> /dev/null; then
    echo "❌ Error: Not logged in to Cloudflare"
    echo "Login with: wrangler login"
    exit 1
fi

# Validate environment
if [[ "$ENVIRONMENT" != "development" && "$ENVIRONMENT" != "production" ]]; then
    echo "❌ Error: Invalid environment. Use 'development' or 'production'"
    exit 1
fi

echo "📦 Installing dependencies..."
pip install -r requirements.txt

echo "🔍 Running pre-deployment checks..."

# Check if required secrets are set
REQUIRED_SECRETS=(
    "DATABASE_URL"
    "SECRET_KEY"
    "AWS_ACCESS_KEY_ID"
    "AWS_SECRET_ACCESS_KEY"
    "AWS_S3_BUCKET"
    "REDIS_URL"
    "APNS_SECRET_ARN"
    "APNS_AUTH_KEY_ID"
    "APNS_TEAM_ID"
    "APNS_BUNDLE_ID"
)

echo "Checking required secrets..."
for secret in "${REQUIRED_SECRETS[@]}"; do
    if ! wrangler secret list --env "$ENVIRONMENT" 2>/dev/null | grep -q "$secret"; then
        echo "⚠️  Warning: Secret '$secret' is not set"
        echo "   Set it with: wrangler secret put $secret --env $ENVIRONMENT"
    fi
done

echo "🚀 Deploying to $ENVIRONMENT environment..."
wrangler deploy --env "$ENVIRONMENT"

echo "✅ Deployment complete!"
echo ""
echo "🔗 Your API is now available at:"
wrangler deployments list --env "$ENVIRONMENT" | head -n 2

echo ""
echo "📊 View logs with:"
echo "   wrangler tail --env $ENVIRONMENT"
echo ""
echo "🧪 Test your deployment:"
echo "   curl https://puctee-api.your-subdomain.workers.dev/health"
