from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db_session
from app.schemas.plant import PlantAddFlowResponse, PlantResponse
from app.services.plant_flow import PLANT_ADD_QUESTIONS, PLANT_RESULT_FIELDS
from app.services.plant_service import plant_service

router = APIRouter(prefix="/plants", tags=["plants"])


@router.get("/catalog", response_model=list[PlantResponse])
async def list_plants(
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    location_type: str | None = Query(default=None),
    light_condition: str | None = Query(default=None),
    caring_style: str | None = Query(default=None),
    pet_safe_only: bool = Query(default=False),
    session: AsyncSession = Depends(get_db_session),
) -> list[PlantResponse]:
    plants = await plant_service.list_plants(
        session,
        limit=limit,
        offset=offset,
        location_type=location_type,
        light_condition=light_condition,
        caring_style=caring_style,
        pet_safe_only=pet_safe_only,
    )
    return [PlantResponse(**plant) for plant in plants]


@router.get("/add-flow", response_model=PlantAddFlowResponse)
async def get_add_plant_flow() -> PlantAddFlowResponse:
    return PlantAddFlowResponse(
        questions=PLANT_ADD_QUESTIONS,
        result_fields=PLANT_RESULT_FIELDS,
    )


@router.get("/{plant_id}", response_model=PlantResponse)
async def get_plant(
    plant_id: str,
    session: AsyncSession = Depends(get_db_session),
) -> PlantResponse:
    plant = await plant_service.get_plant_by_id(session, plant_id)
    return PlantResponse(**plant)
