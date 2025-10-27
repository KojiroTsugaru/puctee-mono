#!/bin/bash

# Create IAM role for Lambda function

set -e

ROLE_NAME="puctee-scheduler-lambda-role"
REGION="ap-northeast-1"

echo "Creating IAM role: $ROLE_NAME"

# Create trust policy
cat > trust-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

# Create role
if aws iam get-role --role-name $ROLE_NAME 2>/dev/null; then
    echo "Role already exists"
else
    aws iam create-role \
        --role-name $ROLE_NAME \
        --assume-role-policy-document file://trust-policy.json \
        --description "Role for Lambda function to trigger Railway scheduler endpoint"
    
    echo "✅ Role created"
fi

# Attach basic Lambda execution policy
aws iam attach-role-policy \
    --role-name $ROLE_NAME \
    --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

echo "✅ Attached AWSLambdaBasicExecutionRole policy"

# Update EventBridge Scheduler role to allow invoking Lambda
echo "Updating EventBridge Scheduler role..."

cat > scheduler-lambda-policy.json << EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "lambda:InvokeFunction"
      ],
      "Resource": "arn:aws:lambda:$REGION:002066576827:function:puctee-scheduler-trigger"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name puctee-scheduler-lambda-role \
    --policy-name LambdaInvokePolicy \
    --policy-document file://scheduler-lambda-policy.json

echo "✅ Updated scheduler role with Lambda invoke permissions"

# Clean up
rm trust-policy.json scheduler-lambda-policy.json

echo ""
echo "✅ IAM role setup complete!"
echo "Role ARN: arn:aws:iam::002066576827:role/$ROLE_NAME"
