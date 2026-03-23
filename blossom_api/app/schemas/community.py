from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field, model_validator


class CommunityProfileSummary(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    display_name: str | None
    avatar_path: str | None


class CommunityCommentResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    post_id: str
    user_id: str
    content: str
    hidden_by_admin: bool
    created_at: datetime
    updated_at: datetime
    author: CommunityProfileSummary


class CommunityPostResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    user_id: str
    content: str
    image_path: str | None
    hidden_by_admin: bool
    created_at: datetime
    updated_at: datetime
    author: CommunityProfileSummary
    comments: list[CommunityCommentResponse]
    likes_count: int
    comments_count: int
    liked_by_me: bool


class CommunityPostCreateRequest(BaseModel):
    content: str = Field(default="")
    image_path: str | None = None

    @model_validator(mode="after")
    def validate_content_or_image(self) -> "CommunityPostCreateRequest":
        if not self.image_path and not self.content.strip():
            raise ValueError("Either content or image_path is required")
        return self


class CommunityCommentCreateRequest(BaseModel):
    content: str

    @model_validator(mode="after")
    def validate_content(self) -> "CommunityCommentCreateRequest":
        if not self.content.strip():
            raise ValueError("Comment content is required")
        return self


class VisibilityUpdateRequest(BaseModel):
    hidden_by_admin: bool


class CommunityFeedResponse(BaseModel):
    items: list[CommunityPostResponse]
    meta: dict[str, Any]


class ReportCreateRequest(BaseModel):
    reason: str = Field(min_length=1, max_length=1000)


class ReportResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    post_id: str | None
    comment_id: str | None
    reporter_user_id: str
    reporter: CommunityProfileSummary | None = None
    reason: str
    status: str
    reviewed_by: str | None
    created_at: datetime
    updated_at: datetime
    # Optional context about the reported content
    post_content: str | None = None
    comment_content: str | None = None
    target_author: CommunityProfileSummary | None = None


class ReportListResponse(BaseModel):
    items: list[ReportResponse]
    meta: dict[str, Any]


class ReportStatusUpdateRequest(BaseModel):
    status: str = Field(pattern=r"^(reviewed|dismissed)$")


class AuditLogEntryResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    admin_user_id: str
    admin_display_name: str | None = None
    action: str
    entity_type: str
    entity_id: str | None
    metadata: dict[str, Any]
    created_at: datetime


class AuditLogListResponse(BaseModel):
    items: list[AuditLogEntryResponse]
    meta: dict[str, Any]


class DeleteResponse(BaseModel):
    success: bool
    message: str
