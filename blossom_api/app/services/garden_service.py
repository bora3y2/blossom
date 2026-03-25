import json
from collections import defaultdict
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.plant_service import plant_service


USER_PLANT_SELECT_COLUMNS = """
    up.id::text as id,
    up.user_id::text as user_id,
    up.plant_id::text as plant_id,
    up.custom_name,
    up.location_type,
    up.light_condition,
    up.caring_style,
    up.pet_safety_priority,
    up.created_via,
    up.created_at,
    up.updated_at
"""

USER_PLANT_RETURNING_COLUMNS = """
    id::text as id,
    user_id::text as user_id,
    plant_id::text as plant_id,
    custom_name,
    location_type,
    light_condition,
    caring_style,
    pet_safety_priority,
    created_via,
    created_at,
    updated_at
"""

CARE_TASK_SELECT_COLUMNS = """
    id::text as id,
    user_plant_id::text as user_plant_id,
    title,
    description,
    task_type,
    due_at,
    completed_at,
    is_enabled,
    created_at,
    updated_at
"""

CARE_TASK_RECURRENCE_DAYS = {
    "light": 2,
    "temperature": 3,
    "fertilize": 30,
}

# ── Watering schedule helpers ──────────────────────────────────────────────────

_DAY_KEYS: dict[str, int] = {
    "mon": 0, "tue": 1, "wed": 2, "thu": 3, "fri": 4, "sat": 5, "sun": 6,
}


def _water_times_in_day(day_start: datetime, times: int) -> list[datetime]:
    """Return evenly-spaced watering datetimes within a single calendar day."""
    times = max(1, min(24, times))
    interval = 24 / times
    return [day_start + timedelta(hours=interval * i + interval / 2) for i in range(times)]


