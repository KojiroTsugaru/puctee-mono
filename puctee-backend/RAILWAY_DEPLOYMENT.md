# Railway Deployment Guide

This guide explains how to deploy the Puctee FastAPI backend to Railway with Supabase database.

## Why Railway?

- ✅ **Full FastAPI Support**: No experimental limitations
- ✅ **Easy Deployment**: GitHub integration with auto-deploy
- ✅ **Free Tier**: $5 credit/month (enough for small projects)
- ✅ **Supabase Integration**: Works perfectly with Supabase PostgreSQL
- ✅ **Environment Variables**: Easy secret management
- ✅ **Automatic HTTPS**: SSL certificates included
- ✅ **Logs & Monitoring**: Built-in observability

## Prerequisites

- GitHub account
- Railway account (sign up at https://railway.app)
- Supabase project (from previous setup)

## Step 1: Push Code to GitHub

```bash
# Make sure you're in the puctee-mono directory
cd /Users/kj/Documents/code/puctee-mono

# Add all changes
git add -A

# Commit
git commit -m "backend: add railway deployment configuration"

# Push to GitHub
git push origin migrate-to-cloudflare
```

## Step 2: Create Railway Project

1. **Go to Railway Dashboard**
   - Visit https://railway.app/dashboard
   - Click "New Project"

2. **Deploy from GitHub**
   - Select "Deploy from GitHub repo"
   - Authorize Railway to access your GitHub
   - Select `puctee-mono` repository
   - Select `puctee-backend` as the root directory

3. **Configure Build**
   - Railway will auto-detect Python and use `requirements.txt`
   - Root directory: `puctee-backend`
   - Start command: `uvicorn app.main:app --host 0.0.0.0 --port $PORT`

## Step 3: Set Environment Variables

In Railway Dashboard > Variables, add the following:

### Database
```
DATABASE_URL=postgresql://postgres:[YOUR-PASSWORD]@db.tfpaghmrfsmdllfajdfu.supabase.co:5432/postgres
```

### Authentication
```
SECRET_KEY=[YOUR-SECRET-KEY]
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30
```

### AWS (S3)
```
AWS_ACCESS_KEY_ID=[YOUR-AWS-ACCESS-KEY-ID]
AWS_SECRET_ACCESS_KEY=[YOUR-AWS-SECRET-ACCESS-KEY]
AWS_REGION=ap-northeast-1
AWS_S3_BUCKET=[YOUR-S3-BUCKET-NAME]
```

### Redis (Optional if using Supabase Realtime)
```
REDIS_URL=redis://localhost:6379/0
```

### Supabase (for Realtime)
```
SUPABASE_URL=https://tfpaghmrfsmdllfajdfu.supabase.co
SUPABASE_ANON_KEY=[YOUR-SUPABASE-ANON-KEY]
```

### APNs (Push Notifications)
```
APNS_SECRET_ARN=[YOUR-APNS-SECRET-ARN]
APNS_AUTH_KEY_ID=[YOUR-APNS-AUTH-KEY-ID]
APNS_TEAM_ID=[YOUR-APNS-TEAM-ID]
APNS_BUNDLE_ID=[YOUR-BUNDLE-ID]
APNS_USE_SANDBOX=false
```

### Application Settings
```
ENVIRONMENT=production
```

## Step 4: Deploy

Railway will automatically deploy when you push to GitHub!

```bash
# Any push to the branch will trigger a deployment
git push origin migrate-to-cloudflare
```

## Step 5: Get Your Deployment URL

After deployment completes:

1. Go to Railway Dashboard > Your Project > Settings
2. Click "Generate Domain"
3. Your API will be available at: `https://your-project.up.railway.app`

## Step 6: Update iOS App

Update your iOS app's API base URL to the Railway URL:

```swift
// APIConfig.swift or similar
let baseURL = "https://your-project.up.railway.app"
```

## Step 7: Test Deployment

```bash
# Health check
curl https://your-project.up.railway.app/health

# Expected response
{"ok": true}
```

## Monitoring & Logs

### View Logs
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# View logs
railway logs
```

### Or use the Dashboard
- Railway Dashboard > Your Project > Deployments > View Logs

## Database Migration

If you haven't migrated your database yet:

```bash
# From your local machine, run Alembic migrations against Supabase
export DATABASE_URL="postgresql://postgres:[PASSWORD]@db.tfpaghmrfsmdllfajdfu.supabase.co:5432/postgres"
alembic upgrade head
```

## Cost Estimation

### Railway Pricing
- **Free Tier**: $5 credit/month
- **Hobby Plan**: $5/month (500 hours execution time)
- **Pro Plan**: $20/month (unlimited)

### Typical Usage
- Small app: Free tier sufficient
- Medium traffic: ~$5-10/month
- High traffic: $20/month

### Total Stack Cost
- Railway: $0-5/month
- Supabase: $0 (Free tier) or $25/month (Pro)
- **Total**: $0-30/month

## Automatic Deployments

Railway automatically deploys when you:
1. Push to your connected branch
2. Merge a pull request
3. Manually trigger from dashboard

## Environment-Specific Deployments

### Production
- Branch: `main`
- Environment: `production`
- Domain: `https://puctee-api.up.railway.app`

### Staging
- Branch: `staging`
- Environment: `development`
- Domain: `https://puctee-api-staging.up.railway.app`

To set up staging:
1. Create a new Railway project
2. Connect to `staging` branch
3. Use different environment variables

## Troubleshooting

### Deployment Failed

**Check logs:**
```bash
railway logs
```

**Common issues:**
- Missing environment variables
- Database connection timeout
- Port binding issues (ensure using `$PORT`)

### Database Connection Error

```
Error: connection timeout
```

**Solution:**
- Verify `DATABASE_URL` is correct
- Check Supabase database is running
- Ensure connection string includes `?sslmode=require`

### Module Not Found

```
ModuleNotFoundError: No module named 'xxx'
```

**Solution:**
- Ensure package is in `requirements.txt`
- Check Railway build logs
- Verify Python version in `runtime.txt`

## Rollback

If a deployment fails:

1. Go to Railway Dashboard > Deployments
2. Find the last working deployment
3. Click "Redeploy"

## Custom Domain (Optional)

To use your own domain:

1. Railway Dashboard > Settings > Domains
2. Click "Add Custom Domain"
3. Enter your domain (e.g., `api.puctee.com`)
4. Add CNAME record to your DNS:
   ```
   CNAME api.puctee.com -> your-project.up.railway.app
   ```

## Health Checks

Railway automatically monitors your `/health` endpoint:

```python
# Already implemented in app/main.py
@app.get("/health")
async def health():
    return {"ok": True}
```

## Scaling

Railway automatically scales based on:
- CPU usage
- Memory usage
- Request volume

For manual scaling:
- Railway Dashboard > Settings > Resources
- Adjust CPU and Memory limits

## Migration from AWS Lambda

### What Changes:
- ❌ No more Lambda functions
- ❌ No more EventBridge Scheduler
- ✅ Standard HTTP server
- ✅ Always-on (no cold starts)
- ✅ WebSocket support

### What Stays the Same:
- ✅ FastAPI code (no changes needed)
- ✅ Database (Supabase)
- ✅ S3 storage
- ✅ APNs push notifications

## Next Steps

1. ✅ Deploy to Railway
2. ✅ Test all endpoints
3. ✅ Update iOS app with new URL
4. ✅ Monitor logs and performance
5. ⏭️ Optional: Set up staging environment
6. ⏭️ Optional: Add custom domain

## Support

- [Railway Docs](https://docs.railway.app/)
- [Railway Discord](https://discord.gg/railway)
- [Railway Status](https://status.railway.app/)

## Comparison: Railway vs Cloudflare Workers

| Feature | Railway | Cloudflare Workers |
|---------|---------|-------------------|
| **FastAPI Support** | ✅ Full | ⚠️ Experimental |
| **Python Packages** | ✅ All | ❌ Limited |
| **WebSocket** | ✅ Native | ⚠️ Limited |
| **Database** | ✅ Any | ✅ Any |
| **Cold Starts** | ❌ None | ✅ Very fast |
| **Pricing** | $5/month | $0-5/month |
| **Deployment** | ✅ Easy | ⚠️ Complex |
| **Logs** | ✅ Built-in | ✅ Built-in |

**Verdict**: Railway is the better choice for FastAPI applications.
