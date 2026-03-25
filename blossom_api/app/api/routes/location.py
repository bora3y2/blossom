from typing import Any

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps.auth import get_current_profile
from app.db.session import get_db_session
from app.schemas.location import StateResponse, CountryResponse, WeatherResponse
from app.services.location_service import location_service
from app.services.weather_service import weather_service

# Public router — no authentication needed (lookup data)
public_router = APIRouter(prefix="/location", tags=["location"])

# Auth router — requires valid user session
weather_router = APIRouter(prefix="/weather", tags=["weather"])


@public_router.get("/countries", response_model=list[CountryResponse])
async def list_countries(
    session: AsyncSession = Depends(get_db_session),
) -> list[CountryResponse]:
    countries = await location_service.list_countries(session)
    return [CountryResponse(**c) for c in countries]


@public_router.get("/countries/{country_id}/states", response_model=list[StateResponse])
async def list_states(
    country_id: int,
    session: AsyncSession = Depends(get_db_session),
) -> list[StateResponse]:
    states = await location_service.list_states(session, country_id)
    return [StateResponse(**s) for s in states]


@weather_router.get("/current", response_model=WeatherResponse)
async def get_current_weather(
    state_id: int = Query(..., description="The state ID to get weather for"),
    _: dict[str, Any] = Depends(get_current_profile),
    session: AsyncSession = Depends(get_db_session),
) -> WeatherResponse:
    state = await location_service.get_state_by_id(session, state_id)
    temperature = await weather_service.get_temperature_celsius(
        latitude=state["latitude"],
        longitude=state["longitude"],
    )
    return WeatherResponse(
        state_id=state["id"],
        state_name=state["name"],
        country_name=state["country_name"],
        latitude=state["latitude"],
        longitude=state["longitude"],
        temperature_celsius=temperature,
    )