def _get_next_water_time(schedule_json: str, after: datetime) -> datetime:
    """
    Compute the next watering datetime from a schedule JSON string.

    Schedule formats:
      {"type": "daily",   "times_per_day": 3}
      {"type": "weekly",  "days":  [{"day": "mon", "times": 2}, ...]}
      {"type": "monthly", "dates": [{"date": 1,    "times": 2}, ...]}

    Legacy format: plain numeric string (interpreted as days interval).
    """
    try:
        schedule = json.loads(schedule_json)
    except (json.JSONDecodeError, TypeError, ValueError):
        # Legacy: float-string = days interval
        try:
            days = float(schedule_json)
            return after + timedelta(days=max(1 / 24, days))
        except (ValueError, TypeError):
            return after + timedelta(days=7)

    kind = schedule.get("type")

    if kind == "daily":
        times = max(1, min(24, int(schedule.get("times_per_day", 1))))
        return after + timedelta(hours=24 / times)

    if kind == "weekly":
        days_config = schedule.get("days") or []
        if not days_config:
            return after + timedelta(days=7)
        scheduled = {
            _DAY_KEYS[d["day"]]: max(1, min(24, int(d.get("times", 1))))
            for d in days_config
            if d.get("day") in _DAY_KEYS
        }
        for offset in range(14):
            day_start = (after + timedelta(days=offset)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            wd = day_start.weekday()
            if wd in scheduled:
                for t in _water_times_in_day(day_start, scheduled[wd]):
                    if t > after:
                        return t
        return after + timedelta(days=7)

    if kind == "monthly":
        dates_config = schedule.get("dates") or []
        if not dates_config:
            return after + timedelta(days=30)
        scheduled = {
            max(1, min(31, int(d["date"]))): max(1, min(24, int(d.get("times", 1))))
            for d in dates_config
            if d.get("date") is not None
        }
        for offset in range(62):
            day_start = (after + timedelta(days=offset)).replace(
                hour=0, minute=0, second=0, microsecond=0
            )
            if day_start.day in scheduled:
                for t in _water_times_in_day(day_start, scheduled[day_start.day]):
                    if t > after:
                        return t
        return after + timedelta(days=30)

    return after + timedelta(days=7)


def _water_description(schedule_json: str) -> str:
    """Return a human-readable watering description from a schedule JSON string."""
    try:
        s = json.loads(schedule_json)
    except (json.JSONDecodeError, TypeError, ValueError):
        return "Water on schedule"

    kind = s.get("type")
    if kind == "daily":
        t = max(1, int(s.get("times_per_day", 1)))
        return f"Water {t} time{'s' if t > 1 else ''} per day"
    if kind == "weekly":
        total = sum(int(d.get("times", 1)) for d in s.get("days", []))
        return f"Water {total} time{'s' if total != 1 else ''} per week"
    if kind == "monthly":
        total = sum(int(d.get("times", 1)) for d in s.get("dates", []))
        return f"Water {total} time{'s' if total != 1 else ''} per month"
    return "Water on schedule"


# ── Service ────────────────────────────────────────────────────────────────────


class GardenService:
    async def list_user_plants(self, session: AsyncSession, user_id: str) -> list[dict[str, Any]]:
        query = text(
            f"""
            select {USER_PLANT_SELECT_COLUMNS}
            from public.user_plants up
            where up.user_id = cast(:user_id as uuid)
            order by up.created_at desc
            """
        )
        result = await session.execute(query, {"user_id": user_id})
        rows = [dict(row) for row in result.mappings().all()]
        return await self._attach_plant_details_and_tasks(session, rows)

    async def get_user_plant(
        self,
        session: AsyncSession,
        user_id: str,
        user_plant_id: str,
    ) -> dict[str, Any]:
        query = text(
            f"""
            select {USER_PLANT_SELECT_COLUMNS}
            from public.user_plants up
            where up.id = cast(:user_plant_id as uuid)
              and up.user_id = cast(:user_id as uuid)
            """
        )
        result = await session.execute(
            query,
            {"user_plant_id": user_plant_id, "user_id": user_id},
        )
        row = result.mappings().first()
        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Garden plant not found",
            )
        enriched = await self._attach_plant_details_and_tasks(session, [dict(row)])
        return enriched[0]

    async def complete_care_task(
        self,
        session: AsyncSession,
        user_id: str,
        task_id: str,
    ) -> dict[str, Any]:
        current_task_query = text(
            f"""
            select {CARE_TASK_SELECT_COLUMNS}
            from public.care_tasks
            join public.user_plants up
              on public.care_tasks.user_plant_id = up.id
            where public.care_tasks.id = cast(:task_id as uuid)
              and up.user_id = cast(:user_id as uuid)
            """
        )
        query = text(
            f"""
            update public.care_tasks
            set completed_at = coalesce(
                    public.care_tasks.completed_at,
                    timezone('utc', now())
                ),
                updated_at = timezone('utc', now())
            from public.user_plants up
            where public.care_tasks.id = cast(:task_id as uuid)
              and public.care_tasks.user_plant_id = up.id
              and up.user_id = cast(:user_id as uuid)
              and public.care_tasks.completed_at is null
            returning {CARE_TASK_SELECT_COLUMNS}
            """
        )
        result = await session.execute(query, {"task_id": task_id, "user_id": user_id})
        row = result.mappings().first()
        if not row:
            existing_result = await session.execute(
                current_task_query,
                {"task_id": task_id, "user_id": user_id},
            )
            existing_row = existing_result.mappings().first()
            if not existing_row:
                raise HTTPException(
                    status_code=status.HTTP_404_NOT_FOUND,
                    detail="Care task not found",
                )
            await session.rollback()
            return {
                "completed_task": dict(existing_row),
                "next_task": None,
            }
        completed_task = dict(row)
        next_task = await self._create_next_care_task(session, completed_task)
        await session.commit()
        return {
            "completed_task": completed_task,
            "next_task": next_task,
        }

    async def add_plant_to_garden(
        self,
        session: AsyncSession,
        user_id: str,
        payload: dict[str, Any],
    ) -> dict[str, Any]:
        plant = await plant_service.get_plant_by_id(
            session,
            payload["plant_id"],
            include_inactive=False,
        )
        query = text(
            f"""
            insert into public.user_plants (
                user_id,
                plant_id,
                custom_name,
                location_type,
                light_condition,
                caring_style,
                pet_safety_priority,
                created_via
            )
            values (
                cast(:user_id as uuid),
                cast(:plant_id as uuid),
                :custom_name,
                :location_type,
                :light_condition,
                :caring_style,
                :pet_safety_priority,
                :created_via
            )
            returning {USER_PLANT_RETURNING_COLUMNS}
            """
        )
        result = await session.execute(query, {**payload, "user_id": user_id})
        user_plant = result.mappings().first()
        if not user_plant:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="Unable to add plant to garden",
            )
        user_plant_data = dict(user_plant)
        await self._create_default_care_tasks(session, user_plant_data["id"], plant)
        await session.commit()
        return await self.get_user_plant(session, user_id, user_plant_data["id"])

    async def _create_default_care_tasks(
        self,
        session: AsyncSession,
        user_plant_id: str,
        plant: dict[str, Any],
    ) -> None:
        now = datetime.now(timezone.utc)
        task_definitions = [
            {
                "title": f"Water {plant['common_name']}",
                "description": _water_description(plant["water_requirements"]),
                "task_type": "water",
                "due_at": _get_next_water_time(plant["water_requirements"], now),
            },
            {
                "title": f"Check light for {plant['common_name']}",
                "description": plant["light_requirements"],
                "task_type": "light",
                "due_at": now + timedelta(days=2),
            },
            {
                "title": f"Monitor temperature for {plant['common_name']}",
                "description": plant["temperature"],
                "task_type": "temperature",
                "due_at": now + timedelta(days=3),
            },
        ]
        query = text(
            """
            insert into public.care_tasks (
                user_plant_id,
                title,
                description,
                task_type,
                due_at,
                is_enabled
            )
            values (
                cast(:user_plant_id as uuid),
                :title,
                :description,
                :task_type,
                :due_at,
                true
            )
            """
        )
        for task in task_definitions:
            await session.execute(query, {**task, "user_plant_id": user_plant_id})

    async def _create_next_care_task(
        self,
        session: AsyncSession,
        task: dict[str, Any],
    ) -> dict[str, Any] | None:
        completed_at = task.get("completed_at") or datetime.now(timezone.utc)

        if task["task_type"] == "water":
            plant_query = text(
                """
                select p.water_requirements
                from public.user_plants up
                join public.plants p on p.id = up.plant_id
                where up.id = cast(:user_plant_id as uuid)
                """
            )
            plant_result = await session.execute(
                plant_query, {"user_plant_id": task["user_plant_id"]}
            )
            plant_row = plant_result.mappings().first()
            schedule_json = (plant_row["water_requirements"] if plant_row else None) or "7"
            next_due_at = _get_next_water_time(schedule_json, completed_at)
        else:
            recurrence_days = CARE_TASK_RECURRENCE_DAYS.get(task["task_type"])
            if recurrence_days is None:
                return None
            next_due_at = completed_at + timedelta(days=recurrence_days)

        query = text(
            f"""
            insert into public.care_tasks (
                user_plant_id,
                title,
                description,
                task_type,
                due_at,
                is_enabled
            )
            values (
                cast(:user_plant_id as uuid),
                :title,
                :description,
                :task_type,
                :due_at,
                :is_enabled
            )
            returning {CARE_TASK_SELECT_COLUMNS}
            """
        )
        result = await session.execute(
            query,
            {
                "user_plant_id": task["user_plant_id"],
                "title": task["title"],
                "description": task.get("description"),
                "task_type": task["task_type"],
                "due_at": next_due_at,
                "is_enabled": task.get("is_enabled", True),
            },
        )
        row = result.mappings().first()
        return dict(row) if row else None

    async def _attach_plant_details_and_tasks(
        self,
        session: AsyncSession,
        rows: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        if not rows:
            return []

        plant_ids = sorted({row["plant_id"] for row in rows})
        plants_by_id = {
            plant_id: await plant_service.get_plant_by_id(
                session,
                plant_id,
                include_inactive=True,
            )
            for plant_id in plant_ids
        }

        tasks_by_user_plant_id: dict[str, list[dict[str, Any]]] = defaultdict(list)
        tasks_query = text(
            f"""
            select {CARE_TASK_SELECT_COLUMNS}
            from public.care_tasks
            where user_plant_id = cast(:user_plant_id as uuid)
            order by due_at asc nulls last, created_at asc
            """
        )
        for row in rows:
            tasks_result = await session.execute(tasks_query, {"user_plant_id": row["id"]})
            tasks_by_user_plant_id[row["id"]] = [
                dict(task) for task in tasks_result.mappings().all()
            ]

        enriched_rows = []
        for row in rows:
            plant = plants_by_id.get(row["plant_id"])
            if not plant:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Garden plant references missing catalog plant",
                )
            enriched_rows.append(
                {
                    **row,
                    "plant": plant,
                    "care_tasks": tasks_by_user_plant_id.get(row["id"], []),
                }
            )
        return enriched_rows


garden_service = GardenService()
