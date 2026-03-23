from typing import Any

from fastapi import APIRouter, Depends
from fastapi import UploadFile, File

from app.api.deps.auth import get_current_profile, require_admin
from app.schemas.profile import ProfileResponse, ProfileRoleUpdateRequest, ProfileUpdateRequest
from app.schemas.community import DeleteResponse
from app.services.profile_service import profile_service
from app.services.supabase_auth import supabase_auth_service

router = APIRouter(prefix="/profiles", tags=["profiles"])


@router.get("/me", response_model=ProfileResponse)
async def get_my_profile(
    profile: dict[str, Any] = Depends(get_current_profile),
) -> ProfileResponse:
    return ProfileResponse(**profile)


@router.patch("/me", response_model=ProfileResponse)
async def update_my_profile(
    payload: ProfileUpdateRequest,
    profile: dict[str, Any] = Depends(get_current_profile),
) -> ProfileResponse:
    updated_profile = await profile_service.update_profile(
        profile_id=profile["id"],
        updates=payload.model_dump(exclude_unset=True),
    )
    return ProfileResponse(**updated_profile)


@router.patch("/{profile_id}/role", response_model=ProfileResponse)
async def update_profile_role(
    profile_id: str,
    payload: ProfileRoleUpdateRequest,
    _: dict[str, Any] = Depends(require_admin),
) -> ProfileResponse:
    updated_profile = await profile_service.update_profile_role(
        profile_id=profile_id,
        role=payload.role,
    )
    return ProfileResponse(**updated_profile)


@router.post("/me/avatar", response_model=ProfileResponse)
async def upload_my_avatar(
    file: UploadFile = File(...),
    profile: dict[str, Any] = Depends(get_current_profile),
) -> ProfileResponse:
    file_bytes = await file.read()
    updated_profile = await profile_service.upload_avatar(
        profile_id=profile["id"],
        file_bytes=file_bytes,
        content_type=file.content_type or "image/jpeg",
    )
    return ProfileResponse(**updated_profile)


@router.delete("/me", response_model=DeleteResponse)
async def delete_my_account(
    profile: dict[str, Any] = Depends(get_current_profile),
) -> DeleteResponse:
    supabase_auth_service.delete_user_account(profile["id"])
    await profile_service.delete_profile(profile["id"])
    return DeleteResponse(success=True)
