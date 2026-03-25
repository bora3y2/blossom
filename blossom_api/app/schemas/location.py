from datetime import datetime

from pydantic import BaseModel


class CountryResponse(BaseModel):
    id: int
    name: str
    created_at: datetime


class CountryCreateRequest(BaseModel):
    name: str


class StateResponse(BaseModel):
    id: int
    country_id: int
    name: str
    latitude: float
    longitude: float
    created_at: datetime


class StateCreateRequest(BaseModel):
    name: str
    latitude: float
    longitude: float


class StateUpdateRequest(BaseModel):
    name: str | None = None
    latitude: float | None = None
    longitude: float | None = None


class WeatherResponse(BaseModel):
    state_id: int
    state_name: str
    country_name: str
    latitude: float
    longitude: float
    temperature_celsius: float
