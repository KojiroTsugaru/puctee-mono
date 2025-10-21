"""
Scheduler endpoint for EventBridge Scheduler to trigger scheduled tasks
"""
import logging
from fastapi import APIRouter, HTTPException, Header, status
from pydantic import BaseModel
from typing import Optional

from app.core.config import settings
from app.services.scheduler.silent_notification import run_send_silent

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/scheduler", tags=["scheduler"])


class SchedulerRequest(BaseModel):
    """Request body from EventBridge Scheduler"""
    plan_id: int


@router.post("/silent-notification")
async def trigger_silent_notification(
    request: SchedulerRequest,
    x_api_key: Optional[str] = Header(None, alias="X-API-Key")
):
    """
    Endpoint called by EventBridge Scheduler to send silent notifications
    
    This endpoint is triggered at the scheduled time to wake up iOS apps
    and check for arrival at plan locations.
    """
    # Verify API key if configured
    if settings.SCHEDULER_API_KEY:
        if not x_api_key or x_api_key != settings.SCHEDULER_API_KEY:
            logger.warning(f"Unauthorized scheduler request for plan {request.plan_id}")
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid or missing API key"
            )
    
    logger.info(f"[SCHEDULER] Received scheduled silent notification request for plan {request.plan_id}")
    
    try:
        result = run_send_silent(request.plan_id)
        
        if result.get("success"):
            logger.info(f"[SCHEDULER] Successfully processed silent notification for plan {request.plan_id}")
            return {
                "success": True,
                "plan_id": request.plan_id,
                "notifications_sent": result.get("notifications_sent", 0),
                "total_participants": result.get("total_participants", 0)
            }
        else:
            logger.error(f"[SCHEDULER] Failed to process silent notification for plan {request.plan_id}: {result.get('error')}")
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to send notifications: {result.get('error')}"
            )
    
    except Exception as e:
        logger.exception(f"[SCHEDULER] Error processing silent notification for plan {request.plan_id}: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error"
        )
