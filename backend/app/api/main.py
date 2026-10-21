from fastapi import APIRouter

from app.api.routes import albums, tracks

router = APIRouter()
router.include_router(albums.router)
router.include_router(tracks.router)
