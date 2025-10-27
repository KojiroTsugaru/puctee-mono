import json
import logging
from datetime import datetime, timezone, timedelta
from typing import Optional
import uuid

import boto3
from app.core.config import settings

logger = logging.getLogger(__name__)

SCHEDULE_GROUP = "default"

class EventBridgeSchedulerService:
    def __init__(self):
        self.scheduler_client = boto3.client('scheduler', region_name=settings.AWS_REGION)
        self.events_client = boto3.client('events', region_name=settings.AWS_REGION)
        self.railway_endpoint = f"{settings.railway_app_url}/api/scheduler/silent-notification"
        self.api_destination_name = "puctee-railway-api-destination"
        self.connection_name = "puctee-railway-connection"

    def _get_schedule_name(self, plan_id: int) -> str:
        return f"puctee-plan-silent-{plan_id}"

    def _ensure_utc_future(self, when_utc: datetime) -> datetime:
        if when_utc.tzinfo is None:
            when_utc = when_utc.replace(tzinfo=timezone.utc)
        else:
            when_utc = when_utc.astimezone(timezone.utc)

        now = datetime.now(timezone.utc)
        if (when_utc - now) < timedelta(seconds=20):
            when_utc = (now + timedelta(seconds=30)).replace(microsecond=0)
        return when_utc

    async def _ensure_event_rule(self, api_destination_arn: str) -> str:
        """Ensure EventBridge Rule exists to route scheduler events to API Destination"""
        rule_name = "puctee-scheduler-to-api-destination"
        
        try:
            # Check if rule already exists
            try:
                response = self.events_client.describe_rule(Name=rule_name)
                logger.info(f"EventBridge Rule already exists: {response['Arn']}")
                return response['Arn']
            except self.events_client.exceptions.ResourceNotFoundException:
                logger.info(f"EventBridge Rule not found, creating new one")
            
            # Create rule to match scheduler events
            rule_response = self.events_client.put_rule(
                Name=rule_name,
                EventPattern=json.dumps({
                    "source": ["puctee.scheduler"],
                    "detail-type": ["PucteeSilentNotification"]
                }),
                State='ENABLED',
                Description='Route Puctee scheduler events to Railway API Destination'
            )
            rule_arn = rule_response['RuleArn']
            logger.info(f"Created EventBridge Rule: {rule_arn}")
            
            # Add API Destination as target with InputTransformer
            # Extract plan_id from event detail and send as JSON
            self.events_client.put_targets(
                Rule=rule_name,
                Targets=[{
                    'Id': '1',
                    'Arn': api_destination_arn,
                    'RoleArn': 'arn:aws:iam::002066576827:role/puctee-scheduler-http-role',
                    'HttpParameters': {
                        'HeaderParameters': {
                            'Content-Type': 'application/json'
                        }
                    },
                    'InputTransformer': {
                        'InputPathsMap': {
                            'planId': '$.detail.plan_id'
                        },
                        'InputTemplate': '{"plan_id": <planId>}'
                    },
                    'RetryPolicy': {
                        'MaximumRetryAttempts': 10,
                        'MaximumEventAgeInSeconds': 86400
                    }
                }]
            )
            logger.info(f"Added API Destination as target to rule")
            
            return rule_arn
            
        except Exception as e:
            logger.exception(f"Failed to ensure EventBridge Rule: {e}")
            raise

    async def _ensure_api_destination(self) -> str:
        """Ensure API Destination exists and return its ARN"""
        try:
            # Check if API destination already exists
            try:
                response = self.events_client.describe_api_destination(
                    Name=self.api_destination_name
                )
                logger.info(f"API destination already exists: {response['ApiDestinationArn']}")
                return response['ApiDestinationArn']
            except self.events_client.exceptions.ResourceNotFoundException:
                logger.info(f"API destination not found, creating new one")

            # Create connection for API authentication
            connection_arn = None
            try:
                conn_response = self.events_client.describe_connection(
                    Name=self.connection_name
                )
                connection_arn = conn_response['ConnectionArn']
                logger.info(f"Connection already exists: {connection_arn}")
            except self.events_client.exceptions.ResourceNotFoundException:
                logger.info(f"Connection not found, creating new one")
                
                # Create connection with API key auth if configured
                if settings.SCHEDULER_API_KEY:
                    conn_response = self.events_client.create_connection(
                        Name=self.connection_name,
                        AuthorizationType='API_KEY',
                        AuthParameters={
                            'ApiKeyAuthParameters': {
                                'ApiKeyName': 'X-API-Key',
                                'ApiKeyValue': settings.SCHEDULER_API_KEY
                            }
                        }
                    )
                else:
                    # No authentication - use invocation parameters to add headers
                    conn_response = self.events_client.create_connection(
                        Name=self.connection_name,
                        AuthorizationType='BASIC',
                        AuthParameters={
                            'BasicAuthParameters': {
                                'Username': 'puctee',
                                'Password': 'dummy'
                            }
                        }
                    )
                connection_arn = conn_response['ConnectionArn']
                logger.info(f"Created connection: {connection_arn}")

            # Create API destination
            dest_response = self.events_client.create_api_destination(
                Name=self.api_destination_name,
                ConnectionArn=connection_arn,
                InvocationEndpoint=self.railway_endpoint,
                HttpMethod='POST',
                InvocationRateLimitPerSecond=10
            )
            logger.info(f"Created API destination: {dest_response['ApiDestinationArn']}")
            return dest_response['ApiDestinationArn']

        except Exception as e:
            logger.exception(f"Failed to ensure API destination: {e}")
            raise

    async def schedule_silent_notification(self, plan_id: int, when_utc: datetime) -> bool:
        try:
            schedule_name = self._get_schedule_name(plan_id)
            when_utc = self._ensure_utc_future(when_utc)

            logger.info(f"Scheduling silent notification for plan {plan_id} at {when_utc.isoformat()}")

            ok = await self._delete_schedule_if_exists(schedule_name)
            if not ok:
                logger.warning(f"Delete existing schedule failed: {schedule_name}")

            # Ensure API destination and EventBridge Rule exist
            api_destination_arn = await self._ensure_api_destination()
            await self._ensure_event_rule(api_destination_arn)
            logger.info(f"Using API destination: {api_destination_arn}")
            logger.info(f"Target endpoint: {self.railway_endpoint}")

            schedule_expression = f"at({when_utc.strftime('%Y-%m-%dT%H:%M:%S')})"
            payload = {"plan_id": plan_id}

            # Configure target to send event to EventBridge default bus
            # The event will be routed to API Destination via EventBridge Rule
            event_bus_arn = f"arn:aws:events:{settings.AWS_REGION}:002066576827:event-bus/default"
            
            target = {
                "Arn": event_bus_arn,
                "RoleArn": "arn:aws:iam::002066576827:role/puctee-scheduler-http-role",
                "EventBridgeParameters": {
                    "DetailType": "PucteeSilentNotification",
                    "Source": "puctee.scheduler"
                },
                "Input": json.dumps(payload),
                "RetryPolicy": {
                    "MaximumEventAgeInSeconds": 86400,
                    "MaximumRetryAttempts": 10
                },
            }

            resp = self.scheduler_client.create_schedule(
                Name=schedule_name,
                GroupName=SCHEDULE_GROUP,
                ScheduleExpression=schedule_expression,
                ScheduleExpressionTimezone="UTC",
                FlexibleTimeWindow={"Mode": "OFF"},
                Target=target,
                State="ENABLED",
                Description=f"Silent notification for plan {plan_id}",
                ClientToken=str(uuid.uuid4()),
            )
            logger.info(f"✅ Created schedule {schedule_name}: {resp.get('ScheduleArn')} at {when_utc.isoformat()}")

            info = self.scheduler_client.get_schedule(Name=schedule_name, GroupName=SCHEDULE_GROUP)
            logger.info(f"Schedule details - next={info.get('NextInvocationTime')} last={info.get('LastRunTime')}")

            return True

        except Exception as e:
            logger.exception(f"❌ Failed to schedule silent notification for plan {plan_id}: {e}")
            return False

    async def cancel_silent_notification(self, plan_id: int) -> bool:
        try:
            schedule_name = self._get_schedule_name(plan_id)
            return await self._delete_schedule_if_exists(schedule_name)
        except Exception as e:
            logger.exception(f"Failed to cancel silent notification for plan {plan_id}: {e}")
            return False

    async def _delete_schedule_if_exists(self, schedule_name: str) -> bool:
        try:
            self.scheduler_client.delete_schedule(Name=schedule_name, GroupName=SCHEDULE_GROUP)
            logger.info(f"Deleted existing schedule: {schedule_name}")
            return True
        except self.scheduler_client.exceptions.ResourceNotFoundException:
            logger.info(f"No existing schedule to delete: {schedule_name}")
            return True
        except Exception as e:
            logger.exception(f"Failed to delete schedule {schedule_name}: {e}")
            return False


# Facade
eventbridge_scheduler = EventBridgeSchedulerService()

async def schedule_silent_for_plan(plan_id: int, when_utc: datetime) -> bool:
    return await eventbridge_scheduler.schedule_silent_notification(plan_id, when_utc)

async def cancel_silent_for_plan(plan_id: int) -> bool:
    return await eventbridge_scheduler.cancel_silent_notification(plan_id)
