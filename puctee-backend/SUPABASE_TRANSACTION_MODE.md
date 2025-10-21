# Supabase Transaction Mode Setup

This document explains how to configure the application to use Supabase's Transaction Mode for connection pooling.

## What is Transaction Mode?

Supabase uses PgBouncer for connection pooling with two modes:

### Session Mode (Port 5432)
- ❌ Limited connections (strict limits)
- ❌ Not suitable for serverless/Railway
- ✅ Supports all PostgreSQL features

### Transaction Mode (Port 6543) - **RECOMMENDED**
- ✅ More concurrent connections
- ✅ Better for serverless/Railway deployments
- ✅ Better performance under load
- ⚠️ Some limitations (no session-level settings)

## Migration Steps

### Step 1: Update Railway Environment Variable

Change the DATABASE_URL port from `5432` to `6543`:

**Before (Session Mode):**
```
postgresql://postgres.tfpaghmrfsmdllfajdfu:StephCurry%4030@aws-1-us-west-1.pooler.supabase.com:5432/postgres
```

**After (Transaction Mode):**
```
postgresql://postgres.tfpaghmrfsmdllfajdfu:StephCurry%4030@aws-1-us-west-1.pooler.supabase.com:6543/postgres
```

**Using Railway CLI:**
```bash
railway variables --set DATABASE_URL="postgresql://postgres.tfpaghmrfsmdllfajdfu:StephCurry%4030@aws-1-us-west-1.pooler.supabase.com:6543/postgres"
```

**Using Railway Dashboard:**
1. Go to your project → Variables tab
2. Edit `DATABASE_URL`
3. Change port from `5432` to `6543`
4. Save (will trigger automatic redeploy)

### Step 2: Verify Code Changes

The following code changes have been made to support Transaction Mode:

1. **Removed server_settings** - Not supported in Transaction Mode
2. **Optimized pool settings** - Increased pool size for better performance
3. **Adjusted pool_recycle** - 30 minutes (best practice for Transaction Mode)

### Step 3: Test the Migration

After Railway redeploys, test the endpoints:

```bash
# Health check
curl https://puctee-backend-production.up.railway.app/health

# Auth endpoint
curl -X POST https://puctee-backend-production.up.railway.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"test"}'

# Scheduler endpoint
curl -X POST https://puctee-backend-production.up.railway.app/api/scheduler/silent-notification \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"plan_id": 1}'
```

### Step 4: Monitor Logs

Check Railway logs for any connection issues:

```bash
railway logs
```

Look for:
- ✅ `Converted DATABASE_URL to use asyncpg driver`
- ✅ Successful database queries
- ❌ Connection errors or timeouts

## Transaction Mode Limitations

### What's NOT Supported:
1. **Session-level settings** (e.g., `SET search_path`)
2. **Prepared statements** (disabled in our config)
3. **LISTEN/NOTIFY** (use Supabase Realtime instead)
4. **Advisory locks**

### What IS Supported:
- ✅ All standard SQL queries
- ✅ Transactions
- ✅ Connection pooling
- ✅ Async operations
- ✅ SQLAlchemy ORM

## Performance Benefits

### Before (Session Mode):
- Max ~10-15 connections
- Frequent "max clients reached" errors
- Slower under load

### After (Transaction Mode):
- Max ~100+ connections
- No connection limit errors
- Better performance
- More suitable for Railway/serverless

## Rollback Plan

If you encounter issues, you can rollback by changing the port back to `5432`:

```bash
railway variables --set DATABASE_URL="postgresql://postgres.tfpaghmrfsmdllfajdfu:StephCurry%4030@aws-1-us-west-1.pooler.supabase.com:5432/postgres"
```

Then revert the code changes:
```bash
git revert HEAD
git push origin main
```

## References

- [Supabase Connection Pooling](https://supabase.com/docs/guides/database/connecting-to-postgres#connection-pooler)
- [PgBouncer Transaction Mode](https://www.pgbouncer.org/features.html)
