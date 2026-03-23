import base64
import hashlib
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from cryptography.fernet import Fernet
from fastapi import HTTPException, status
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.config import settings

AI_SETTINGS_SELECT_COLUMNS = """
    provider,
    model,
    system_prompt,
    temperature,
    max_tokens,
    is_enabled,
    encrypted_api_key,
    connection_last_tested_at,
    connection_last_status,
    updated_by::text as updated_by,
    created_at,
    updated_at
"""


@dataclass(slots=True)
class RuntimeAiSettings:
    provider: str
    model: str
    system_prompt: str
    temperature: float
    max_tokens: int
    is_enabled: bool
    api_key: str


class AiSettingsService:
    def _get_fernet(self) -> Fernet:
        if not settings.app_encryption_secret:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail="APP_ENCRYPTION_SECRET is not configured",
            )
        digest = hashlib.sha256(settings.app_encryption_secret.encode("utf-8")).digest()
        key = base64.urlsafe_b64encode(digest)
        return Fernet(key)

    def _encrypt_api_key(self, api_key: str) -> str:
        return self._get_fernet().encrypt(api_key.encode("utf-8")).decode("utf-8")

    def _decrypt_api_key(self, encrypted_api_key: str) -> str:
        return self._get_fernet().decrypt(encrypted_api_key.encode("utf-8")).decode("utf-8")

    async def get_settings(self, session: AsyncSession) -> dict[str, Any]:
        query = text(
            f"""
            select {AI_SETTINGS_SELECT_COLUMNS}
            from public.ai_settings
            where id = 1
            """
        )
        result = await session.execute(query)
        ai_settings = result.mappings().first()
        if not ai_settings:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="AI settings not found",
            )
        data = dict(ai_settings)
        return {
            **data,
            "has_api_key": bool(data.get("encrypted_api_key") or settings.gemini_api_key),
        }

    async def get_runtime_settings(
        self,
        session: AsyncSession,
        *,
        require_enabled: bool = True,
    ) -> RuntimeAiSettings:
        ai_settings = await self.get_settings(session)
        encrypted_api_key = ai_settings.get("encrypted_api_key")
        if encrypted_api_key:
            api_key = self._decrypt_api_key(encrypted_api_key)
        elif settings.gemini_api_key:
            api_key = settings.gemini_api_key
        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Gemini API key is not configured",
            )
        if require_enabled and not ai_settings["is_enabled"]:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="AI assistant is disabled",
            )
        return RuntimeAiSettings(
            provider=ai_settings["provider"],
            model=ai_settings["model"],
            system_prompt=ai_settings["system_prompt"],
            temperature=float(ai_settings["temperature"]),
            max_tokens=int(ai_settings["max_tokens"]),
            is_enabled=bool(ai_settings["is_enabled"]),
            api_key=api_key,
        )

    async def update_settings(
        self,
        session: AsyncSession,
        updates: dict[str, Any],
        updated_by: str,
    ) -> dict[str, Any]:
        allowed_updates = {
            key: value
            for key, value in updates.items()
            if key in {"model", "system_prompt", "temperature", "max_tokens", "is_enabled"}
        }
        if "api_key" in updates:
            api_key = (updates.get("api_key") or "").strip()
            allowed_updates["encrypted_api_key"] = (
                self._encrypt_api_key(api_key) if api_key else None
            )
        if not allowed_updates:
            return await self.get_settings(session)
        set_clause = ", ".join(f"{key} = :{key}" for key in allowed_updates)
        query = text(
            f"""
            update public.ai_settings
            set {set_clause}, updated_by = cast(:updated_by as uuid)
            where id = 1
            returning {AI_SETTINGS_SELECT_COLUMNS}
            """
        )
        result = await session.execute(query, {**allowed_updates, "updated_by": updated_by})
        await session.commit()
        updated = result.mappings().first()
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="AI settings not found",
            )
        data = dict(updated)
        return {
            **data,
            "has_api_key": bool(data.get("encrypted_api_key") or settings.gemini_api_key),
        }

    async def record_connection_status(
        self,
        session: AsyncSession,
        *,
        success: bool,
    ) -> dict[str, Any]:
        tested_at = datetime.now(timezone.utc)
        query = text(
            f"""
            update public.ai_settings
            set
                connection_last_tested_at = :tested_at,
                connection_last_status = :connection_last_status
            where id = 1
            returning {AI_SETTINGS_SELECT_COLUMNS}
            """
        )
        result = await session.execute(
            query,
            {
                "tested_at": tested_at,
                "connection_last_status": "success" if success else "failed",
            },
        )
        await session.commit()
        updated = result.mappings().first()
        if not updated:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="AI settings not found",
            )
        data = dict(updated)
        return {
            **data,
            "has_api_key": bool(data.get("encrypted_api_key") or settings.gemini_api_key),
        }


ai_settings_service = AiSettingsService()
