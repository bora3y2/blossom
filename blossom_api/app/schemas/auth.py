from pydantic import BaseModel

from app.schemas.profile import ProfileResponse


class SessionResponse(BaseModel):
    provider: str
    authenticated: bool
    user_id: str
    email: str
    auth_role: str | None
    app_role: str
    is_admin: bool
    profile: ProfileResponse
