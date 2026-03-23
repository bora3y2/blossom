from fastapi import APIRouter

from app.api.routes import admin, ai, auth, community, garden, health, notifications, plants, profiles

api_router = APIRouter()
api_router.include_router(health.router)
api_router.include_router(auth.router)
api_router.include_router(profiles.router)
api_router.include_router(plants.router)
api_router.include_router(garden.router)
api_router.include_router(community.router)
api_router.include_router(ai.router)
api_router.include_router(admin.router)
api_router.include_router(notifications.router)
