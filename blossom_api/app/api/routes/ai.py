from typing import Any

from fastapi import APIRouter, Depends, File, Form, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_profile
from app.db.session import get_db_session
from app.schemas.ai import AiPlantFlowResponse, PlantIdentificationResponse
from app.services.plant_flow import PLANT_ADD_QUESTIONS, PLANT_RESULT_FIELDS
from app.services.ai_service import ai_service

router = APIRouter(prefix="/ai", tags=["ai"])


@router.get("/plant-add-flow", response_model=AiPlantFlowResponse)
async def get_ai_plant_add_flow() -> AiPlantFlowResponse:
    return AiPlantFlowResponse(
        questions=PLANT_ADD_QUESTIONS,
        result_fields=PLANT_RESULT_FIELDS,
        input_mode="image_only",
    )


@router.post("/identify-plant", response_model=PlantIdentificationResponse)
async def identify_plant(
    image: UploadFile = File(...),
    location_type: str | None = Form(default=None),
    light_condition: str | None = Form(default=None),
    caring_style: str | None = Form(default=None),
    pet_safety_priority: str | None = Form(default=None),
    add_to_garden: bool = Form(default=False),
    custom_name: str | None = Form(default=None),
    profile: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> PlantIdentificationResponse:
    answers = {
        key: value
        for key, value in {
            "location_type": location_type,
            "light_condition": light_condition,
            "caring_style": caring_style,
            "pet_safety_priority": pet_safety_priority,
        }.items()
        if value is not None
    }
    result = await ai_service.identify_plant(
        session=session,
        user_id=profile["id"],
        image=image,
        answers=answers,
        add_to_garden=add_to_garden,
        custom_name=custom_name,
    )
    return PlantIdentificationResponse(**result)
