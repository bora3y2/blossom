from dataclasses import dataclass

import jwt
from jwt import PyJWKClient
from fastapi import HTTPException, status

from app.core.config import settings
from supabase import create_client, Client

@dataclass(slots=True)
class AuthenticatedUser:
    user_id: str
    email: str | None
    auth_role: str | None


_jwks_client: PyJWKClient | None = None


def _get_jwks_client() -> PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        _jwks_client = PyJWKClient(f"{settings.supabase_url}/auth/v1/.well-known/jwks.json")
    return _jwks_client


class SupabaseAuthService:
    def __init__(self):
        self.admin_client: Client | None = None
        if settings.supabase_url and settings.supabase_service_role_key:
            self.admin_client = create_client(
                settings.supabase_url,
                settings.supabase_service_role_key
            )

    def decode_access_token(self, token: str) -> AuthenticatedUser:
        try:
            if settings.environment == "local" and not settings.supabase_jwt_secret:
                payload = jwt.decode(token, options={"verify_signature": False})
            elif settings.supabase_jwt_secret:
                payload = jwt.decode(
                    token,
                    settings.supabase_jwt_secret,
                    algorithms=["HS256"],
                    audience="authenticated",
                )
            else:
                signing_key = _get_jwks_client().get_signing_key_from_jwt(token)
                payload = jwt.decode(
                    token,
                    signing_key.key,
                    algorithms=["ES256", "RS256"],
                    audience="authenticated",
                )
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
