from dataclasses import dataclass

import jwt
from fastapi import HTTPException, status

from app.core.config import settings
from supabase import create_client, Client

@dataclass(slots=True)
class AuthenticatedUser:
    user_id: str
    email: str | None
    auth_role: str | None


class SupabaseAuthService:
    def __init__(self):
        self.admin_client: Client | None = None
        if settings.supabase_url and settings.supabase_service_role_key:
            self.admin_client = create_client(
                settings.supabase_url,
                settings.supabase_service_role_key
            )
    def decode_access_token(self, token: str) -> AuthenticatedUser:
        if not settings.supabase_jwt_secret and settings.environment != "local":
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="SUPABASE_JWT_SECRET is not configured",
            )
        try:
            if settings.supabase_jwt_secret:
                payload = jwt.decode(
                    token,
                    settings.supabase_jwt_secret,
                    algorithms=["HS256"],
                    audience="authenticated",
                )
            else:
                payload = jwt.decode(token, options={"verify_signature": False})
        except jwt.PyJWTError as exc:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid access token",
            ) from exc
        subject = payload.get("sub")
        if not subject:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid access token payload",
            )
        return AuthenticatedUser(
            user_id=str(subject),
            email=payload.get("email"),
            auth_role=payload.get("role"),
        )

    def delete_user_account(self, user_id: str) -> None:
        if not self.admin_client:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Supabase admin client not configured",
            )
        try:
            self.admin_client.auth.admin.delete_user(user_id)
        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Failed to delete user account: {str(e)}",
            )


supabase_auth_service = SupabaseAuthService()
