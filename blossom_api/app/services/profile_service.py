"""Profile service using Supabase REST API (PostgREST) over HTTPS."""

from typing import Any

from fastapi import HTTPException, status

from app.core.config import settings
from app.db.supabase_client import supabase_admin


class ProfileService:
    async def sync_profile_from_auth(
        self,
        profile_id: str,
        email: str | None,
    ) -> dict[str, Any]:
        if not email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Authenticated user email is missing",
            )
        if not supabase_admin:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Supabase client not configured",
            )

        display_name = email.split("@", maxsplit=1)[0] or "Blossom User"

        # Try to fetch existing profile
        result = supabase_admin.table("profiles").select("*").eq("id", profile_id).execute()

        if result.data:
            # Profile exists, update email if needed
            profile = result.data[0]
            if profile.get("email") != email:
                update_result = (
                    supabase_admin.table("profiles")
                    .update({"email": email})
                    .eq("id", profile_id)
                    .execute()
                )
                profile = update_result.data[0] if update_result.data else profile
        else:
            # Create new profile
            insert_result = (
                supabase_admin.table("profiles")
                .insert({
                    "id": profile_id,
                    "email": email,
                    "display_name": display_name,
                })
                .execute()
            )
            if not insert_result.data:
                raise HTTPException(
                    status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                    detail="Unable to synchronize profile",
                )
            profile = insert_result.data[0]

        return await self.ensure_bootstrap_admin(profile)

    async def ensure_bootstrap_admin(
        self,
        profile: dict[str, Any],
    ) -> dict[str, Any]:
        bootstrap_admin_email = settings.bootstrap_admin_email.strip().lower()
        profile_email = str(profile.get("email", "")).strip().lower()
        if not bootstrap_admin_email or profile_email != bootstrap_admin_email:
            return profile
        if profile.get("role") == "admin":
            return profile
        return await self.update_profile_role(
            profile_id=str(profile["id"]),
            role="admin",
        )

    async def get_profile_by_id(self, profile_id: str) -> dict[str, Any]:
        if not supabase_admin:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Supabase client not configured",
            )
        result = supabase_admin.table("profiles").select("*").eq("id", profile_id).execute()
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found",
            )
        return result.data[0]

    async def update_profile(
        self,
        profile_id: str,
        updates: dict[str, Any],
    ) -> dict[str, Any]:
        if not supabase_admin:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Supabase client not configured",
            )
        allowed_updates = {
            key: value
            for key, value in updates.items()
            if key in {"display_name", "avatar_path", "notifications_enabled"}
        }
        if not allowed_updates:
            return await self.get_profile_by_id(profile_id)

        result = (
            supabase_admin.table("profiles")
            .update(allowed_updates)
            .eq("id", profile_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found",
            )
        return result.data[0]

    async def update_profile_role(
        self,
        profile_id: str,
        role: str,
    ) -> dict[str, Any]:
        if not supabase_admin:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Supabase client not configured",
            )
        result = (
            supabase_admin.table("profiles")
            .update({"role": role})
            .eq("id", profile_id)
            .execute()
        )
        if not result.data:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Profile not found",
            )
        return result.data[0]

    async def delete_profile(self, profile_id: str) -> None:
        if not supabase_admin:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Supabase client not configured",
            )
        supabase_admin.table("profiles").delete().eq("id", profile_id).execute()

    async def upload_avatar(
        self,
        profile_id: str,
        file_bytes: bytes,
        content_type: str,
    ) -> dict[str, Any]:
        if not supabase_admin:
            raise HTTPException(
                status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
                detail="Supabase admin client not configured",
            )

        ext = "jpg"
        if content_type == "image/png":
            ext = "png"
        elif content_type == "image/webp":
            ext = "webp"

        file_path = f"{profile_id}/avatar.{ext}"

        try:
            supabase_admin.storage.from_("avatars").upload(
                file_path,
                file_bytes,
                file_options={"content-type": content_type, "upsert": "true"},
            )
        except Exception as exc:
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
                detail=f"Avatar upload failed: {exc}",
            )

        public_url = supabase_admin.storage.from_("avatars").get_public_url(file_path)

        return await self.update_profile(
            profile_id=profile_id,
            updates={"avatar_path": public_url},
        )


profile_service = ProfileService()
