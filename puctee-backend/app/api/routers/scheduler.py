"""
Scheduler endpoint for EventBridge Scheduler to trigger scheduled tasks
"""
import json
import logging
from fastapi import APIRouter, HTTPException, Header, status, Depends, Request
from pydantic import BaseModel
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from app.core.config import settings
from app.db.session import get_db
from app.models import Plan
from app.services.push_notification import send_silent_wakeup_arrival_notification

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/scheduler", tags=["scheduler"])


class SchedulerRequest(BaseModel):
    """Request body from EventBridge Scheduler"""
    plan_id: int


@router.post("/silent-notification")
async def trigger_silent_notification(
    raw_request: Request,
    db: AsyncSession = Depends(get_db),
    x_api_key: Optional[str] = Header(None, alias="X-API-Key")
):
    """
    Endpoint called by EventBridge Scheduler to send silent notifications
    
    This endpoint is triggered at the scheduled time to wake up iOS apps
    and check for arrival at plan locations.
    """
    # Log raw request body for debugging
    raw_body = await raw_request.body()
    logger.info(f"[SCHEDULER] Raw request body: {raw_body.decode('utf-8')}")
    
    # Parse request - handle both direct format and EventBridge format
    try:
        body_dict = json.loads(raw_body)
        logger.info(f"[SCHEDULER] Parsed body: {body_dict}")
        
        # Check if this is an EventBridge event (has 'detail' field)
        if 'detail' in body_dict and isinstance(body_dict['detail'], dict):
            # Extract from EventBridge event structure
            logger.info(f"[SCHEDULER] Detected EventBridge event structure")
            plan_id = body_dict['detail'].get('plan_id')
            if plan_id is None:
                raise ValueError("plan_id not found in event detail")
            request = SchedulerRequest(plan_id=plan_id)
        elif 'plan_id' in body_dict:
            # Direct request format (from InputTransformer)
            request = SchedulerRequest(**body_dict)
        else:
            raise ValueError("plan_id not found in request")
    except Exception as e:
        logger.error(f"[SCHEDULER] Failed to parse request: {e}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Invalid request format: {str(e)}"
        )
    
    # Verify API key (required for security)
    if not settings.SCHEDULER_API_KEY:
        logger.error("[SCHEDULER] SCHEDULER_API_KEY not configured")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Server configuration error"
        )
    
    if not x_api_key or x_api_key != settings.SCHEDULER_API_KEY:
        logger.warning(f"[SCHEDULER] Unauthorized request - API key mismatch")
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing API key"
        )
    
    logger.info(f"[SCHEDULER] Received scheduled silent notification request for plan {request.plan_id}")
    
    try:
        # Get plan and participants
        result = await db.execute(
            select(Plan).options(selectinload(Plan.participants)).where(Plan.id == request.plan_id)
        )
        plan = result.scalar_one_or_none()
        
        if not plan:
            logger.warning(f"[SCHEDULER] Plan {request.plan_id} not found")
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plan not found"
            )
        
        logger.info(f"[SCHEDULER] Found plan '{plan.title}' with {len(plan.participants)} participants")
        
        # Send silent notifications to all participants
        notification_count = 0
        for user in plan.participants:
            if user.push_token:
                try:
                    logger.info(f"[SCHEDULER] Sending silent notification to user {user.username}")
                    success = await send_silent_wakeup_arrival_notification(
                        device_token=user.push_token,
                        plan_id=request.plan_id
                    )
                    if success:
                        notification_count += 1
                        logger.info(f"[SCHEDULER] ✅ Sent to {user.username}")
                    else:
                        logger.warning(f"[SCHEDULER] ❌ Failed to send to {user.username}")
                except Exception as e:
                    logger.error(f"[SCHEDULER] Error sending to {user.username}: {e}")
            else:
                logger.info(f"[SCHEDULER] User {user.username} has no push token")
        
        logger.info(f"[SCHEDULER] Completed for plan {request.plan_id}. Sent {notification_count} notifications")
        
        return {
            "success": True,
            "plan_id": request.plan_id,
            "notifications_sent": notification_count,
            "total_participants": len(plan.participants)
        }
    
    except HTTPException:
        raise
    except Exception as e:
        logger.exception(f"[SCHEDULER] Error processing plan {request.plan_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )
