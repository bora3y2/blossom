from typing import Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import require_admin
from app.db.session import get_db_session
from app.schemas.ai import AiConnectionTestResponse, AiSettingsResponse, AiSettingsUpdateRequest
from app.schemas.community import (
    AuditLogEntryResponse,
    AuditLogListResponse,
    CommunityCommentResponse,
    CommunityFeedResponse,
    CommunityPostResponse,
    DeleteResponse,
    ReportListResponse,
    ReportResponse,
    ReportStatusUpdateRequest,
    VisibilityUpdateRequest,
)
from app.schemas.plant import PlantCreateRequest, PlantResponse, PlantUpdateRequest
from app.services.ai_service import ai_service
from app.services.ai_settings_service import ai_settings_service
from app.services.community_service import community_service
from app.services.plant_service import plant_service

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/ai-settings", response_model=AiSettingsResponse)
async def get_ai_settings(
    _: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> AiSettingsResponse:
    settings_data = await ai_settings_service.get_settings(session)
    return AiSettingsResponse(**settings_data)


@router.patch("/ai-settings", response_model=AiSettingsResponse)
async def update_ai_settings(
    payload: AiSettingsUpdateRequest,
    profile: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> AiSettingsResponse:
    settings_data = await ai_settings_service.update_settings(
        session,
        payload.model_dump(exclude_unset=True),
        updated_by=profile["id"],
    )
    return AiSettingsResponse(**settings_data)


@router.post("/ai-settings/test-connection", response_model=AiConnectionTestResponse)
async def test_ai_connection(
    _: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> AiConnectionTestResponse:
    result = await ai_service.test_connection(session)
    return AiConnectionTestResponse(**result)


@router.get("/plants", response_model=list[PlantResponse])
async def list_admin_plants(
    _: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> list[PlantResponse]:
    plants = await plant_service.list_plants(session, include_inactive=True)
    return [PlantResponse(**plant) for plant in plants]


@router.post("/plants", response_model=PlantResponse)
async def create_admin_plant(
    payload: PlantCreateRequest,
    profile: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> PlantResponse:
    plant = await plant_service.create_plant(
        session,
        payload.model_dump(),
        created_by_user_id=profile["id"],
    )
    return PlantResponse(**plant)


@router.patch("/plants/{plant_id}", response_model=PlantResponse)
async def update_admin_plant(
    plant_id: str,
    payload: PlantUpdateRequest,
    _: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> PlantResponse:
    plant = await plant_service.update_plant(
        session,
        plant_id,
        payload.model_dump(exclude_unset=True),
    )
    return PlantResponse(**plant)


@router.delete("/plants/{plant_id}", response_model=PlantResponse)
async def delete_admin_plant(
    plant_id: str,
    _: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> PlantResponse:
    plant = await plant_service.archive_plant(session, plant_id)
    return PlantResponse(**plant)


# ── Community Moderation ───────────────────────────────────────────────

@router.get("/community/posts", response_model=CommunityFeedResponse)
async def list_admin_posts(
    profile: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityFeedResponse:
    items = await community_service.list_posts(
        session,
        current_user_id=profile["id"],
        include_hidden=True,
    )
    return CommunityFeedResponse(items=items, meta={"count": len(items)})


@router.patch("/community/posts/{post_id}/visibility", response_model=CommunityPostResponse)
async def set_post_visibility(
    post_id: str,
    payload: VisibilityUpdateRequest,
    profile: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityPostResponse:
    post = await community_service.set_post_visibility(
        session,
        post_id=post_id,
        hidden_by_admin=payload.hidden_by_admin,
        current_user_id=profile["id"],
    )
    return CommunityPostResponse(**post)


@router.delete("/community/posts/{post_id}", response_model=DeleteResponse)
async def admin_delete_post(
    post_id: str,
    profile: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> DeleteResponse:
    await community_service.admin_delete_post(
        session,
        post_id=post_id,
        admin_user_id=profile["id"],
    )
    return DeleteResponse(success=True, message="Post deleted permanently.")


@router.patch("/community/comments/{comment_id}/visibility", response_model=CommunityCommentResponse)
async def set_comment_visibility(
    comment_id: str,
    payload: VisibilityUpdateRequest,
    profile: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> CommunityCommentResponse:
    comment = await community_service.set_comment_visibility(
        session,
        comment_id=comment_id,
        hidden_by_admin=payload.hidden_by_admin,
        admin_user_id=profile["id"],
    )
    return CommunityCommentResponse(**comment)


@router.delete("/community/comments/{comment_id}", response_model=DeleteResponse)
async def admin_delete_comment(
    comment_id: str,
    profile: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> DeleteResponse:
    await community_service.admin_delete_comment(
        session,
        comment_id=comment_id,
        admin_user_id=profile["id"],
    )
    return DeleteResponse(success=True, message="Comment deleted permanently.")


# ── Reports ────────────────────────────────────────────────────────────

@router.get("/community/reports", response_model=ReportListResponse)
async def list_admin_reports(
    status_filter: str | None = Query(None, alias="status"),
    _: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> ReportListResponse:
    items = await community_service.list_reports(
        session,
        status_filter=status_filter,
    )
    return ReportListResponse(items=items, meta={"count": len(items)})


@router.patch("/community/reports/{report_id}", response_model=ReportResponse)
async def update_report_status(
    report_id: str,
    payload: ReportStatusUpdateRequest,
    profile: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> ReportResponse:
    report = await community_service.update_report_status(
        session,
        report_id=report_id,
        new_status=payload.status,
        admin_user_id=profile["id"],
    )
    return ReportResponse(**report)


# ── Audit Log ──────────────────────────────────────────────────────────

@router.get("/audit-log", response_model=AuditLogListResponse)
async def list_audit_log(
    _: dict[str, Any] = Depends(require_admin),
    session: AsyncSession = Depends(get_db_session),
) -> AuditLogListResponse:
    items = await community_service.list_audit_log(session)
    return AuditLogListResponse(items=items, meta={"count": len(items)})
