from fastapi import APIRouter
from fastapi.responses import HTMLResponse


api_router = APIRouter()


@api_router.get("/", response_class=HTMLResponse)
def landing_page():
    return "<html><h1>HI!</h1></html>"
