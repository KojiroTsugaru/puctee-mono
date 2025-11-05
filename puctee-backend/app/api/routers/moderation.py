# Content moderation endpoints for reporting and blocking
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from datetime import datetime, timezone
from app.core.auth import get_current_username
from app.db.session import get_db
from app.models import User, ContentReport, BlockedUser
from app.schemas import (
    ContentReportCreate,
    ContentReportResponse,
    BlockUserCreate,
    BlockedUserResponse,
    BlockedUserListResponse,
    UserResponse
)

router = APIRouter()

# ============================================================================
# Content Reporting Endpoints
# ============================================================================

@router.post("/reports", response_model=ContentReportResponse, status_code=status.HTTP_201_CREATED)
async def create_content_report(
    report_data: ContentReportCreate,
    current_user: str = Depends(get_current_username),
    db: AsyncSession = Depends(get_db),
):
    """
    Report inappropriate content (penalty requests, plans, or user profiles).
    
    This endpoint allows users to flag content that violates community guidelines.
    Reports are reviewed by moderators within 24 hours.
    """
    # Get current user (reporter)
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    reporter = result.scalar_one_or_none()
    if not reporter:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Validate that user is not reporting themselves
    if report_data.reported_user_id and report_data.reported_user_id == reporter.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot report your own content"
        )
    
    # Check for duplicate reports (same reporter, content_type, content_id within last 24 hours)
    result = await db.execute(
        select(ContentReport).where(
            and_(
                ContentReport.reporter_user_id == reporter.id,
                ContentReport.content_type == report_data.content_type,
                ContentReport.content_id == report_data.content_id,
                ContentReport.status == 'pending'
            )
        )
    )
    existing_report = result.scalar_one_or_none()
    if existing_report:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="You have already reported this content"
        )
    
    # Create content report
    content_report = ContentReport(
        reporter_user_id=reporter.id,
        reported_user_id=report_data.reported_user_id,
        content_type=report_data.content_type,
        content_id=report_data.content_id,
        reason=report_data.reason,
        description=report_data.description,
        status='pending'
    )
    
    db.add(content_report)
    await db.commit()
    await db.refresh(content_report)
    
    print(f"📝 Content report created: {content_report.id} by user {reporter.username}")
    print(f"   Type: {report_data.content_type}, Reason: {report_data.reason}")
    
    return content_report


@router.get("/reports/my-reports", response_model=List[ContentReportResponse])
async def get_my_reports(
    current_user: str = Depends(get_current_username),
    db: AsyncSession = Depends(get_db),
):
    """
    Get all reports submitted by the current user.
    """
    # Get current user
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Get all reports by this user
    result = await db.execute(
        select(ContentReport)
        .where(ContentReport.reporter_user_id == user.id)
        .order_by(ContentReport.created_at.desc())
    )
    reports = result.scalars().all()
    
    return reports


# ============================================================================
# User Blocking Endpoints
# ============================================================================

@router.post("/block", response_model=BlockedUserResponse, status_code=status.HTTP_201_CREATED)
async def block_user(
    block_data: BlockUserCreate,
    current_user: str = Depends(get_current_username),
    db: AsyncSession = Depends(get_db),
):
    """
    Block a user to prevent them from interacting with you.
    
    Blocked users:
    - Cannot send you friend requests
    - Cannot invite you to plans
    - Will not appear in your friend lists or search results
    """
    # Get current user (blocker)
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    blocker = result.scalar_one_or_none()
    if not blocker:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Validate that user is not blocking themselves
    if block_data.blocked_user_id == blocker.id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Cannot block yourself"
        )
    
    # Verify blocked user exists
    result = await db.execute(
        select(User).where(User.id == block_data.blocked_user_id)
    )
    blocked_user = result.scalar_one_or_none()
    if not blocked_user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User to block not found"
        )
    
    # Check if already blocked
    result = await db.execute(
        select(BlockedUser).where(
            and_(
                BlockedUser.blocker_user_id == blocker.id,
                BlockedUser.blocked_user_id == block_data.blocked_user_id
            )
        )
    )
    existing_block = result.scalar_one_or_none()
    if existing_block:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="User is already blocked"
        )
    
    # Create block
    blocked_user_entry = BlockedUser(
        blocker_user_id=blocker.id,
        blocked_user_id=block_data.blocked_user_id,
        reason=block_data.reason
    )
    
    db.add(blocked_user_entry)
    await db.commit()
    await db.refresh(blocked_user_entry)
    
    print(f"🚫 User {blocker.username} blocked user ID {block_data.blocked_user_id}")
    
    return blocked_user_entry


@router.delete("/block/{blocked_user_id}", status_code=status.HTTP_204_NO_CONTENT)
async def unblock_user(
    blocked_user_id: int,
    current_user: str = Depends(get_current_username),
    db: AsyncSession = Depends(get_db),
):
    """
    Unblock a previously blocked user.
    """
    # Get current user
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Find the block entry
    result = await db.execute(
        select(BlockedUser).where(
            and_(
                BlockedUser.blocker_user_id == user.id,
                BlockedUser.blocked_user_id == blocked_user_id
            )
        )
    )
    block_entry = result.scalar_one_or_none()
    if not block_entry:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Block entry not found"
        )
    
    await db.delete(block_entry)
    await db.commit()
    
    print(f"✅ User {user.username} unblocked user ID {blocked_user_id}")
    
    return None


@router.get("/blocked-users", response_model=List[UserResponse])
async def get_blocked_users(
    current_user: str = Depends(get_current_username),
    db: AsyncSession = Depends(get_db),
):
    """
    Get list of all users blocked by the current user.
    """
    # Get current user
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Get all blocked users
    result = await db.execute(
        select(User)
        .join(BlockedUser, BlockedUser.blocked_user_id == User.id)
        .where(BlockedUser.blocker_user_id == user.id)
        .order_by(BlockedUser.created_at.desc())
    )
    blocked_users = result.scalars().all()
    
    return blocked_users


@router.get("/is-blocked/{user_id}", response_model=dict)
async def check_if_blocked(
    user_id: int,
    current_user: str = Depends(get_current_username),
    db: AsyncSession = Depends(get_db),
):
    """
    Check if a specific user is blocked by the current user.
    """
    # Get current user
    result = await db.execute(
        select(User).where(User.username == current_user)
    )
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
    
    # Check if blocked
    result = await db.execute(
        select(BlockedUser).where(
            and_(
                BlockedUser.blocker_user_id == user.id,
                BlockedUser.blocked_user_id == user_id
            )
        )
    )
    is_blocked = result.scalar_one_or_none() is not None
    
    return {"is_blocked": is_blocked, "user_id": user_id}
