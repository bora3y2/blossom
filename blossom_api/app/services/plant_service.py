from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


PLANT_SELECT_COLUMNS = """
    id::text as id,
    common_name,
    scientific_name,
    short_description,
    image_path,
    water_requirements,
    light_requirements,
    temperature,
    pet_safe,
    location_type,
    caring_difficulty,
    source,
    ai_confidence,
    created_by_user_id::text as created_by_user_id,
    reviewed_by_admin,
    is_active,
    created_at,
    updated_at
"""


class PlantService:
    async def find_matching_plant(
        self,
        session: AsyncSession,
        *,
        common_name: str,
        scientific_name: str | None,
    ) -> dict[str, Any] | None:
        query = text(
            f"""
            select {PLANT_SELECT_COLUMNS}
            from public.plants
            where is_active = true
              and (
                lower(common_name) = lower(:common_name)
                or (
                    :scientific_name is not null
                    and scientific_name is not null
                    and lower(scientific_name) = lower(:scientific_name)
                )
              )
            order by reviewed_by_admin desc, created_at asc
            limit 1
            """
        )
        result = await session.execute(
            query,
            {
                "common_name": common_name,
                "scientific_name": scientific_name,
            },
        )
        plant = result.mappings().first()
        return dict(plant) if plant else None

    async def list_plants(
        self,
        session: AsyncSession,
        *,
        include_inactive: bool = False,
        limit: int | None = None,
        offset: int = 0,
        location_type: str | None = None,
        light_condition: str | None = None,
        caring_style: str | None = None,
        pet_safe_only: bool = False,
    ) -> list[dict[str, Any]]:
        conditions: list[str] = []
        params: dict[str, Any] = {}

        if not include_inactive:
            conditions.append("is_active = true")

        if location_type in ("Indoor", "Outdoor"):
            conditions.append("location_type in (:loc_a, :loc_b)")
            params["loc_a"] = location_type
            params["loc_b"] = "Both"

        if caring_style == "I'm a bit forgetful":
            conditions.append("caring_difficulty = 'low'")

        if light_condition:
            conditions.append("lower(light_requirements) like :light_pattern")
            params["light_pattern"] = f"%{light_condition.lower()}%"

        if pet_safe_only:
            conditions.append("pet_safe = true")

        where_clause = ("where " + " and ".join(conditions)) if conditions else ""
        pagination_clause = (
            f"limit {limit} offset {offset}" if limit is not None else ""
        )
        query = text(
            f"""
            select {PLANT_SELECT_COLUMNS}
            from public.plants
            {where_clause}
            order by common_name asc, created_at desc
            {pagination_clause}
            """
        )
        result = await session.execute(query, params)
        return [dict(row) for row in result.mappings().all()]

    async def get_plant_by_id(
        self,
        session: AsyncSession,
        plant_id: str,
        *,
        include_inactive: bool = False,
    ) -> dict[str, Any]:
        where_clause = "" if include_inactive else "and is_active = true"
        query = text(
            f"""
            select {PLANT_SELECT_COLUMNS}
            from public.plants
            where id = cast(:plant_id as uuid)
              {where_clause}
            """
        )
        result = await session.execute(query, {"plant_id": plant_id})
        plant = result.mappings().first()
        if not plant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plant not found",
            )
        return dict(plant)

    async def create_plant(
        self,
        session: AsyncSession,
        data: dict[str, Any],
        created_by_user_id: str | None,
    ) -> dict[str, Any]:
        query = text(
            f"""
            insert into public.plants (
                common_name,
                scientific_name,
                short_description,
                image_path,
                water_requirements,
                light_requirements,
                temperature,
                pet_safe,
                location_type,
                caring_difficulty,
                source,
                ai_confidence,
                created_by_user_id,
                reviewed_by_admin,
                is_active
            )
            values (
                :common_name,
                :scientific_name,
                :short_description,
                :image_path,
                :water_requirements,
                :light_requirements,
                :temperature,
                :pet_safe,
                :location_type,
                :caring_difficulty,
                :source,
                :ai_confidence,
                cast(:created_by_user_id as uuid),
                :reviewed_by_admin,
                :is_active
            )
            returning {PLANT_SELECT_COLUMNS}
            """
        )
        result = await session.execute(
            query,
            {**data, "created_by_user_id": created_by_user_id},
        )
        await session.commit()
        plant = result.mappings().first()
        if not plant:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to create plant",
            )
        return dict(plant)

    async def update_plant(
        self,
        session: AsyncSession,
        plant_id: str,
        updates: dict[str, Any],
    ) -> dict[str, Any]:
        allowed_updates = {
            key: value
            for key, value in updates.items()
            if key
            in {
                "common_name",
                "scientific_name",
                "short_description",
                "image_path",
                "water_requirements",
                "light_requirements",
                "temperature",
                "pet_safe",
                "location_type",
                "caring_difficulty",
                "source",
                "ai_confidence",
                "reviewed_by_admin",
                "is_active",
            }
        }
        if not allowed_updates:
            return await self.get_plant_by_id(session, plant_id, include_inactive=True)

        set_clause = ", ".join(f"{key} = :{key}" for key in allowed_updates)
        query = text(
            f"""
            update public.plants
            set {set_clause}
            where id = cast(:plant_id as uuid)
            returning {PLANT_SELECT_COLUMNS}
            """
        )
        result = await session.execute(query, {"plant_id": plant_id, **allowed_updates})
        await session.commit()
        plant = result.mappings().first()
        if not plant:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Plant not found",
            )
        return dict(plant)

    async def archive_plant(self, session: AsyncSession, plant_id: str) -> dict[str, Any]:
        return await self.update_plant(
            session=session,
            plant_id=plant_id,
            updates={"is_active": False},
        )


plant_service = PlantService()
