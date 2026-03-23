"""Supabase REST client singleton for database operations over HTTPS."""

from supabase import create_client, Client

from app.core.config import settings


def _create_supabase_admin() -> Client | None:
    if settings.supabase_url and settings.supabase_service_role_key:
        return create_client(settings.supabase_url, settings.supabase_service_role_key)
    if settings.supabase_url and settings.supabase_anon_key:
        return create_client(settings.supabase_url, settings.supabase_anon_key)
    return None


supabase_admin: Client | None = _create_supabase_admin()
