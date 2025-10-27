"""
Lambda function to trigger Railway backend scheduler endpoint

This function is invoked by EventBridge Scheduler and calls the Railway
backend endpoint to send silent notifications.
"""
import json
import os
import urllib3
import logging

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize HTTP client
http = urllib3.PoolManager()

# Configuration from environment variables
RAILWAY_ENDPOINT = os.environ['RAILWAY_ENDPOINT']
API_KEY = os.environ['API_KEY']


def lambda_handler(event, context):
    """
    Lambda handler for EventBridge Scheduler trigger
    
    Expected event format:
    {
        "plan_id": 123
    }
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Extract plan_id from event
        plan_id = event.get('plan_id')
        if not plan_id:
            logger.error("Missing plan_id in event")
            return {
                'statusCode': 400,
                'body': json.dumps({'error': 'Missing plan_id'})
            }
        
        # Prepare request
        url = RAILWAY_ENDPOINT
        headers = {
            'Content-Type': 'application/json',
            'X-API-Key': API_KEY
        }
        body = json.dumps({'plan_id': plan_id})
        
        logger.info(f"Calling Railway endpoint: {url}")
        logger.info(f"Request body: {body}")
        
        # Make HTTP request to Railway endpoint
        response = http.request(
            'POST',
            url,
            body=body,
            headers=headers,
            timeout=30.0
        )
        
        logger.info(f"Response status: {response.status}")
        logger.info(f"Response body: {response.data.decode('utf-8')}")
        
        # Check response status
        if response.status == 200:
            return {
                'statusCode': 200,
                'body': response.data.decode('utf-8')
            }
        else:
            logger.error(f"Railway endpoint returned error: {response.status}")
            return {
                'statusCode': response.status,
                'body': response.data.decode('utf-8')
            }
            
    except Exception as e:
        logger.exception(f"Error calling Railway endpoint: {e}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }
