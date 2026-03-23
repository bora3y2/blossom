from typing import Any

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_profile
from app.db.session import get_db_session
from app.schemas.garden import CareTaskCompletionResponse, UserPlantCreateRequest, UserPlantResponse
from app.services.garden_service import garden_service

router = APIRouter(prefix="/garden", tags=["garden"])


@router.get("/plants", response_model=list[UserPlantResponse])
async def list_my_garden(
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> list[UserPlantResponse]:
    items = await garden_service.list_user_plants(session, profile["id"])
    return [UserPlantResponse(**item) for item in items]


@router.get("/plants/{user_plant_id}", response_model=UserPlantResponse)
async def get_my_garden_plant(
    user_plant_id: str,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> UserPlantResponse:
    item = await garden_service.get_user_plant(session, profile["id"], user_plant_id)
    return UserPlantResponse(**item)


@router.post("/tasks/{task_id}/complete", response_model=CareTaskCompletionResponse)
async def complete_my_care_task(
    task_id: str,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> CareTaskCompletionResponse:
    item = await garden_service.complete_care_task(session, profile["id"], task_id)
    return CareTaskCompletionResponse(**item)


@router.post("/plants", response_model=UserPlantResponse)
async def add_plant_to_garden(
    payload: UserPlantCreateRequest,
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> UserPlantResponse:
    item = await garden_service.add_plant_to_garden(
        session,
        profile["id"],
        payload.model_dump(),
    )
    return UserPlantResponse(**item)
