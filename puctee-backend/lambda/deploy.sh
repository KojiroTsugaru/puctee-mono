#!/bin/bash

# Deploy Lambda function for EventBridge Scheduler trigger

set -e

FUNCTION_NAME="puctee-scheduler-trigger"
REGION="ap-northeast-1"
ROLE_ARN="arn:aws:iam::002066576827:role/puctee-scheduler-lambda-role"

# Get Railway endpoint and API key from .env
RAILWAY_ENDPOINT=$(grep RAILWAY_PUBLIC_DOMAIN ../.env | cut -d '=' -f2 | tr -d ' ')
API_KEY=$(grep SCHEDULER_API_KEY ../.env | cut -d '=' -f2 | tr -d ' ')

if [ -z "$RAILWAY_ENDPOINT" ]; then
    echo "Error: RAILWAY_PUBLIC_DOMAIN not found in .env"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    echo "Error: SCHEDULER_API_KEY not found in .env"
    exit 1
fi

RAILWAY_ENDPOINT="https://${RAILWAY_ENDPOINT}/api/scheduler/silent-notification"

echo "Deploying Lambda function: $FUNCTION_NAME"
echo "Railway endpoint: $RAILWAY_ENDPOINT"

# Create deployment package
echo "Creating deployment package..."
zip -j function.zip scheduler_trigger.py

# Check if function exists
if aws lambda get-function --function-name $FUNCTION_NAME --region $REGION 2>/dev/null; then
    echo "Updating existing function..."
    aws lambda update-function-code \
        --function-name $FUNCTION_NAME \
        --zip-file fileb://function.zip \
        --region $REGION
    
    # Update environment variables
    aws lambda update-function-configuration \
        --function-name $FUNCTION_NAME \
        --environment "Variables={RAILWAY_ENDPOINT=$RAILWAY_ENDPOINT,API_KEY=$API_KEY}" \
        --region $REGION
else
    echo "Creating new function..."
    aws lambda create-function \
        --function-name $FUNCTION_NAME \
        --runtime python3.11 \
        --role $ROLE_ARN \
        --handler scheduler_trigger.lambda_handler \
        --zip-file fileb://function.zip \
        --timeout 30 \
        --memory-size 128 \
        --environment "Variables={RAILWAY_ENDPOINT=$RAILWAY_ENDPOINT,API_KEY=$API_KEY}" \
        --region $REGION
fi

# Clean up
rm function.zip

echo "✅ Lambda function deployed successfully!"
echo ""
echo "Function ARN: arn:aws:lambda:$REGION:002066576827:function:$FUNCTION_NAME"
