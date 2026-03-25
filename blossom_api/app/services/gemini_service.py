import base64
import json
import re
from typing import Any

import httpx
from fastapi import HTTPException, status

from app.services.ai_settings_service import RuntimeAiSettings

GEMINI_API_BASE_URL = "https://generativelanguage.googleapis.com/v1beta"
DEFAULT_SYSTEM_PROMPT = (
    "You are Blossom AI, a plant identification and care assistant. "
    "Return concise, safe, structured plant results for a gardening app."
)


class GeminiService:
    async def test_connection(self, runtime_settings: RuntimeAiSettings) -> None:
        payload = {
            "system_instruction": {
                "parts": [{"text": runtime_settings.system_prompt or DEFAULT_SYSTEM_PROMPT}]
            },
            "contents": [
                {
                    "role": "user",
                    "parts": [{"text": "Reply with exactly READY"}],
                }
            ],
            "generationConfig": {
                "temperature": 0,
                "maxOutputTokens": 32,
            },
        }
        response_text = await self._generate_content(
            runtime_settings=runtime_settings,
            payload=payload,
        )
        if "READY" not in response_text.upper():
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Gemini test response was invalid",
            )

    async def identify_plant(
        self,
        *,
        runtime_settings: RuntimeAiSettings,
        image_bytes: bytes,
        mime_type: str,
        answers: dict[str, str],
    ) -> dict[str, Any]:
        guidance_context = "\n".join(
            f"- {key}: {value}" for key, value in answers.items()
        ) or "- No guided answers provided yet"
        prompt = (
            "Identify the plant from the provided image and return only valid JSON. "
            "Use the guided answers as contextual constraints for how the plant will be placed in the user's garden. "
            "The JSON must contain exactly these keys: "
            "common_name, scientific_name, short_description, water_requirements, light_requirements, temperature, pet_safe, ai_confidence. "
            "The short_description should be 1-2 sentences. "
            "ai_confidence must be a number from 0 to 100. "
            "Guided answers:\n"
            f"{guidance_context}"
        )
        payload = {
            "system_instruction": {
                "parts": [{"text": runtime_settings.system_prompt or DEFAULT_SYSTEM_PROMPT}]
            },
            "contents": [
                {
                    "role": "user",
                    "parts": [
                        {"text": prompt},
                        {
                            "inline_data": {
                                "mime_type": mime_type,
                                "data": base64.b64encode(image_bytes).decode("utf-8"),
                            }
                        },
                    ],
                }
            ],
            "generationConfig": {
                "temperature": runtime_settings.temperature,
                "maxOutputTokens": runtime_settings.max_tokens,
                "responseMimeType": "application/json",
            },
        }
        response_text = await self._generate_content(
            runtime_settings=runtime_settings,
            payload=payload,
        )
        parsed = self._parse_json_response(response_text)
        return {
            "common_name": self._required_string(parsed.get("common_name"), "common_name"),
            "scientific_name": self._normalize_nullable_string(parsed.get("scientific_name")),
            "short_description": str(parsed.get("short_description") or "").strip(),
            "water_requirements": self._required_string(
                parsed.get("water_requirements"),
                "water_requirements",
            ),
            "light_requirements": self._required_string(
                parsed.get("light_requirements"),
                "light_requirements",
            ),
            "temperature": self._required_string(parsed.get("temperature"), "temperature"),
            "pet_safe": bool(parsed.get("pet_safe")),
            "ai_confidence": self._normalize_confidence(parsed.get("ai_confidence")),
        }

    async def _generate_content(
        self,
        *,
        runtime_settings: RuntimeAiSettings,
        payload: dict[str, Any],
    ) -> str:
        url = (
            f"{GEMINI_API_BASE_URL}/models/{runtime_settings.model}:generateContent"
            f"?key={runtime_settings.api_key}"
        )
        async with httpx.AsyncClient(timeout=45.0) as client:
            response = await client.post(url, json=payload)
        if response.status_code >= 400:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Gemini request failed: {response.text}",
            )
        data = response.json()
        try:
            parts = data["candidates"][0]["content"]["parts"]
            # Thinking models (e.g. gemini-flash-latest) prepend thought-only parts
            # that have no text or empty text — skip them to find the real response.
            text = next(
                (p["text"] for p in parts if p.get("text", "").strip()),
                None,
            )
            if not text:
                raise KeyError("no text part in response")
            return text
        except (KeyError, IndexError, TypeError) as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Gemini returned an unexpected response structure",
            ) from exc

    def _parse_json_response(self, response_text: str) -> dict[str, Any]:
        stripped = response_text.strip()
        if stripped.startswith("```"):
            stripped = re.sub(r"^```(?:json)?\s*", "", stripped)
            stripped = re.sub(r"\s*```$", "", stripped)
        match = re.search(r"\{.*\}", stripped, re.DOTALL)
        if match:
            stripped = match.group(0)
        try:
            return json.loads(stripped)
        except json.JSONDecodeError as exc:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail="Gemini response was not valid JSON",
            ) from exc

    def _normalize_nullable_string(self, value: Any) -> str | None:
        if value is None:
            return None
        normalized = str(value).strip()
        return normalized or None

    def _required_string(self, value: Any, field_name: str) -> str:
        normalized = str(value or "").strip()
        if not normalized:
            raise HTTPException(
                status_code=status.HTTP_502_BAD_GATEWAY,
                detail=f"Gemini response is missing required field: {field_name}",
            )
        return normalized

    def _normalize_confidence(self, value: Any) -> float | None:
        if value is None or value == "":
            return None
        try:
            numeric = float(value)
        except (TypeError, ValueError):
            return None
        return max(0.0, min(100.0, numeric))


gemini_service = GeminiService()
