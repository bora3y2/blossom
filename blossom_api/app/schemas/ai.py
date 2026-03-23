from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict

from app.schemas.garden import UserPlantResponse
from app.schemas.plant import PlantResponse


class AiPlantFlowResponse(BaseModel):
    questions: list[dict[str, object]]
    result_fields: list[dict[str, str]]
    input_mode: str


class AiSettingsResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    provider: str
    model: str
    system_prompt: str
    temperature: float
    max_tokens: int
    is_enabled: bool
    has_api_key: bool
    connection_last_tested_at: datetime | None
    connection_last_status: str | None
    updated_by: str | None
    created_at: datetime
    updated_at: datetime


class AiSettingsUpdateRequest(BaseModel):
    model: str | None = None
    system_prompt: str | None = None
    temperature: float | None = None
    max_tokens: int | None = None
    is_enabled: bool | None = None
    api_key: str | None = None


class AiConnectionTestResponse(BaseModel):
    success: bool
    message: str
    tested_at: datetime
    model: str


class PlantIdentificationResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    plant: PlantResponse
    matched_existing: bool
    created_new_plant: bool
    garden_item: UserPlantResponse | None
    missing_answers: list[str]
    next_questions: list[dict[str, object]]
    used_answers: dict[str, str]
    input_mode: str
    provider: str
    raw_result: dict[str, Any]
