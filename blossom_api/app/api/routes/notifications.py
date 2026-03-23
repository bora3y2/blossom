from fastapi import APIRouter

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/status")
async def get_notification_status() -> dict[str, str]:
    return {"status": "pending_implementation"}
