from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict


class ProfileResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    email: str
    display_name: str | None
    avatar_path: str | None
    role: Literal["user", "admin"]
    notifications_enabled: bool
    created_at: datetime
    updated_at: datetime


class ProfileUpdateRequest(BaseModel):
    display_name: str | None = None
    avatar_path: str | None = None
    notifications_enabled: bool | None = None


class ProfileRoleUpdateRequest(BaseModel):
    role: Literal["user", "admin"]
