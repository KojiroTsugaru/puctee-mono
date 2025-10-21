# EventBridge Scheduler Setup for Railway

This document explains how to configure AWS EventBridge Scheduler to trigger scheduled notifications on your Railway-deployed FastAPI application.

## Architecture

```
EventBridge Scheduler → Railway FastAPI Endpoint → Silent Notifications
```

Instead of invoking a Lambda function, EventBridge Scheduler now makes HTTP POST requests directly to your Railway application endpoint.

## Prerequisites

1. **Railway App Deployed**: Your FastAPI app must be deployed and accessible
2. **AWS Account**: With EventBridge Scheduler permissions
3. **IAM Role**: For EventBridge Scheduler to invoke HTTP endpoints

## Step 1: Configure Environment Variables

Railway automatically provides `RAILWAY_PUBLIC_DOMAIN` environment variable (e.g., `your-app.up.railway.app`).

You only need to add the API key to your Railway environment variables:

```bash
# Optional but recommended: API key for authenticating scheduler requests
SCHEDULER_API_KEY=your-secure-random-key-here
```

Generate a secure API key:
```bash
openssl rand -hex 32
```

**Note**: `RAILWAY_PUBLIC_DOMAIN` is automatically set by Railway. You don't need to configure it manually!

## Step 2: Update IAM Role

The EventBridge Scheduler IAM role (`puctee-scheduler-invoke-role`) needs permissions to invoke HTTP endpoints:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "scheduler:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:SendMessage"
      ],
      "Resource": "arn:aws:sqs:ap-northeast-1:002066576827:puctee-scheduler-dlq"
    }
  ]
}
```

## Step 3: Test the Endpoint

Test that your Railway endpoint is accessible:

```bash
curl -X POST https://your-app.up.railway.app/api/scheduler/silent-notification \
  -H "Content-Type: application/json" \
  -H "X-API-Key: your-api-key" \
  -d '{"plan_id": 1}'
```

Expected response:
```json
{
  "success": true,
  "plan_id": 1,
  "notifications_sent": 2,
  "total_participants": 2
}
```

## Step 4: How It Works

1. **Plan Creation**: When a plan is created with a scheduled time, the backend calls `schedule_silent_for_plan()`
2. **EventBridge Scheduler**: Creates a one-time schedule that will trigger at the specified time
3. **HTTP Request**: At the scheduled time, EventBridge makes a POST request to:
   ```
   POST https://your-app.up.railway.app/api/scheduler/silent-notification
   ```
4. **Authentication**: The request includes the `X-API-Key` header if configured
5. **Notification Sending**: The endpoint triggers `run_send_silent()` which sends silent push notifications to all plan participants
6. **iOS Wake-up**: Silent notifications wake up the iOS app in the background to check arrival status

## Endpoint Details

### POST `/api/scheduler/silent-notification`

**Headers:**
- `Content-Type: application/json`
- `X-API-Key: <your-api-key>` (if `SCHEDULER_API_KEY` is configured)

**Request Body:**
```json
{
  "plan_id": 123
}
```

**Response (Success):**
```json
{
  "success": true,
  "plan_id": 123,
  "notifications_sent": 5,
  "total_participants": 5
}
```

**Response (Error):**
```json
{
  "detail": "Invalid or missing API key"
}
```

## Security Considerations

1. **API Key Authentication**: Always set `SCHEDULER_API_KEY` in production
2. **HTTPS Only**: Railway provides HTTPS by default
3. **Rate Limiting**: Consider adding rate limiting to the scheduler endpoint
4. **Logging**: All scheduler requests are logged for monitoring

## Monitoring

Check logs for scheduler activity:

```bash
# Railway CLI
railway logs

# Look for these log patterns:
[SCHEDULER] Received scheduled silent notification request for plan 123
[SCHEDULER] Successfully processed silent notification for plan 123
```

## Troubleshooting

### Scheduler not triggering

1. Check EventBridge Scheduler console for schedule status
2. Verify Railway app is running: `https://your-app.up.railway.app/health`
3. Check DLQ (Dead Letter Queue) for failed invocations

### Authentication errors

1. Verify `SCHEDULER_API_KEY` matches in both Railway and EventBridge Scheduler
2. Check request headers include `X-API-Key`

### Notifications not sending

1. Check logs for APNs errors
2. Verify users have valid push tokens
3. Ensure `APNS_USE_SANDBOX` is set correctly

## Migration from Lambda

The previous implementation used Lambda functions. The new implementation:

✅ **Simpler**: No Lambda deployment needed
✅ **Cheaper**: No Lambda invocation costs
✅ **Unified**: All code in one Railway deployment
✅ **Easier to debug**: Logs in one place

No changes needed to the scheduling logic - it's transparent to the rest of the application.
