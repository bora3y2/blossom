from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict

from app.schemas.plant import PlantResponse


class CareTaskResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    user_plant_id: str
    title: str
    description: str | None
    task_type: Literal["water", "light", "temperature", "fertilize", "custom"]
    due_at: datetime | None
    completed_at: datetime | None
    is_enabled: bool
    created_at: datetime
    updated_at: datetime


class CareTaskCompletionResponse(BaseModel):
    completed_task: CareTaskResponse
    next_task: CareTaskResponse | None


class UserPlantCreateRequest(BaseModel):
    plant_id: str
    custom_name: str | None = None
    location_type: Literal["Indoor", "Outdoor"]
    light_condition: Literal["Low Light", "Indirect", "Direct Sunlight"]
    caring_style: Literal["I'm a bit forgetful", "I love caring for them daily"]
    pet_safety_priority: Literal["Yes, keep it safe", "No pets here"]
    created_via: Literal["manual", "ai_image_discovery", "admin"] = "manual"


class UserPlantResponse(BaseModel):
    model_config = ConfigDict(extra="ignore")

    id: str
    user_id: str
    plant_id: str
    custom_name: str | None
    location_type: Literal["Indoor", "Outdoor"]
    light_condition: Literal["Low Light", "Indirect", "Direct Sunlight"]
    caring_style: Literal["I'm a bit forgetful", "I love caring for them daily"]
    pet_safety_priority: Literal["Yes, keep it safe", "No pets here"]
    created_via: Literal["manual", "ai_image_discovery", "admin"]
    created_at: datetime
    updated_at: datetime
    plant: PlantResponse
    care_tasks: list[CareTaskResponse]
