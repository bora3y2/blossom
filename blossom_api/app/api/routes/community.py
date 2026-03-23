from typing import Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_profile
from app.db.session import get_db_session
from app.schemas.community import (
    CommunityCommentCreateRequest,
    CommunityCommentResponse,
    CommunityFeedResponse,
    CommunityPostCreateRequest,
    CommunityPostResponse,
    DeleteResponse,
    ReportResponse,
    ReportCreateRequest,
)
from app.services.community_service import community_service

router = APIRouter(prefix="/community", tags=["community"])


@router.get("/posts", response_model=CommunityFeedResponse)
async def list_posts(
    limit: int = Query(default=20, ge=1, le=100),
    offset: int = Query(default=0, ge=0),
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityFeedResponse:
    items = await community_service.list_posts(
        session,
        current_user_id=profile["id"],
        include_hidden=False,
        limit=limit,
        offset=offset,
    )
    return CommunityFeedResponse(
        items=items,
        meta={"count": len(items), "limit": limit, "offset": offset},
    )


@router.get("/posts/{post_id}", response_model=CommunityPostResponse)
async def get_post(
    post_id: str,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityPostResponse:
    item = await community_service.get_post(
        session,
        post_id,
        current_user_id=profile["id"],
        include_hidden=False,
    )
    return CommunityPostResponse(**item)


@router.post("/posts", response_model=CommunityPostResponse)
async def create_post(
    payload: CommunityPostCreateRequest,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityPostResponse:
    item = await community_service.create_post(
        session,
        user_id=profile["id"],
        payload=payload.model_dump(),
    )
    return CommunityPostResponse(**item)


@router.post("/posts/{post_id}/comments", response_model=CommunityCommentResponse)
async def create_comment(
    post_id: str,
    payload: CommunityCommentCreateRequest,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityCommentResponse:
    comment = await community_service.create_comment(
        session,
        user_id=profile["id"],
        post_id=post_id,
        content=payload.content,
    )
    return CommunityCommentResponse(**comment)


@router.post("/posts/{post_id}/like", response_model=CommunityPostResponse)
async def like_post(
    post_id: str,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityPostResponse:
    item = await community_service.like_post(
        session,
        user_id=profile["id"],
        post_id=post_id,
    )
    return CommunityPostResponse(**item)


@router.delete("/posts/{post_id}/like", response_model=CommunityPostResponse)
async def unlike_post(
    post_id: str,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityPostResponse:
    item = await community_service.unlike_post(
        session,
        user_id=profile["id"],
        post_id=post_id,
    )
    return CommunityPostResponse(**item)


@router.delete("/posts/{post_id}", response_model=DeleteResponse)
async def delete_post(
    post_id: str,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> DeleteResponse:
    await community_service.delete_post(
        session,
        post_id=post_id,
        user_id=profile["id"],
    )
    return DeleteResponse(success=True)


@router.delete("/comments/{comment_id}", response_model=DeleteResponse)
async def delete_comment(
    comment_id: str,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> DeleteResponse:
    await community_service.delete_comment(
        session,
        comment_id=comment_id,
        user_id=profile["id"],
    )
    return DeleteResponse(success=True)


@router.post("/posts/{post_id}/report", response_model=ReportResponse)
async def report_post(
    post_id: str,
    payload: ReportCreateRequest,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> ReportResponse:
    report = await community_service.report_post(
        session,
        post_id=post_id,
        reporter_id=profile["id"],
        reason=payload.reason,
    )
    return ReportResponse(**report)


@router.post("/comments/{comment_id}/report", response_model=ReportResponse)
async def report_comment(
    comment_id: str,
    payload: ReportCreateRequest,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> ReportResponse:
    report = await community_service.report_comment(
        session,
        comment_id=comment_id,
        reporter_id=profile["id"],
        reason=payload.reason,
    )
    return ReportResponse(**report)

