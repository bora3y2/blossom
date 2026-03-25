from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class LocationService:
    async def list_countries(self, session: AsyncSession) -> list[dict[str, Any]]:
        result = await session.execute(
            text("SELECT id, name, created_at FROM public.countries ORDER BY name")
        )
        return [dict(row._mapping) for row in result]

    async def create_country(self, session: AsyncSession, name: str) -> dict[str, Any]:
        result = await session.execute(
            text(
                """
                INSERT INTO public.countries (name)
                VALUES (:name)
                RETURNING id, name, created_at
                """
            ),
            {"name": name},
        )
        await session.commit()
        row = result.fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create country",
            )
        return dict(row._mapping)

    async def delete_country(self, session: AsyncSession, country_id: int) -> None:
        result = await session.execute(
            text("DELETE FROM public.countries WHERE id = :id RETURNING id"),
            {"id": country_id},
        )
        await session.commit()
        if not result.fetchone():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Country not found",
            )

    async def list_states(
        self, session: AsyncSession, country_id: int
    ) -> list[dict[str, Any]]:
        result = await session.execute(
            text(
                """
                SELECT id, country_id, name, latitude, longitude, created_at
                FROM public.states
                WHERE country_id = :country_id
                ORDER BY name
                """
            ),
            {"country_id": country_id},
        )
        return [dict(row._mapping) for row in result]

    async def create_state(
        self,
        session: AsyncSession,
        country_id: int,
        name: str,
        latitude: float,
        longitude: float,
    ) -> dict[str, Any]:
        result = await session.execute(
            text(
                """
                INSERT INTO public.states (country_id, name, latitude, longitude)
                VALUES (:country_id, :name, :latitude, :longitude)
                RETURNING id, country_id, name, latitude, longitude, created_at
                """
            ),
            {
                "country_id": country_id,
                "name": name,
                "latitude": latitude,
                "longitude": longitude,
            },
        )
        await session.commit()
        row = result.fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Failed to create state",
            )
        return dict(row._mapping)

    async def update_state(
        self,
        session: AsyncSession,
        state_id: int,
        updates: dict[str, Any],
    ) -> dict[str, Any]:
        allowed = {k: v for k, v in updates.items() if k in {"name", "latitude", "longitude"}}
        if not allowed:
            return await self.get_state_by_id(session, state_id)

        set_clauses = ", ".join(f"{k} = :{k}" for k in allowed)
        result = await session.execute(
            text(
                f"""
                UPDATE public.states
                SET {set_clauses}
                WHERE id = :state_id
                RETURNING id, country_id, name, latitude, longitude, created_at
                """
            ),
            {"state_id": state_id, **allowed},
        )
        await session.commit()
        row = result.fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="State not found",
            )
        return dict(row._mapping)

    async def delete_state(self, session: AsyncSession, state_id: int) -> None:
        result = await session.execute(
            text("DELETE FROM public.states WHERE id = :id RETURNING id"),
            {"id": state_id},
        )
        await session.commit()
        if not result.fetchone():
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="State not found",
            )

    async def get_state_by_id(
        self, session: AsyncSession, state_id: int
    ) -> dict[str, Any]:
        result = await session.execute(
            text(
                """
                SELECT s.id, s.country_id, s.name, s.latitude, s.longitude, s.created_at,
                       c.name AS country_name
                FROM public.states s
                JOIN public.countries c ON c.id = s.country_id
                WHERE s.id = :state_id
                """
            ),
            {"state_id": state_id},
        )
        row = result.fetchone()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="State not found",
            )
        return dict(row._mapping)


location_service = LocationService()
