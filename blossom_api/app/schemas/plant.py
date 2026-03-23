from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict


class PlantResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    common_name: str
    scientific_name: str | None
    short_description: str
    image_path: str | None
    water_requirements: str
    light_requirements: str
    temperature: str
    pet_safe: bool
    source: Literal["admin", "ai_image_discovery"]
    ai_confidence: float | None
    created_by_user_id: str | None
    reviewed_by_admin: bool
    is_active: bool
    created_at: datetime
    updated_at: datetime


class PlantCreateRequest(BaseModel):
    common_name: str
    scientific_name: str | None = None
    short_description: str = ""
    image_path: str | None = None
    water_requirements: str
    light_requirements: str
    temperature: str
    pet_safe: bool = False
    source: Literal["admin", "ai_image_discovery"] = "admin"
    ai_confidence: float | None = None
    reviewed_by_admin: bool = False
    is_active: bool = True


class PlantUpdateRequest(BaseModel):
    common_name: str | None = None
    scientific_name: str | None = None
    short_description: str | None = None
    image_path: str | None = None
    water_requirements: str | None = None
    light_requirements: str | None = None
    temperature: str | None = None
    pet_safe: bool | None = None
    source: Literal["admin", "ai_image_discovery"] | None = None
    ai_confidence: float | None = None
    reviewed_by_admin: bool | None = None
    is_active: bool | None = None


class PlantAddFlowResponse(BaseModel):
    questions: list[dict[str, object]]
    result_fields: list[dict[str, str]]
