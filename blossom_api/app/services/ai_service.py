from typing import Any

from fastapi import HTTPException, UploadFile, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.services.ai_settings_service import ai_settings_service
from app.services.garden_service import garden_service
from app.services.gemini_service import gemini_service
from app.services.plant_flow import get_missing_question_definitions, validate_answers
from app.services.plant_service import plant_service


class AiService:
    async def identify_plant(
        self,
        *,
        session: AsyncSession,
        user_id: str,
        image: UploadFile,
        answers: dict[str, str],
        add_to_garden: bool,
        custom_name: str | None,
    ) -> dict[str, Any]:
        if not image.content_type or not image.content_type.startswith("image/"):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Only image uploads are supported",
            )
        image_bytes = await image.read()
        if not image_bytes:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Uploaded image is empty",
            )
        validated_answers = validate_answers(answers)
        runtime_settings = await ai_settings_service.get_runtime_settings(session)
        ai_result = await gemini_service.identify_plant(
            runtime_settings=runtime_settings,
            image_bytes=image_bytes,
            mime_type=image.content_type,
            answers=validated_answers,
        )
        matched_plant = await plant_service.find_matching_plant(
            session,
            common_name=ai_result["common_name"],
            scientific_name=ai_result.get("scientific_name"),
        )
        created_new_plant = False
        if matched_plant:
            plant = matched_plant
        else:
            plant = await plant_service.create_plant(
                session,
                {
                    "common_name": ai_result["common_name"],
                    "scientific_name": ai_result.get("scientific_name"),
                    "short_description": ai_result["short_description"],
                    "image_path": None,
                    "water_requirements": ai_result["water_requirements"],
                    "light_requirements": ai_result["light_requirements"],
                    "temperature": ai_result["temperature"],
                    "pet_safe": ai_result["pet_safe"],
                    "source": "ai_image_discovery",
                    "ai_confidence": ai_result.get("ai_confidence"),
                    "reviewed_by_admin": False,
                    "is_active": True,
                },
                created_by_user_id=user_id,
            )
            created_new_plant = True
        await self._log_identification_event(
            session,
            user_id=user_id,
            plant_id=plant["id"],
            detected_name=ai_result["common_name"],
            confidence=ai_result.get("ai_confidence"),
            created_new_plant=created_new_plant,
        )
        missing_answers = get_missing_question_definitions(validated_answers)
        garden_item = None
        if add_to_garden and not missing_answers:
            garden_item = await garden_service.add_plant_to_garden(
                session,
                user_id,
                {
                    "plant_id": plant["id"],
                    "custom_name": custom_name,
                    "location_type": validated_answers["location_type"],
                    "light_condition": validated_answers["light_condition"],
                    "caring_style": validated_answers["caring_style"],
                    "pet_safety_priority": validated_answers["pet_safety_priority"],
                    "created_via": "ai_image_discovery",
                },
            )
        return {
            "plant": plant,
            "matched_existing": not created_new_plant,
            "created_new_plant": created_new_plant,
            "garden_item": garden_item,
            "missing_answers": [question["key"] for question in missing_answers],
            "next_questions": missing_answers,
            "used_answers": validated_answers,
            "input_mode": "image_only",
            "provider": runtime_settings.provider,
            "raw_result": ai_result,
        }

    async def test_connection(self, session: AsyncSession) -> dict[str, Any]:
        runtime_settings = await ai_settings_service.get_runtime_settings(
            session,
            require_enabled=False,
        )
        try:
            await gemini_service.test_connection(runtime_settings)
        except HTTPException:
            await ai_settings_service.record_connection_status(session, success=False)
            raise
        updated = await ai_settings_service.record_connection_status(session, success=True)
        return {
            "success": True,
            "message": "Gemini connection successful",
            "tested_at": updated["connection_last_tested_at"],
            "model": runtime_settings.model,
        }

    async def _log_identification_event(
        self,
        session: AsyncSession,
        *,
        user_id: str,
        plant_id: str,
        detected_name: str,
        confidence: float | None,
        created_new_plant: bool,
    ) -> None:
        query = text(
            """
            insert into public.plant_identification_events (
                user_id,
                plant_id,
                detected_name,
                source,
                confidence,
                created_new_plant
            )
            values (
                cast(:user_id as uuid),
                cast(:plant_id as uuid),
                :detected_name,
                'gemini',
                :confidence,
                :created_new_plant
            )
            """
        )
        await session.execute(
            query,
            {
                "user_id": user_id,
                "plant_id": plant_id,
                "detected_name": detected_name,
                "confidence": confidence,
                "created_new_plant": created_new_plant,
            },
        )
        await session.commit()


ai_service = AiService()
