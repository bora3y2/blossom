import httpx
from fastapi import HTTPException, status

OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"


class WeatherService:
    async def get_temperature_celsius(self, latitude: float, longitude: float) -> float:
        params = {
            "latitude": latitude,
            "longitude": longitude,
            "current": "temperature_2m",
            "temperature_unit": "celsius",
        }
        try:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.get(OPEN_METEO_URL, params=params)
                response.raise_for_status()
                data = response.json()
                return float(data["current"]["temperature_2m"])
        except httpx.HTTPStatusError as exc:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Weather service returned an error: {exc.response.status_code}",
            ) from exc
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail=f"Weather service unavailable: {exc}",
            ) from exc


weather_service = WeatherService()
