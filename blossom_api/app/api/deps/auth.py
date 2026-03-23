from typing import Any

from fastapi import Depends, HTTPException, status

from app.core.security import get_bearer_token
from app.services.profile_service import profile_service
from app.services.supabase_auth import AuthenticatedUser, supabase_auth_service


async def require_access_token(token: str = Depends(get_bearer_token)) -> str:
    return token


async def get_authenticated_user(
    token: str = Depends(require_access_token),
) -> AuthenticatedUser:
    return supabase_auth_service.decode_access_token(token)


async def get_current_profile(
    current_user: AuthenticatedUser = Depends(get_authenticated_user),
) -> dict[str, Any]:
    return await profile_service.sync_profile_from_auth(
        profile_id=current_user.user_id,
        email=current_user.email,
    )


async def require_admin(
    profile: dict[str, Any] = Depends(get_current_profile),
) -> dict[str, Any]:
    if profile["role"] != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return profile
