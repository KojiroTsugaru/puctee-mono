# Cloudflare Workers + Neon/Supabase Migration Guide

This guide explains the migration process from AWS Lambda + RDS to Cloudflare Workers + Neon/Supabase.

## Prerequisites

- Node.js 18 or higher installed
- Cloudflare account (free tier available)
- Neon or Supabase account

## Step 1: Database Setup

### Option A: Using Neon (Recommended)

1. Access [Neon Console](https://console.neon.tech/)
2. Create a new project
   - **Region**: Select Tokyo (ap-northeast-1)
   - **PostgreSQL version**: 15 or higher
3. Copy the connection string
   ```
   postgresql://user:password@ep-xxx.ap-northeast-1.aws.neon.tech/dbname?sslmode=require
   ```

### Option B: Using Supabase

1. Access [Supabase Console](https://app.supabase.com/)
2. Create a new project
   - **Region**: Select Tokyo
3. Copy the connection string from Settings > Database
   ```
   postgresql://postgres:password@db.xxx.supabase.co:5432/postgres
   ```

## Step 2: Data Migration

### Export data from current RDS

```bash
# Get dump from RDS
pg_dump $CURRENT_RDS_URL > backup.sql

# Or specific tables only
pg_dump $CURRENT_RDS_URL --table=users --table=plans > backup.sql
```

### Import to Neon/Supabase

```bash
# Import to new database
psql $NEW_DATABASE_URL < backup.sql

# Or create schema with Alembic first, then import data
cd puctee-backend
alembic upgrade head
```

## Step 3: Install Wrangler CLI

```bash
# Install Wrangler CLI globally
npm install -g wrangler

# Login to Cloudflare
wrangler login
```

## Step 4: Configure Secrets

Set environment variables (Secrets) for Cloudflare Workers:

```bash
cd puctee-backend

# Database connection string
wrangler secret put DATABASE_URL
# Input: postgresql://user:password@ep-xxx.ap-northeast-1.aws.neon.tech/dbname?sslmode=require

# JWT Secret Key
wrangler secret put SECRET_KEY
# Input: Key generated with openssl rand -hex 32

# AWS credentials (for S3)
wrangler secret put AWS_ACCESS_KEY_ID
wrangler secret put AWS_SECRET_ACCESS_KEY
wrangler secret put AWS_S3_BUCKET

# Redis URL (Upstash Redis recommended)
wrangler secret put REDIS_URL
# Upstash: https://console.upstash.com/

# APNs configuration
wrangler secret put APNS_SECRET_ARN
wrangler secret put APNS_AUTH_KEY_ID
wrangler secret put APNS_TEAM_ID
wrangler secret put APNS_BUNDLE_ID
```

## Step 5: Deploy

```bash
# Deploy to development environment
wrangler deploy --env development

# Deploy to production environment
wrangler deploy --env production
```

After successful deployment, the URL will be displayed:
```
https://puctee-api.your-subdomain.workers.dev
```

## Step 6: Update iOS App Connection

In `puctee-ios/puctee/Utils/Networking/APIConfig.swift` or similar,
update the API base URL to the new Cloudflare Workers URL.

```swift
// Before
let baseURL = "https://your-api.execute-api.ap-northeast-1.amazonaws.com"

// After
let baseURL = "https://puctee-api.your-subdomain.workers.dev"
```

## Step 7: Verify Operation

```bash
# Health check
curl https://puctee-api.your-subdomain.workers.dev/health

# Response example
{"ok": true}
```

## Troubleshooting

### Database Connection Error

```
Error: connection timeout
```

**Solution**:
- Verify Neon/Supabase connection string is correct
- Ensure `?sslmode=require` is included
- Check if database is running in Neon/Supabase dashboard

### Deployment Error

```
Error: Python workers are not supported
```

**Solution**:
- Check `compatibility_flags` in `wrangler.toml`
- Cloudflare Workers currently supports Python experimentally
- Convert FastAPI to Workers-compatible format if needed

### Connection Pool Error

```
Error: too many connections
```

**Solution**:
- Verify `pool_size=1` is set in `app/db/session.py`
- Check Neon/Supabase connection limits (free tier has restrictions)

## Performance Optimization

### 1. Enable Neon Autoscaling

Enable Autoscaling in Neon Console > Settings > Compute to
automatically scale based on traffic.

### 2. Cloudflare Workers Region Settings

Reduce latency by restricting to specific regions in `wrangler.toml`:

```toml
[placement]
mode = "smart"
```

### 3. Utilize Redis Cache

Cache frequently accessed data in Upstash Redis.

## Cost Comparison

### AWS Lambda + RDS
- Lambda: Charged based on request count
- RDS: Always running, minimum $15-30/month

### Cloudflare Workers + Neon
- Workers: Free tier includes 100,000 requests/day
- Neon: Free tier includes 0.5GB storage, auto-scaling

**Estimated cost savings**: $20-50/month

## Next Steps

1. **Migrate S3 → Cloudflare R2**
   - R2 provides S3-compatible API
   - Free egress charges

2. **Introduce Upstash Redis**
   - Easy integration with Cloudflare Workers
   - Global replication

3. **Setup Monitoring**
   - Monitor requests with Cloudflare Analytics
   - Monitor database performance in Neon Console

## Support

If you encounter issues:
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Neon Docs](https://neon.tech/docs)
- [Supabase Docs](https://supabase.com/docs)
