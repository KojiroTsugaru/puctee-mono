# Cloudflare Workers + Neon/Supabase Migration Guide

This guide explains the migration process from AWS Lambda + RDS to Cloudflare Workers + Neon/Supabase.

## Prerequisites

- Node.js 18 or higher installed
- Cloudflare account (free tier available)
- Neon or Supabase account

## Step 1: Database Setup

### Option A: Using Supabase (Recommended)

**Why Supabase?**
- ✅ Built-in Realtime/WebSocket support (already used in this project)
- ✅ Replaces Redis for real-time location sharing
- ✅ Excellent dashboard and SQL editor
- ✅ Row Level Security built-in
- ✅ All-in-one platform (Database + Realtime + Storage + Auth)

**Setup Steps:**

1. Access [Supabase Console](https://app.supabase.com/)
2. Create a new project
   - **Region**: Select Tokyo (Northeast Asia)
   - **Database Password**: Set a strong password
3. Copy the connection string from Settings > Database
   ```
   postgresql://postgres:[YOUR-PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres
   ```
4. Get your Supabase credentials for Realtime:
   - **Project URL**: `https://[PROJECT-REF].supabase.co`
   - **Anon Key**: Found in Settings > API

### Option B: Using Neon

**Why Neon?**
- ✅ Database-only focus (simpler)
- ✅ Auto-scaling and auto-pause (cost-effective)
- ✅ Fast cold starts (0.5s)
- ✅ Git-like database branching

**Setup Steps:**

1. Access [Neon Console](https://console.neon.tech/)
2. Create a new project
   - **Region**: Select Tokyo (ap-northeast-1)
   - **PostgreSQL version**: 15 or higher
3. Copy the connection string
   ```
   postgresql://user:password@ep-xxx.ap-northeast-1.aws.neon.tech/dbname?sslmode=require
   ```

**Note**: If using Neon, you'll need to keep Redis (Upstash) for WebSocket functionality.

## Step 2: Data Migration

### Export data from current RDS

```bash
# Get dump from RDS
pg_dump $CURRENT_RDS_URL > backup.sql

# Or specific tables only
pg_dump $CURRENT_RDS_URL --table=users --table=plans > backup.sql
```

### Import to Supabase/Neon

```bash
# Import to new database
psql $NEW_DATABASE_URL < backup.sql

# Or create schema with Alembic first, then import data
cd puctee-backend
alembic upgrade head
```

### Supabase-Specific: Enable Realtime

If using Supabase, enable Realtime for the `locations` table:

1. Go to Supabase Dashboard > Database > Replication
2. Enable replication for the `locations` table
3. This allows real-time updates via WebSocket without Redis

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

# Redis URL (Optional if using Supabase Realtime)
# Only needed if using Neon or keeping current WebSocket implementation
wrangler secret put REDIS_URL
# Upstash: https://console.upstash.com/

# Supabase credentials (if using Supabase)
wrangler secret put SUPABASE_URL
wrangler secret put SUPABASE_ANON_KEY

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

### 1. Database Optimization

**For Supabase:**
- Enable connection pooling in Settings > Database
- Use Supabase's built-in caching for read-heavy queries
- Enable Row Level Security for better security

**For Neon:**
- Enable Autoscaling in Neon Console > Settings > Compute
- Automatically scales based on traffic

### 2. Cloudflare Workers Region Settings

Reduce latency by restricting to specific regions in `wrangler.toml`:

```toml
[placement]
mode = "smart"
```

### 3. Realtime Optimization (Supabase)

If using Supabase Realtime:
- Only subscribe to specific tables/rows you need
- Use filters to reduce bandwidth
- Implement client-side throttling for location updates

### 4. Caching Strategy

**With Supabase:** Use Supabase's built-in caching + Cloudflare KV for edge caching

**With Neon:** Use Upstash Redis for caching frequently accessed data

## Cost Comparison

### Current: AWS Lambda + RDS + Redis
- Lambda: Charged based on request count (~$5-10/month)
- RDS: Always running, minimum $15-30/month
- Redis: Upstash ~$5-10/month
- **Total**: ~$25-50/month

### Option A: Cloudflare Workers + Supabase (Recommended)
- Workers: Free tier includes 100,000 requests/day
- Supabase: Free tier includes 500MB database + Realtime + Storage
- **No Redis needed** (Supabase Realtime replaces it)
- **Total**: $0/month (free tier) or $25/month (Pro with more resources)

### Option B: Cloudflare Workers + Neon + Redis
- Workers: Free tier includes 100,000 requests/day
- Neon: Free tier includes 0.5GB storage, auto-scaling
- Redis: Upstash ~$5-10/month (still needed for WebSocket)
- **Total**: $5-10/month

**Estimated cost savings with Supabase**: $25-50/month → $0-25/month

## Next Steps

### If using Supabase:

1. **Migrate WebSocket to Supabase Realtime**
   - Replace Redis Pub/Sub with Supabase Realtime
   - Update iOS app to use Supabase client for location sharing
   - Remove Redis dependency

2. **Optional: Migrate S3 → Supabase Storage**
   - Supabase Storage provides S3-compatible API
   - Integrated with your database
   - Or use Cloudflare R2 for S3 compatibility

3. **Setup Monitoring**
   - Monitor requests with Cloudflare Analytics
   - Monitor database performance in Supabase Dashboard
   - Track Realtime connections and bandwidth

### If using Neon:

1. **Keep current WebSocket implementation**
   - Continue using Redis (Upstash) for Pub/Sub
   - No changes needed to WebSocket code

2. **Migrate S3 → Cloudflare R2**
   - R2 provides S3-compatible API
   - Free egress charges

3. **Setup Monitoring**
   - Monitor requests with Cloudflare Analytics
   - Monitor database performance in Neon Console

## Support

If you encounter issues:
- [Cloudflare Workers Docs](https://developers.cloudflare.com/workers/)
- [Neon Docs](https://neon.tech/docs)
- [Supabase Docs](https://supabase.com/docs)
