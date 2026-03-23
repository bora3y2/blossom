from typing import Any

from fastapi import APIRouter, Depends

from app.api.deps.auth import get_authenticated_user, get_current_profile
from app.schemas.auth import SessionResponse
from app.services.supabase_auth import AuthenticatedUser

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/session", response_model=SessionResponse)
async def get_auth_session(
    current_user: AuthenticatedUser = Depends(get_authenticated_user),
    profile: dict[str, Any] = Depends(get_current_profile),
) -> SessionResponse:
    return SessionResponse(
        provider="supabase",
        authenticated=True,
        user_id=current_user.user_id,
        email=current_user.email or profile["email"],
        auth_role=current_user.auth_role,
        app_role=profile["role"],
        is_admin=profile["role"] == "admin",
        profile=profile,
    )
