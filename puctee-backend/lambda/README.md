# Lambda Function for EventBridge Scheduler

This Lambda function is triggered by EventBridge Scheduler to call the Railway backend endpoint for sending silent notifications.

## Architecture

```
EventBridge Scheduler → Lambda Function → Railway Backend Endpoint
```

## Setup

### 1. Create IAM Role

```bash
cd lambda
chmod +x setup-iam-role.sh
./setup-iam-role.sh
```

This creates:
- `puctee-scheduler-lambda-role` - Role for Lambda function with CloudWatch Logs permissions
- Lambda invoke permissions for EventBridge Scheduler

### 2. Deploy Lambda Function

Make sure `.env` file has:
```
RAILWAY_PUBLIC_DOMAIN=your-app.up.railway.app
SCHEDULER_API_KEY=your-api-key
```

Then deploy:
```bash
chmod +x deploy.sh
./deploy.sh
```

### 3. Update EventBridge Scheduler

The `eventbridge_scheduler.py` is already configured to use Lambda function.
When you create a plan, it will automatically create an EventBridge Schedule that invokes the Lambda function.

## Testing

Test the Lambda function directly:

```bash
aws lambda invoke \
  --function-name puctee-scheduler-trigger \
  --payload '{"plan_id": 99999}' \
  --region ap-northeast-1 \
  response.json

cat response.json
```

## Monitoring

View Lambda logs:

```bash
aws logs tail /aws/lambda/puctee-scheduler-trigger --follow --region ap-northeast-1
```

## Cost

Lambda pricing:
- First 1 million requests per month: FREE
- $0.20 per 1 million requests thereafter
- $0.0000166667 per GB-second of compute time

For typical usage (few schedules per day), this will be within the free tier.
